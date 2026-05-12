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
QUERIES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/queries"
FAILED=()

echo "Test TSInstall"
echo "PARSER_DIR: $PARSER_DIR"
rm -f "${PARSER_DIR:?}"/*.so
rm -rf "${QUERIES_DIR:?}"/*

get_languages() {
    LUA_PATH="$SCRIPT_DIR/../lua/nvim-treesitter-lite/?.lua;;" lua "$SCRIPT_DIR/get_parsers.lua"
}

install_lang() {
    local lang="${1}"

    # Important to add </dev/null to the nvim command, because otherwise it will
    # consume the stdin of the while loop it's called from
    timeout "$TIMEOUT" nvim --headless -es \
        -u "$SCRIPT_DIR/minimal_nvim_config.lua" \
        -c "TSInstall $lang" \
        -c "qall" \
        </dev/null 2>&1
}

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

while IFS= read -r line; do

    IFS='|' read -ra parts <<< "$line"
    lang="${parts[0]}"
    parsers_str="${parts[1]}"
    queries_str="${parts[2]}"

    echo "Testing: $lang"
    install_lang "$lang"

    lang_failed=false

    if ! check_parsers_installed "$parsers_str"; then
        echo "FAIL: $lang — missing parser(s)"
        lang_failed=true
    fi

    if ! check_queries_installed "$queries_str"; then
        echo "FAIL: $lang — missing query file(s)"
        lang_failed=true
    fi

    if [ "$lang_failed" = false ]; then
        echo "PASS: $lang"
    else
        FAILED+=("$lang")
    fi

done < <(get_languages)

if [ ${#FAILED[@]} -ne 0 ]; then
    echo ""
    echo "Failed languages: ${FAILED[*]}"
    exit 1
else
    echo ""
    echo "All languages passed"
fi

