#!/usr/bin/env bash

trap 'echo ""; echo "Interrupted"; kill $(jobs -p) 2>/dev/null; exit 130' INT

usage() {
    echo "Usage: $(basename "$0") [-t <seconds>] [-h]"
    echo ""
    echo "Options:"
    echo "  -t <seconds> Timeout per language in seconds (default: 30)"
    echo "  -h           Show this help message"
}

TIMEOUT="30s"

while getopts "n:t:h" opt; do
    case "$opt" in
        t) TIMEOUT="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARSER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/parser"
FAILED=()

echo "Test TSUninstall"
echo "PARSER_DIR: $PARSER_DIR"
rm -f "$PARSER_DIR"/*.so

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
check_installed() {
    local lang_signature="$1"
    local parts
    IFS=':' read -ra parts <<< "$lang_signature"
    local parsers=("${parts[@]:1}")
    for parser in "${parsers[@]}"; do
        if [[ ! -f "$PARSER_DIR/$parser.so" ]]; then
            return 1
        fi
    done
    return 0
}

test_uninstall() {
    local lang_signature="$1"
    local parts
    IFS=':' read -ra parts <<< "$lang_signature"
    local lang="${parts[0]}"

    echo "Testing uninstall: $lang"

    install_lang "$lang"
    if ! check_installed "$lang_signature"; then
        echo "FAIL: $lang — install step failed"
        FAILED+=("$lang")
        return
    fi

    uninstall_lang "$lang"
    if check_installed "$lang_signature"; then
        echo "FAIL: $lang — parsers still present after uninstall"
        FAILED+=("$lang")
        return
    fi

    echo "PASS: $lang"
}

# test one random tier 1 language
tier1_sig="$(get_languages 1 | shuf -n 1)"
test_uninstall "$tier1_sig"

# test all tier 2 and tier 3 languages
while IFS= read -r line; do
    test_uninstall "$line"
done < <(get_languages 2 3)

if [ ${#FAILED[@]} -ne 0 ]; then
    echo ""
    echo "Failed languages: ${FAILED[*]}"
    exit 1
else
    echo ""
    echo "All languages passed"
fi

