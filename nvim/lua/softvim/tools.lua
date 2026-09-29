local M = {}
M.packages = {
  "lua-language-server",
  "bash-language-server",
  "pyright",
  "typescript-language-server",
  "clangd",
  "gopls",
  "rust-analyzer",
  "yaml-language-server",
  "stylua",
  "ruff",
  "shfmt",
  "prettier",
  "deadnix",
  "statix",
  "nixd",
  "nixfmt",
}

function M.install()
  local registry = require("mason-registry")
  registry.refresh(vim.schedule_wrap(function(success)
    if not success then
      vim.notify(
        "Could not refresh the Mason registry. Check :MasonLog, then retry :SoftvimInstall.",
        vim.log.levels.ERROR
      )
      return
    end
    for _, name in ipairs(M.packages) do
      if registry.has_package(name) then
        local package = registry.get_package(name)
        if package:is_installable() and not package:is_installed() and not package:is_installing() then
          package:once(
            "install:success",
            vim.schedule_wrap(function()
              require("softvim.lsp").enable_available()
            end)
          )
          package:install()
        end
      end
    end
  end))
end

function M.setup()
  vim.api.nvim_create_user_command("SoftvimInstall", function()
    M.install()
    require("nvim-treesitter").install(require("softvim.data").mirror.parsers)
  end, { desc = "Install the dotfiles language tools and syntax parsers" })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("SoftvimTools", { clear = true }),
    once = true,
    callback = function()
      if require("softvim.settings").install_tools then
        M.install()
      end
    end,
  })
end
return M
