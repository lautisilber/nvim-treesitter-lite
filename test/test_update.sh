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

echo "Test TSUpdate"
echo "PARSER_DIR: $PARSER_DIR"
rm -f "$PARSER_DIR"/*.so
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

if stat -f "%m" /dev/null &>/dev/null; then
    STAT_FMT="-f %m"   # macOS
else
    STAT_FMT="-c %Y"   # Linux
fi

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

update_lang() {
    local lang="$1"
    timeout "$TIMEOUT" nvim --headless -es \
        -u "$SCRIPT_DIR/minimal_nvim_config.lua" \
        -c "TSUpdate $lang" \
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
        return 0
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

get_parser_mtimes() {
    local parsers_str="$1"
    IFS=':' read -ra parsers <<< "$parsers_str"
    local mtimes=()
    for parser in "${parsers[@]}"; do
        mtimes+=("$(stat $STAT_FMT "$PARSER_DIR/$parser.so" 2>/dev/null || echo "0")")
    done
    echo "${mtimes[@]}"
}

get_query_mtimes() {
    local queries_str="$1"
    if [ -z "$queries_str" ]; then
        echo ""
        return
    fi
    IFS=':' read -ra queries <<< "$queries_str"
    local mtimes=()
    for query in "${queries[@]}"; do
        # use the mtime of the directory itself
        mtimes+=("$(stat $STAT_FMT "$QUERIES_DIR/$query" 2>/dev/null || echo "0")")
    done
    echo "${mtimes[@]}"
}

test_update() {
    local lang_signature="$1"
    local parts
    IFS='|' read -ra parts <<< "$lang_signature"
    local lang="${parts[0]}"
    local parsers_str="${parts[1]}"
    local queries_str="${parts[2]:-$lang}"

    echo "Testing update: $lang"

    # install first
    install_lang "$lang"
    if ! check_parsers_installed "$parsers_str"; then
        echo "FAIL: $lang — install step failed (parsers)"
        FAILED+=("$lang")
        return
    fi
    if ! check_queries_installed "$queries_str"; then
        echo "FAIL: $lang — install step failed (queries)"
        FAILED+=("$lang")
        return
    fi

    # record mtimes before update
    local before_parsers before_queries
    before_parsers=$(get_parser_mtimes "$parsers_str")
    before_queries=$(get_query_mtimes "$queries_str")

    # small sleep to ensure mtime changes
    sleep 1

    update_lang "$lang"

    # check all parsers and queries still present
    if ! check_parsers_installed "$parsers_str"; then
        echo "FAIL: $lang — parsers missing after update"
        FAILED+=("$lang")
        return
    fi
    if ! check_queries_installed "$queries_str"; then
        echo "FAIL: $lang — queries missing after update"
        FAILED+=("$lang")
        return
    fi

    # check mtimes changed
    local after_parsers after_queries
    after_parsers=$(get_parser_mtimes "$parsers_str")
    after_queries=$(get_query_mtimes "$queries_str")

    if [ "$before_parsers" = "$after_parsers" ]; then
        echo "FAIL: $lang — parsers were not updated (mtimes unchanged)"
        FAILED+=("$lang")
        return
    fi
    if [ -n "$before_queries" ] && [ "$before_queries" = "$after_queries" ]; then
        echo "FAIL: $lang — queries were not updated (mtimes unchanged)"
        FAILED+=("$lang")
        return
    fi

    echo "PASS: $lang"
}

if [[ -n "$SINGLE_LANG" ]]; then
    line="$SINGLE_LANG|$SINGLE_LANG|$SINGLE_LANG"
    test_update "$line"
else
    # test one random tier 1 language
    tier1_lang="python"
    tier1_sig="$tier1_lang|$tier1_lang|$tier1_lang"
    test_update "$tier1_sig"

    # test all tier 2 and tier 3 languages
    while IFS= read -r line; do

        if is_omitted "$lang"; then
            echo "SKIP: $lang"
            continue
        fi

        test_update "$line"
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

