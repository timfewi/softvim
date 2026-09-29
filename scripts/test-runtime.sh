#!/usr/bin/env bash
set -euo pipefail
task_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd -- "$task_root"
export XDG_CONFIG_HOME="$task_root/.test-runtime/config"
export XDG_DATA_HOME="$task_root/.test-runtime/data"
export XDG_STATE_HOME="$task_root/.test-runtime/state"
export XDG_CACHE_HOME="$task_root/.test-runtime/cache"
export NVIM_APPNAME=softvim-test
mkdir -p "$XDG_CONFIG_HOME/$NVIM_APPNAME/lua/softvim" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
cp -r nvim/. "$XDG_CONFIG_HOME/$NVIM_APPNAME/"
printf '%s\n' 'return { install_tools = false, install_parsers = false }' \
  > "$XDG_CONFIG_HOME/$NVIM_APPNAME/lua/softvim/local.lua"
# First-time plugin bootstrap downloads the locked dependencies. Later checks reuse them.
nvim --headless '+Lazy! restore' +qa > .test-runtime/restore.log 2>&1
nvim --headless --cmd 'lua _G.softvim_errors = {}; vim.notify = function(msg, level) if level == vim.log.levels.ERROR then table.insert(_G.softvim_errors, tostring(msg)) end end' \
  -c "lua dofile('checks/runtime.lua')"
