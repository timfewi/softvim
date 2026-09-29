local data = require("softvim.data")
local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(path .. "/lua/lazy/init.lua") then
  if vim.fn.executable("git") ~= 1 then
    error("Git is required to install plugins. Install Git for Windows and restart the terminal.")
  end
  local result = vim
    .system({
      "git",
      "clone",
      "--filter=blob:none",
      "--branch=stable",
      "https://github.com/folke/lazy.nvim.git",
      path,
    }, { text = true })
    :wait()
  if result.code ~= 0 then
    error("Could not install lazy.nvim: " .. (result.stderr or result.stdout or "unknown Git error"))
  end
end
vim.opt.rtp:prepend(path)
require("lazy").setup(require("softvim.plugins"), {
  defaults = { lazy = false },
  lockfile = data.root .. "/lazy-lock.json",
  change_detection = { notify = false },
  checker = { enabled = false },
})
