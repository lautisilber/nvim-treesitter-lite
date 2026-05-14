#!/usr/bin/env bash

trap 'echo ""; echo "Interrupted"; kill $(jobs -p) 2>/dev/null; exit 130' INT

usage() {
    echo "Usage: $(basename "$0") [-t <seconds>] [-o <lang1,lang2,...>] [-l <lang>] [-h]"
    echo ""
    echo "Options:"
    echo "  -t <seconds>          Timeout per language in seconds (default: 30)"
    echo "  -o <lang1,lang2,...>  Comma-separated list of languages to omit"
    echo "  -l <lang>             Test a single language, skipping the language list"
    echo "  -h                    Show this help message"
}

TIMEOUT="30s"
OMIT=()
SINGLE_LANG=""

while getopts "t:o:l:h" opt; do
    case "$opt" in
        t) TIMEOUT="$OPTARG" ;;
        o) IFS=',' read -ra OMIT <<< "$OPTARG" ;;
        l) SINGLE_LANG="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARSER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/parser"
QUERIES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/queries"
FAILED=()

echo "Test TSUninstall"
echo "PARSER_DIR: $PARSER_DIR"
rm -f "${PARSER_DIR:?}"/*.so
rm -rf "${QUERIES_DIR:?}"/*

is_omitted() {
    local lang="$1"
    for omit in "${OMIT[@]}"; do
        if [ "$lang" = "$omit" ]; then
            return 0
        fi
    done
    return 1
}

get_languages() {
    LUA_PATH="$SCRIPT_DIR/../lua/nvim-treesitter-lite/?.lua;;" lua "$SCRIPT_DIR/get_parsers.lua" "$@"
}

install_lang() {
    local lang="$1"
    timeout "$TIMEOUT" nvim --headless -es \
        -u "$SCRIPT_DIR/minimal_nvim_config.lua" \
        -c "TSInstall $lang" \
        -c "qall" \
        </dev/null 2>&1
}

uninstall_lang() {
    local lang="$1"
    timeout "$TIMEOUT" nvim --headless -es \
        -u "$SCRIPT_DIR/minimal_nvim_config.lua" \
        -c "TSUninstall $lang" \
        -c "qall" \
        </dev/null 2>&1
}

# returns 0 if all parsers for a lang_signature are installed, 1 otherwise
check_parsers_installed() {
    local parsers_str="$1"
    IFS=':' read -ra parsers <<< "$parsers_str"
    for parser in "${parsers[@]}"; do
        if [ ! -f "$PARSER_DIR/$parser.so" ]; then
            return 1
        fi
    done
    return 0
}

check_queries_installed() {
local queries_str="$1"
    if [ -z "$queries_str" ]; then
        return 0  # no queries expected
    fi
    IFS=':' read -ra queries <<< "$queries_str"
    for query in "${queries[@]}"; do
        if [ ! -d "$QUERIES_DIR/$query" ]; then
            return 1
        fi
        local scm_count
        scm_count=$(find "$QUERIES_DIR/$query" -name "*.scm" | wc -l)
        if [ "$scm_count" -eq 0 ]; then
            return 1
        fi
    done
    return 0
}

test_uninstall() {
    local lang_signature="$1"
    local parts
    IFS='|' read -ra parts <<< "$lang_signature"
    local lang="${parts[0]}"
    local parsers_str="${parts[1]}"
    local queries_str="${parts[2]}"

    echo "Testing uninstall: $lang"

    install_lang "$lang"
    if ! check_parsers_installed "$parsers_str"; then
        echo "FAIL: $lang — install step failed"
        FAILED+=("$lang")
        return
    fi

    uninstall_lang "$lang"
    if check_parsers_installed "$parsers_str"; then
        echo "FAIL: $lang — parsers still present after uninstall"
        FAILED+=("$lang")
        return
    fi
    if check_queries_installed "$queries_str"; then
        echo "FAIL: $lang — parsers still present after uninstall"
        FAILED+=("$lang")
        return
    fi

    echo "PASS: $lang"
}

# test one random tier 1 language
tier1_lang="python"
tier1_sig="$tier1_lang|$tier1_lang|$tier1_lang"
test_uninstall "$tier1_sig"

if [ -n "$SINGLE_LANG" ]; then
    line="$SINGLE_LANG|$SINGLE_LANG|$SINGLE_LANG"
    test_uninstall "$SINGLE_LANG"
else
    # test all tier 2 and tier 3 languages
    while IFS= read -r line; do
        IFS='|' read -ra parts <<< "$line"
        lang="${parts[0]}"

        if is_omitted "$lang"; then
            echo "SKIP: $lang"
            continue
        fi

        test_uninstall "$line"
    done < <(get_languages 2 3)
fi

if [ ${#FAILED[@]} -ne 0 ]; then
    echo ""
    echo "Failed languages: ${FAILED[*]}"
    exit 1
else
    echo ""
    echo "All languages passed"
fi

