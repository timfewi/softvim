local M = {}
local source = require("softvim.data").mirror.lsp

function M.enable_available()
  for name in pairs(source.servers) do
    local config = vim.lsp.config[name]
    if config and type(config.cmd) == "table" and vim.fn.executable(config.cmd[1]) == 1 then
      vim.lsp.enable(name)
    end
  end
end

function M.setup()
  for name, server in pairs(source.servers) do
    local server_settings = server.settings or {}
    -- NixVim adds these outer keys when generating the server configuration.
    if name == "lua_ls" then
      server_settings = { Lua = server_settings }
    elseif name == "yamlls" then
      server_settings = { yaml = server_settings }
    end
    vim.lsp.config(
      name,
      vim.tbl_deep_extend("force", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
        settings = server_settings,
      }, server.extraOptions or {}, require("softvim.settings").servers[name] or {})
    )
  end
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("SoftvimLsp", { clear = true }),
    callback = function(args)
      for key, action in pairs(source.keymaps.lspBuf) do
        vim.keymap.set("n", key, vim.lsp.buf[action], { buffer = args.buf, desc = "LSP " .. action })
      end
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client:supports_method("textDocument/inlayHint", args.buf) then
        vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
      end
    end,
  })
  M.enable_available()
end
return M
