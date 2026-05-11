#!/usr/bin/env bash
trap 'echo ""; echo "Interrupted"; kill $(jobs -p) 2>/dev/null; exit 130' INT

usage() {
    echo "Usage: $(basename "$0") [-t <seconds>] [-h]"
    echo ""
    echo "Options:"
    echo "  -t <seconds> Timeout per language in seconds (default: 30s)"
    echo "  -h           Show this help message"
}

TIMEOUT="30s"
while getopts "t:h" opt; do
    case "$opt" in
        t) TIMEOUT="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARSER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/parser"
FAILED=()

echo "Test TSUpdate"
echo "PARSER_DIR: $PARSER_DIR"
rm -f "$PARSER_DIR"/*.so

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

get_mtimes() {
    local lang_signature="$1"
    local parts
    IFS=':' read -ra parts <<< "$lang_signature"
    local parsers=("${parts[@]:1}")
    local mtimes=()
    for parser in "${parsers[@]}"; do
        mtimes+=("$(stat $STAT_FMT "$PARSER_DIR/$parser.so" 2>/dev/null || echo "0")")
    done
    echo "${mtimes[@]}"
}

test_update() {
    local lang_signature="$1"
    local parts
    IFS=':' read -ra parts <<< "$lang_signature"
    local lang="${parts[0]}"
    local parsers=("${parts[@]:1}")

    echo "Testing update: $lang"

    # install first
    install_lang "$lang"
    if ! check_installed "$lang_signature"; then
        echo "FAIL: $lang — install step failed"
        FAILED+=("$lang")
        return
    fi

    # record mtimes before update
    local before
    before=$(get_mtimes "$lang_signature")

    # small sleep to ensure mtime changes
    sleep 1

    update_lang "$lang"

    # check all parsers still present
    if ! check_installed "$lang_signature"; then
        echo "FAIL: $lang — parsers missing after update"
        FAILED+=("$lang")
        return
    fi

    # check mtimes changed
    local after
    after=$(get_mtimes "$lang_signature")
    if [ "$before" = "$after" ]; then
        echo "FAIL: $lang — parsers were not updated (mtimes unchanged)"
        FAILED+=("$lang")
        return
    fi

    echo "PASS: $lang"
}

# test one random tier 1 language
tier1_sig="$(get_languages 1 | shuf -n 1)"
test_update "$tier1_sig"

# test all tier 2 and tier 3 languages
while IFS= read -r line; do
    test_update "$line"
done < <(get_languages 2 3)

if [ ${#FAILED[@]} -ne 0 ]; then
    echo ""
    echo "Failed languages: ${FAILED[*]}"
    exit 1
else
    echo ""
    echo "All languages passed"
fi

