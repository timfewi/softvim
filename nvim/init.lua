if vim.fn.has("nvim-0.12") ~= 1 then
  error("Softvim requires Neovim 0.12 or newer (the version used by the source dotfiles).")
end
require("softvim.options")
require("softvim.keymaps")
require("softvim.theme").setup()
require("softvim.lazy")
require("softvim.voice")
