# Softvim

A native Windows Neovim configuration mirroring the portable NixVim editor in
`dotfiles`. It includes the same Space leader, editor options, mappings, plugin
settings, language-server preferences, formatters, syntax languages, and four
dark/light palettes. Windows runs plain Lua; Nix is only a development tool.

## Windows installation

Use **Neovim 0.12 or newer**, matching the source configuration. Install these
prerequisites in PowerShell using WinGet, or your preferred package manager:

```powershell
winget install --id Neovim.Neovim --exact
winget install --id Git.Git --exact
winget install --id OpenJS.NodeJS.LTS --exact
winget install --id BurntSushi.ripgrep.MSVC --exact
winget install --id sharkdp.fd --exact
winget install --id JesseDuffield.lazygit --exact
winget install --id Kitware.CMake --exact
winget install --id LLVM.LLVM --exact
```

Install the **Tree-sitter CLI 0.26.1 or newer** from the
[official releases](https://github.com/tree-sitter/tree-sitter/releases), and
put `tree-sitter.exe` on PATH. Use the executable release, rather than the npm
package. Make sure `clang`, `cmake`, `git`, `curl`, and `tar` are on PATH. LLVM's
installer may require adding its `bin` directory to PATH. Alternatively, use
Visual Studio Build Tools and launch from its Developer PowerShell so `cl` is
available. These compilers build Telescope's native sorter and syntax parsers.

Restart the terminal after installing tools. Use Windows Terminal with
**CaskaydiaCove Nerd Font** for the same icons as NixOS; select the font in the
terminal profile. The editor keeps transparent backgrounds, so the terminal
controls their underlying color.

Extract `softvim-windows.zip`, open PowerShell in the extracted directory, and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
nvim
```

The script copies `nvim/` into `%LOCALAPPDATA%\nvim`. It backs up an existing
configuration beside it as `nvim.backup-<timestamp>-<id>` and preserves
`lua\softvim\local.lua` overrides on upgrades. It does not change system
execution policy or install system packages. Preview with `-WhatIf`.

The first Neovim launch downloads the locked plugins, builds the native sorter,
installs syntax parsers, and asks Mason to install supported language tools.
Keep it open while installations finish. Inspect `:Lazy`, `:Mason`, and
`:checkhealth softvim`; `:SoftvimInstall` retries tools and parsers. After a
compiler installation, `:Lazy build telescope-fzf-native.nvim` retries the
native sorter. `:TSUpdate` updates installed parsers after a plugin update.

To keep an existing Neovim installation alongside Softvim:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -AppName softvim
$env:NVIM_APPNAME = 'softvim'
nvim
```

If you already set `NVIM_APPNAME`, pass the matching name to the installer.
Close Neovim before upgrading or restoring a backup. Restore by moving the new
config directory aside and renaming the selected backup to its original name.

## What matches

The plugin set includes Blink, Telescope with FZF and UI selection, Neo-tree in
the current window, Bufferline, Lualine, Gitsigns, Diffview, Trouble, Toggleterm,
Noice, Which-Key, Flash, Hardtime, Mini AI and Move, Conform, nvim-lint,
Tree-sitter, text objects, and devicons. Hardtime gives hints without blocking
motion keys or the mouse.

| Keys | Action |
| --- | --- |
| `Space w`, `Space q`, `Space h` | Save, close window, clear search highlight |
| `-`, `Space bb` | Toggle tree, reveal file |
| `Tab`, `Shift-Tab` | Next/previous buffer |
| `Space ff`, `Space fg`, `Space fb` | Files including dotfiles, text, buffers |
| `Space fk` | Search the complete keymap list |
| `gd`, `gr`, `gD`, `gI`, `K`, `Ctrl-s` | Definition, references, declaration, implementation, hover, signature |
| `Space rn` / `Space cr`, `Space ca`, `Space cf` | Rename, code action, format |
| `Space gg`, `Space gv`, `Space gC`, `Space gh` | Lazygit, open/close diff, file history |
| `]c`, `[c`, `Space gs/gr/gu/gp/gb` | Hunks, stage/reset/undo/preview/blame |
| `Space xx/xq/xl/xr/xv` | Diagnostics, quickfix, location list, references, inline diagnostics |
| `Space tt/th/tv`, `Esc` | Floating/horizontal/vertical terminal, leave terminal mode |
| `Ctrl-h/j/k/l`, `Ctrl-arrow` | Navigate and resize splits |
| `s`, `S`, `r`, `R` | Flash jumps, nodes, remote and Tree-sitter search |
| `am/im`, `ac/ic`, `]m/[m`, `Space sn/sp` | Function/class text objects, move, swap parameters |
| `Alt-h/j/k/l` | Move the current line or selection |

Language servers cover Lua, Bash, Python, TypeScript/JavaScript, C/C++, Go,
Rust, YAML, and Nix when the respective executable is available. Inlay hints
are enabled for servers that support them. Format-on-save uses the source
one-second timeout and LSP fallback. Formatting also covers JSON, Markdown,
CSS, and HTML. The exact parser, formatter, and mapping lists are in the
generated `nvim/lua/softvim/mirror.json`.

## Windows adaptations

- Neovim's native Windows clipboard replaces Wayland's `wl-copy` provider.
- Floating and split terminals use PowerShell 7 when available, then Windows
  PowerShell, then Neovim's default shell.
- Lazy and Mason replace Nix's plugin and executable delivery. Plugin commits
  are locked in `nvim/lazy-lock.json`. Mason tools follow its current registry.
- Mason skips tools unsupported on the current platform. **Nixd, Statix, and
  Nixfmt may require Linux/Nix rather than native Windows.** Their source
  configuration remains intact and activates when available. For Nix projects
  needing the complete Nix toolchain, run Neovim inside WSL with Nix installed;
  this config's Lua also works there. A bare `wsl.exe nixd` command is insufficient
  for native Windows LSP because file URIs need translation.
- Rust formatting uses the project's `rustfmt` (install Rust through rustup).
  Go projects need Go; Bash development needs a Bash environment. The config
  supplies editor tools, not project compilers or dependencies.
- The optional `Space ez/ec/ee/eo` voice shortcuts are enabled only if the
  `parloquent` client is on PATH. The source client integration is included;
  install and configure Parloquent separately. No credentials are bundled.
- Noctalia's desktop palette renderer and Linux signals are replaced by
  `:SoftvimTheme`. All source palettes are included; Windows uses their catalog
  colors rather than Noctalia's generated surface adjustments.

## Personal settings

Create `%LOCALAPPDATA%\nvim\lua\softvim\local.lua` (adjust the app directory if
you used `-AppName`):

```lua
return {
  theme = "portable", -- portable, litecreep, memorycreep, tentaflake
  mode = "dark",      -- dark or light
  install_tools = true,
  install_parsers = true,
  voice = { command = "parloquent", language = "de" },
  servers = {},       -- native Neovim LSP overrides, keyed by server name
}
```

`:SoftvimTheme tentaflake light`, `:SoftvimTheme dark`, and
`:SoftvimTheme toggle` change the current session. Set the local file to keep a
selection across restarts. Put a custom server's `cmd` and settings under
`servers`, for example `servers.lua_ls = { cmd = { "C:/tools/lua-language-server.exe" } }`.

## Development and source updates

Source snapshot: dotfiles commit `823c3bcd44a2bb0f04ffa01180361c0895ee81e5`.
The exporter reads the portable editor modules, coaching setup, and shared
palette maps. The voice Lua module is copied from the desktop integration.
It never modifies the dotfiles checkout.

```sh
nix develop path:.
bash scripts/sync-dotfiles.sh /path/to/dotfiles
stylua nvim checks
project-check fast
project-check full
```

Fast checks cover formatting, lint, all source options and keymaps, every
palette in both modes, async tool-install recovery, and PowerShell installation behavior. Full checks also
load the real locked plugins, exercise file-tree and save-time formatting
interactions, and build the isolated Nix core check. Runtime checks use the
ignored `.test-runtime/` directory and download dependencies on first use.
The tests can run on Linux; native Windows rendering, clipboard, and terminal
behavior require verification on Windows. A live Mason registry fetch failed
at the GitHub API in this development environment; its failure and retry path
is tested separately. The live language-server check uses the installed Lua
server, rather than claiming that a blocked Mason download succeeded.
