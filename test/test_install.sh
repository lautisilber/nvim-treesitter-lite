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

echo "Test TSInstall"
echo "PARSER_DIR: $PARSER_DIR"
rm -f "$PARSER_DIR"/*.so

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

while IFS= read -r line; do

    IFS=':' read -ra parts <<< "$line"
    lang="${parts[0]}"
    parsers=("${parts[@]:1}")

    install_lang "$lang"

    lang_failed=false
    for parser in "${parsers[@]}"; do
        if [ ! -f "$PARSER_DIR/$parser.so" ]; then
            echo "FAIL: $lang — missing $parser.so"
            lang_failed=true
        fi
    done

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

