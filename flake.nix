{
  description = "Softvim: Windows Neovim port of the portable NixVim configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/eaad089433ca2bb662274377d33df3d0e51ef28b";
    project-check = {
      url = "github:timfewi/project-check-nix/560f80d59acbae4e4b38c1d3bb0d6d674fdb9907";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, project-check, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      source = pkgs.lib.cleanSourceWith {
        src = ./.;
        filter =
          path: _:
          !(builtins.elem (builtins.baseNameOf path) [
            ".test-runtime"
            ".git"
            ".direnv"
            "softvim-windows.zip"
          ]);
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          project-check.packages.${system}.project-check
          pkgs.bashInteractive
          pkgs.coreutils
          pkgs.deadnix
          pkgs.git
          pkgs.jq
          pkgs.just
          pkgs.nix
          pkgs.nixfmt
          pkgs.ripgrep
          pkgs.statix
          pkgs.neovim-unwrapped
          pkgs.luaPackages.luacheck
          pkgs.stylua
          pkgs.powershell
          pkgs.shellcheck
          pkgs.cmake
          pkgs.gcc
          pkgs.lua-language-server
        ];
      };

      formatter.${system} = pkgs.nixfmt-tree;

      checks.${system}.editor-core =
        pkgs.runCommand "softvim-core"
          {
            nativeBuildInputs = [
              pkgs.neovim-unwrapped
              pkgs.luaPackages.luacheck
            ];
          }
          ''
            cp -r ${source} source
            chmod -R u+w source
            cd source
            export XDG_CONFIG_HOME="$TMPDIR/config"
            export XDG_DATA_HOME="$TMPDIR/data"
            export XDG_STATE_HOME="$TMPDIR/state"
            export XDG_CACHE_HOME="$TMPDIR/cache"
            luacheck nvim checks
            nvim --headless -u NONE -l checks/core.lua
            nvim --headless -u NONE -l checks/tools.lua
            touch "$out"
          '';
    };
}
