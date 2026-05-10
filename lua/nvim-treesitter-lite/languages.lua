-- Tier 1: standard layout, url only
-- Tier 2: multiple parsers in one repo, each with a subpath and parser
-- Tier 3: custom build function
--      The tier 3 build function has the signature fun(utils, repo_path, out_dir) -> string[]|nil
--      if returns a list of commands to execute

return {
    -- tier 1
    python = { url = "tree-sitter/tree-sitter-python" },
    scala = "tree-sitter/tree-sitter-scala",
    ["c-sharp"] = "tree-sitter/tree-sitter-c-sharp",
    rust = "tree-sitter/tree-sitter-rust",
    ruby = "tree-sitter/tree-sitter-ruby",
    go = "tree-sitter/tree-sitter-go",
    cpp = "tree-sitter/tree-sitter-cpp",
    java = "tree-sitter/tree-sitter-java",
    bash = "tree-sitter/tree-sitter-bash",
    html = "tree-sitter/tree-sitter-html",
    javascript = "tree-sitter/tree-sitter-javascript",
    json = "tree-sitter/tree-sitter-json",
    julia = "tree-sitter-grammars/tree-sitter-julia",
    css = "tree-sitter/tree-sitter-css",
    jsdoc = "tree-sitter/tree-sitter-jsdoc",
    regex = "tree-sitter/tree-sitter-regex",
    agda = "tree-sitter/tree-sitter-agda",
    haskell = "tree-sitter-grammars/tree-sitter-haskell",
    ql = "tree-sitter/tree-sitter-ql",
    ["ql-dbscheme"] = "tree-sitter/tree-sitter-ql-dbscheme ",
    fluent = "tree-sitter/tree-sitter-fluent",
    toml = "tree-sitter-grammars/tree-sitter-toml",
    ["pip-requirements"] = "tree-sitter-grammars/tree-sitter-requirements",
    qmldir = "tree-sitter-grammars/tree-sitter-qmldir",
    arduino = "tree-sitter-grammars/tree-sitter-arduino",
    meson = "tree-sitter-grammars/tree-sitter-meson",
    yuck = "tree-sitter-grammars/tree-sitter-yuck",
    scss = "tree-sitter-grammars/tree-sitter-scss",
    cyberchef = "tree-sitter-grammars/tree-sitter-cyberchef",
    hyprlang = "tree-sitter-grammars/tree-sitter-hyprlang",
    make = "tree-sitter-grammars/tree-sitter-make",
    vue = "tree-sitter-grammars/tree-sitter-vue",
    hcl = "tree-sitter-grammars/tree-sitter-hcl",
    ["gpg-config"] = "tree-sitter-grammars/tree-sitter-gpg-config",
    chatito = "tree-sitter-grammars/tree-sitter-chatito",
    pem = "tree-sitter-grammars/tree-sitter-pem",
    gitattributes = "tree-sitter-grammars/tree-sitter-gitattributes",
    ["poe-filter"] = "tree-sitter-grammars/tree-sitter-poe-filter",
    cst = "tree-sitter-grammars/tree-sitter-cst",
    readline = "tree-sitter-grammars/tree-sitter-readline",
    ["wgsl-bevy"] = "tree-sitter-grammars/tree-sitter-wgsl-bevy",
    cuda = "tree-sitter-grammars/tree-sitter-cuda",
    diff = "tree-sitter-grammars/tree-sitter-diff",
    hare = "tree-sitter-grammars/tree-sitter-hare",
    slang = "tree-sitter-grammars/tree-sitter-slang",
    ["ssh-config"] = "tree-sitter-grammars/tree-sitter-ssh-config",
    zig = "tree-sitter-grammars/tree-sitter-zig",
    test = "tree-sitter-grammars/tree-sitter-test",
    pymanifest = "tree-sitter-grammars/tree-sitter-pymanifest",
    udev = "tree-sitter-grammars/tree-sitter-udev",
    xcompose = "tree-sitter-grammars/tree-sitter-xcompose",
    printf = "tree-sitter-grammars/tree-sitter-printf",
    ["java-properties"] = "tree-sitter-grammars/tree-sitter-properties",
    ["go-sum"] = "tree-sitter-grammars/tree-sitter-go-sum",
    bicep = "tree-sitter-grammars/tree-sitter-bicep",
    hlsl = "tree-sitter-grammars/tree-sitter-hlsl",
    svelte = "tree-sitter-grammars/tree-sitter-svelte",
    doxygen = "tree-sitter-grammars/tree-sitter-doxygen",
    bitbake = "tree-sitter-grammars/tree-sitter-bitbake",
    kdl = "tree-sitter-grammars/tree-sitter-kdl",
    tcl = "tree-sitter-grammars/tree-sitter-tcl",
    luadoc = "tree-sitter-grammars/tree-sitter-luadoc",
    starlark = "tree-sitter-grammars/tree-sitter-starlark",
    objc = "tree-sitter-grammars/tree-sitter-objc",
    odin = "tree-sitter-grammars/tree-sitter-odin",
    glsl = "tree-sitter-grammars/tree-sitter-glsl",
    commonlisp = "tree-sitter-grammars/tree-sitter-commonlisp",
    ungrammar = "tree-sitter-grammars/tree-sitter-ungrammar",
    kotlin = "tree-sitter-grammars/tree-sitter-kotlin",
    luau = "tree-sitter-grammars/tree-sitter-luau",
    kconfig = "tree-sitter-grammars/tree-sitter-kconfig",
    puppet= "tree-sitter-grammars/tree-sitter-puppet",
    re2c = "tree-sitter-grammars/tree-sitter-re2c",
    squirrel = "tree-sitter-grammars/tree-sitter-squirrel",
    luap = "tree-sitter-grammars/tree-sitter-luap",
    unxtal = "tree-sitter-grammars/tree-sitter-unxtal",
    tablegen = "tree-sitter-grammars/tree-sitter-tablegen",
    ron = "tree-sitter-grammars/tree-sitter-ron",
    smali = "tree-sitter-grammars/tree-sitter-smali",
    func = "tree-sitter-grammars/tree-sitter-func",
    cairo = "tree-sitter-grammars/tree-sitter-cairo",
    pony = "tree-sitter-grammars/tree-sitter-pony",
    thrift = "tree-sitter-grammars/tree-sitter-thrift",
    po = "tree-sitter-grammars/tree-sitter-po",
    cpon = "tree-sitter-grammars/tree-sitter-cpon",
    firrtl = "tree-sitter-grammars/tree-sitter-firrtl",
    capnp = "tree-sitter-grammars/tree-sitter-capnp",
    gstlaunch = "tree-sitter-grammars/tree-sitter-gstlaunch",
    linkerscript = "tree-sitter-grammars/tree-sitter-linkerscript",
    gn = "tree-sitter-grammars/tree-sitter-gn",
    nqc = "tree-sitter-grammars/tree-sitter-nqc",
    zsh = "tree-sitter-grammars/tree-sitter-zsh",
    ispc = "tree-sitter-grammars/tree-sitter-ispc",
    move = "tree-sitter-grammars/tree-sitter-move",

    -- tier 2
    typescript = {
        url = "tree-sitter/tree-sitter-typescript",
        parsers = {
            {
                subpath = "typescript",
                parser = "typescript",
            },
            {
                subpath = "tsx",
                parser = "tsx",
            },
        }
    },
    php = {
        url = "tree-sitter/tree-sitter-php",
        parsers = {
            {
                subpath = "php",
                parser = "php"
            }
        },
    },
    xml = {
        url = "tree-sitter-grammars/tree-sitter-xml",
        parsers = {
            {
                subpath = "xml",
                parser = "xml",
            },
        },
    },
    csv = {
        url = "tree-sitter-grammars/tree-sitter-csv",
        parsers = {
            {
                subpath = "csv",
                parser = "csv",
            },
            {
                subpath = "psv",
                parser = "psv",
            },
            {
                subpath = "tsv",
                parser = "tsv",
            },
        },
    }

    -- tier 3
    -- yaml = "tree-sitter-grammars/tree-sitter-yaml",
}
