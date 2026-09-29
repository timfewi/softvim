{ dotfiles }:
let
  root = dotfiles;
  core = (import (root + "/modules/home/nixvim.nix") { }).programs.nixvim;
  parsers = [
    "nix"
    "lua"
    "bash"
    "python"
    "rust"
    "c"
    "cpp"
    "go"
    "javascript"
    "typescript"
    "tsx"
    "json"
    "yaml"
    "toml"
    "markdown"
    "markdown_inline"
    "vim"
    "vimdoc"
    "regex"
  ];
  attrs =
    names:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = name;
      }) names
    );
  plugins =
    (import (root + "/modules/home/nixvim/plugins.nix") {
      pkgs = attrs [
        "git"
        "ripgrep"
        "fd"
        "lazygit"
      ];
      config.programs.nixvim.plugins.treesitter.package.builtGrammars = attrs parsers;
    }).programs.nixvim.plugins
    // (import (root + "/modules/home/nixvim/coach.nix") { }).programs.nixvim.plugins;
  themeData = builtins.fromJSON (builtins.readFile (root + "/theme.json"));
  inherit (themeData) palettes;
  roles = builtins.mapAttrs (name: _: "{{${name}}}") palettes.portable.dark;
  runtime = import (root + "/modules/home/nixvim/theme-runtime.nix") {
    lib.optionalAttrs = condition: value: if condition then value else { };
    pkgs = { };
  };
in
{
  schemaVersion = 1;
  leader = core.globals.mapleader;
  options = core.opts;
  diagnostics = core.diagnostic.settings;
  inherit (core) keymaps;
  pluginSettings = builtins.mapAttrs (_: value: value.settings or { }) plugins;
  enabledPlugins = builtins.filter (name: plugins.${name}.enable or false) (
    builtins.attrNames plugins
  );
  inherit (plugins) lsp lint;
  telescopeMappings = plugins.telescope.keymaps;
  parsers = plugins.treesitter.grammarPackages;
  theme = {
    inherit palettes;
    dark = runtime.groups "dark" roles;
    light = runtime.groups "light" roles;
    lualine = runtime.lualine roles;
  };
}
