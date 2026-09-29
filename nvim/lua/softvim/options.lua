local mirror = require("softvim.data").mirror
vim.g.mapleader = mirror.leader
for name, value in pairs(mirror.options) do
  vim.opt[name] = value
end
vim.diagnostic.config(mirror.diagnostics)
-- Native Windows Neovim supplies win32yank/Windows clipboard support itself.
-- Do not carry over NixVim's wl-copy provider or Nix store interpreter paths.
local undo = vim.fn.stdpath("state") .. "/undo"
vim.fn.mkdir(undo, "p")
vim.opt.undodir = undo
