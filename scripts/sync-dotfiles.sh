#!/usr/bin/env bash
set -euo pipefail
if [[ $# != 1 ]]; then
  printf 'Usage: bash scripts/sync-dotfiles.sh /path/to/dotfiles\n' >&2
  exit 2
fi
task_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
source_root=$(realpath -- "$1")
temporary=$(mktemp)
trap 'rm -f -- "$temporary"' EXIT
nix-instantiate --eval --strict --json "$task_root/scripts/export-dotfiles.nix" \
  --argstr dotfiles "$source_root" > "$temporary"
jq -S . "$temporary" > "$task_root/nvim/lua/softvim/mirror.json"
cp -- "$source_root/modules/home/desktop/lua/parloquent.lua" "$task_root/nvim/lua/parloquent.lua"
printf 'Updated the editor and theme snapshot from %s\n' "$source_root"
