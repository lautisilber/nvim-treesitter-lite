-- Tier 1: standard layout, url only
-- Tier 2: multiple parsers in one repo, each with a subpath and parser
-- Tier 3: custom build function
--      The tier 3 build function has the signature fun(utils, repo_path, out_dir) -> string[]|nil
--      if returns a list of commands to execute

return {
    -- tier 1
    python = { url = "tree-sitter/tree-sitter-python" },
    scala = { url = "tree-sitter/tree-sitter-scala" },
    ["c-sharp"] = { url = "tree-sitter/tree-sitter-c-sharp" },
    rust = { url = "tree-sitter/tree-sitter-rust" },
    ruby = { url = "tree-sitter/tree-sitter-ruby" },
    go = { url = "tree-sitter/tree-sitter-go" },
    cpp = { url = "tree-sitter/tree-sitter-cpp" },
    java = { url = "tree-sitter/tree-sitter-java" },
    bash = { url = "tree-sitter/tree-sitter-bash" },
    html = { url = "tree-sitter/tree-sitter-html" },
    javascript = { url = "tree-sitter/tree-sitter-javascript" },
    json = { url = "tree-sitter/tree-sitter-json" },
    julia = { url = "tree-sitter-grammars/tree-sitter-julia" },
    css = { url = "tree-sitter/tree-sitter-css" },
    jsdoc = { url = "tree-sitter/tree-sitter-jsdoc" },
    regex = { url = "tree-sitter/tree-sitter-regex" },
    agda = { url = "tree-sitter/tree-sitter-agda" },
    haskell = { url = "tree-sitter-grammars/tree-sitter-haskell" },
    ql = { url = "tree-sitter/tree-sitter-ql" },
    ["ql-dbscheme"] = { url = "tree-sitter/tree-sitter-ql-dbscheme" },
    fluent = { url = "tree-sitter/tree-sitter-fluent" },
    toml = { url = "tree-sitter-grammars/tree-sitter-toml" },
    ["pip-requirements"] = { url = "tree-sitter-grammars/tree-sitter-requirements" },
    qmldir = { url = "tree-sitter-grammars/tree-sitter-qmldir" },
    arduino = { url = "tree-sitter-grammars/tree-sitter-arduino" },
    meson = { url = "tree-sitter-grammars/tree-sitter-meson" },
    yuck = { url = "tree-sitter-grammars/tree-sitter-yuck" },
    scss = { url = "tree-sitter-grammars/tree-sitter-scss" },
    cyberchef = { url = "tree-sitter-grammars/tree-sitter-cyberchef" },
    hyprlang = { url = "tree-sitter-grammars/tree-sitter-hyprlang" },
    make = { url = "tree-sitter-grammars/tree-sitter-make" },
    vue = { url = "tree-sitter-grammars/tree-sitter-vue" },
    hcl = { url = "tree-sitter-grammars/tree-sitter-hcl" },
    ["gpg-config"] = { url = "tree-sitter-grammars/tree-sitter-gpg-config" },
    chatito = { url = "tree-sitter-grammars/tree-sitter-chatito" },
    pem = { url = "tree-sitter-grammars/tree-sitter-pem" },
    gitattributes = { url = "tree-sitter-grammars/tree-sitter-gitattributes" },
    ["poe-filter"] = { url = "tree-sitter-grammars/tree-sitter-poe-filter" },
    cst = { url = "tree-sitter-grammars/tree-sitter-cst" },
    readline = { url = "tree-sitter-grammars/tree-sitter-readline" },
    ["wgsl-bevy"] = { url = "tree-sitter-grammars/tree-sitter-wgsl-bevy" },
    cuda = { url = "tree-sitter-grammars/tree-sitter-cuda" },
    diff = { url = "tree-sitter-grammars/tree-sitter-diff" },
    hare = { url = "tree-sitter-grammars/tree-sitter-hare" },
    slang = { url = "tree-sitter-grammars/tree-sitter-slang" },
    ["ssh-config"] = { url = "tree-sitter-grammars/tree-sitter-ssh-config" },
    zig = { url = "tree-sitter-grammars/tree-sitter-zig" },
    test = { url = "tree-sitter-grammars/tree-sitter-test" },
    pymanifest = { url = "tree-sitter-grammars/tree-sitter-pymanifest" },
    udev = { url = "tree-sitter-grammars/tree-sitter-udev" },
    xcompose = { url = "tree-sitter-grammars/tree-sitter-xcompose" },
    printf = { url = "tree-sitter-grammars/tree-sitter-printf" },
    ["java-properties"] = { url = "tree-sitter-grammars/tree-sitter-properties" },
    ["go-sum"] = { url = "tree-sitter-grammars/tree-sitter-go-sum" },
    bicep = { url = "tree-sitter-grammars/tree-sitter-bicep" },
    hlsl = { url = "tree-sitter-grammars/tree-sitter-hlsl" },
    svelte = { url = "tree-sitter-grammars/tree-sitter-svelte" },
    doxygen = { url = "tree-sitter-grammars/tree-sitter-doxygen" },
    bitbake = { url = "tree-sitter-grammars/tree-sitter-bitbake" },
    kdl = { url = "tree-sitter-grammars/tree-sitter-kdl" },
    tcl = { url = "tree-sitter-grammars/tree-sitter-tcl" },
    luadoc = { url = "tree-sitter-grammars/tree-sitter-luadoc" },
    starlark = { url = "tree-sitter-grammars/tree-sitter-starlark" },
    objc = { url = "tree-sitter-grammars/tree-sitter-objc" },
    odin = { url = "tree-sitter-grammars/tree-sitter-odin" },
    glsl = { url = "tree-sitter-grammars/tree-sitter-glsl" },
    commonlisp = { url = "tree-sitter-grammars/tree-sitter-commonlisp" },
    ungrammar = { url = "tree-sitter-grammars/tree-sitter-ungrammar" },
    kotlin = { url = "tree-sitter-grammars/tree-sitter-kotlin" },
    luau = { url = "tree-sitter-grammars/tree-sitter-luau" },
    kconfig = { url = "tree-sitter-grammars/tree-sitter-kconfig" },
    puppet = { url = "tree-sitter-grammars/tree-sitter-puppet" },
    re2c = { url = "tree-sitter-grammars/tree-sitter-re2c" },
    squirrel = { url = "tree-sitter-grammars/tree-sitter-squirrel" },
    luap = { url = "tree-sitter-grammars/tree-sitter-luap" },
    uxntal = { url = "tree-sitter-grammars/tree-sitter-uxntal" },
    tablegen = { url = "tree-sitter-grammars/tree-sitter-tablegen" },
    ron = { url = "tree-sitter-grammars/tree-sitter-ron" },
    smali = { url = "tree-sitter-grammars/tree-sitter-smali" },
    func = { url = "tree-sitter-grammars/tree-sitter-func" },
    cairo = { url = "tree-sitter-grammars/tree-sitter-cairo" },
    pony = { url = "tree-sitter-grammars/tree-sitter-pony" },
    thrift = { url = "tree-sitter-grammars/tree-sitter-thrift" },
    po = { url = "tree-sitter-grammars/tree-sitter-po" },
    cpon = { url = "tree-sitter-grammars/tree-sitter-cpon" },
    firrtl = { url = "tree-sitter-grammars/tree-sitter-firrtl" },
    capnp = { url = "tree-sitter-grammars/tree-sitter-capnp" },
    gstlaunch = { url = "tree-sitter-grammars/tree-sitter-gstlaunch" },
    linkerscript = { url = "tree-sitter-grammars/tree-sitter-linkerscript" },
    gn = { url = "tree-sitter-grammars/tree-sitter-gn" },
    nqc = { url = "tree-sitter-grammars/tree-sitter-nqc" },
    zsh = { url = "tree-sitter-grammars/tree-sitter-zsh" },
    ispc = { url = "tree-sitter-grammars/tree-sitter-ispc" },
    move = { url = "tree-sitter-grammars/tree-sitter-move" },
    vb_dotnet = { url = "CodeAnt-AI/tree-sitter-vb-dotnet" },
    fortran = { url = "stadelmanma/tree-sitter-fortran" },
    ada = { url = "briot/tree-sitter-ada" },
    cmake = { url = "uyha/tree-sitter-cmake" },

    -- tier 2
    typescript = {
        url = "tree-sitter/tree-sitter-typescript",
        parsers = {
            {
                subpath = "typescript",
                name = "typescript",
            },
            {
                subpath = "tsx",
                name = "tsx",
            },
        }
    },
    php = {
        url = "tree-sitter/tree-sitter-php",
        parsers = {
            {
                subpath = "php",
                name = "php"
            }
        },
    },
    xml = {
        url = "tree-sitter-grammars/tree-sitter-xml",
        parsers = {
            {
                subpath = "xml",
                name = "xml",
            },
        },
    },
    csv = {
        url = "tree-sitter-grammars/tree-sitter-csv",
        parsers = {
            {
                subpath = "csv",
                name = "csv",
            },
            {
                subpath = "psv",
                name = "psv",
            },
            {
                subpath = "tsv",
                name = "tsv",
            },
        },
    },
    ocaml = {
        url = "tree-sitter/tree-sitter-ocaml",
        parsers = {
            {
                subpath = "grammars/ocaml",
                name = "ocaml",
            },
            {
                subpath = "grammars/interface",
                name = "ocaml_interface",
            },
            {
                subpath = "grammars/type",
                name = "ocaml_type"
            },
        },
    },

    -- tier 3
    -- yaml = "tree-sitter-grammars/tree-sitter-yaml",
}
