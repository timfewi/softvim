local M = {}
function M.check()
  vim.health.start("Softvim prerequisites")
  for _, command in ipairs({ "git", "rg", "fd", "lazygit", "cmake", "tree-sitter", "curl", "tar", "node", "npm" }) do
    if vim.fn.executable(command) == 1 then
      vim.health.ok(command .. " is available")
    else
      vim.health.warn(command .. " is missing", "See the Windows setup commands in README.md")
    end
  end
  local compiler = false
  for _, command in ipairs({ "cc", "gcc", "clang", "cl", "zig" }) do
    compiler = compiler or vim.fn.executable(command) == 1
  end
  if compiler then
    vim.health.ok("C compiler is available")
  else
    vim.health.warn("A C compiler is required for Tree-sitter and Telescope FZF")
  end
  vim.health.start("Language servers")
  for name in pairs(require("softvim.data").mirror.lsp.servers) do
    local config = vim.lsp.config[name]
    if config and type(config.cmd) == "table" and vim.fn.executable(config.cmd[1]) == 1 then
      vim.health.ok(name .. " is available")
    else
      vim.health.warn(name .. " is unavailable", "Run :SoftvimInstall and inspect :Mason; see README.md for Nix tools")
    end
  end
  vim.health.start("Optional integrations")
  local voice = require("softvim.settings").voice.command
  if vim.fn.executable(voice) == 1 then
    vim.health.ok("Parloquent voice shortcuts are enabled")
  else
    vim.health.info("Parloquent is not installed; voice shortcuts are unbound")
  end
end
return M
