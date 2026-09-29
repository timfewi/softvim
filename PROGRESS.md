# Progress

Objective: standalone native Windows Neovim and a public repository that can be
cloned on a fresh work laptop without files or state from the original laptop.

- Generated the source options, keymaps, plugin settings, LSP settings, syntax
  languages, palettes, and highlight maps from dotfiles. Source remains unchanged.
- Added Lazy/Mason delivery, Windows terminal selection, native clipboard
  behavior, source voice integration, health checks, and theme switching.
- Added a PowerShell installer with backup, upgrade, preview, and rollback.
- Added core, runtime, installer, and Nix checks. Core and installer tests passed.
- Runtime startup and native Telescope FZF load passed after fixing a build
  issue caused by installing the native library onto itself.
- Fast and full gates passed, including the real file-tree shortcut,
  save-time formatting, live Lua LSP attachment/diagnostics, and the isolated
  Nix core build. The generated snapshot matches the current source exactly.
- Native Windows UI/clipboard/terminal execution is unavailable on this Linux
  host. The PowerShell installer was exercised under PowerShell 7.6.5.
- A live Mason registry fetch failed at the GitHub API in this environment.
  The async regression check now passes for graceful failure, supported-platform
  filtering, duplicate installations and language-server activation. The final
  fast and full gates pass, including live syntax highlighting, text-object
  queries, and all palettes after plugins load.
- The Windows archive contains the complete portable configuration, installer,
  and README. PowerShell extracted it, compared every configuration file hash,
  and successfully installed the extracted copy into a temporary directory.
- Source parity and diff checks passed; dotfiles remains unchanged. Initial
  local verification could not exercise native Windows or live Mason downloads;
  the subsequent Windows CI results below supersede those limitations.
- Added HTTPS clone, ZIP fallback, install/update instructions, portable Git
  line-ending rules, and exclusions for local settings and common secret files.
- Added a fresh native Windows CI job covering PowerShell 5.1/7 installation,
  locked plugins, native FZF, a Lua parser, Mason, and editor interactions.
- Candidate publication files and existing commit history passed redacted
  Gitleaks scans; PowerShell scripts parsed and the workflow passed actionlint.
  Final `nix develop path:. -c project-check fast --json` and `full --json`
  both passed, including real plugin interactions and the isolated Nix build.
- Published `https://github.com/timfewi/softvim` with PUBLIC visibility. An
  anonymous HTTPS clone, with Git credentials/config disabled, matched the
  reviewed commit and passed the PowerShell installer tests from a clean
  directory containing spaces.
- Native Windows CI run `36639411703` passed on the published runtime code,
  including PowerShell 5.1/7 installation, freshly downloaded locked plugins,
  the FZF build, native Lua parser compilation, Mason StyLua installation,
  file-tree interaction, formatting on save, and live Lua LSP diagnostics.
  Evidence: https://github.com/timfewi/softvim/actions/runs/36639411703
- All requested implementation and publication work is complete. Manual
  rendering/clipboard/terminal QA remains outside the automated check scope.
