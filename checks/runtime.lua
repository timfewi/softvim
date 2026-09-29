local function run()
  local project_root = vim.fn.getcwd()
  assert(vim.v.errmsg == "", "Startup error: " .. vim.v.errmsg)
  assert(#(_G.softvim_errors or {}) == 0, table.concat(_G.softvim_errors or {}, "\n"))
  local lazy = require("lazy.core.config").plugins
  for name, plugin in pairs(lazy) do
    assert(plugin._.installed, "Plugin was not installed: " .. name)
    assert(plugin._.loaded, "Plugin was not loaded: " .. name)
  end
  assert(require("telescope").extensions.fzf, "Native FZF sorter failed to load")
  assert(require("telescope").extensions["ui-select"], "Telescope UI selection is missing")
  assert(require("blink.cmp").get_lsp_capabilities().textDocument.completion, "Completion is missing")
  local mirror = require("softvim.data").mirror
  local lua_settings = vim.lsp.config.lua_ls.settings.Lua
  assert(lua_settings.runtime.version == "LuaJIT" and lua_settings.diagnostics.globals[1] == "vim")
  assert(lua_settings.workspace.library[1] == vim.env.VIMRUNTIME)
  assert(vim.lsp.config.yamlls.settings.yaml.schemaStore.enable)
  assert(vim.lsp.config.gopls.settings.gopls.hints.parameterNames)
  assert(vim.lsp.config.ts_ls.init_options.preferences.includeInlayParameterNameHints == "all")
  local conform = require("conform")
  assert(vim.deep_equal(conform.formatters_by_ft, mirror.pluginSettings["conform-nvim"].formatters_by_ft))
  local scratch = vim.fn.tempname()
  vim.fn.mkdir(scratch .. "/.git", "p")
  vim.fn.writefile({ "hidden" }, scratch .. "/.env")
  vim.fn.writefile({ "metadata" }, scratch .. "/.git/config")
  local command = vim.deepcopy(require("telescope.config").pickers.find_files.find_command)
  command[#command + 1] = scratch
  local files = vim.fn.systemlist(command)
  assert(vim.v.shell_error == 0, "File finder command failed")
  assert(#files == 1 and files[1]:match("%.env$"), "Finder must include dotfiles and exclude .git")
  -- Exercise the actual mapped file-tree interaction.
  vim.cmd("cd " .. vim.fn.fnameescape(scratch))
  vim.cmd("edit " .. vim.fn.fnameescape(scratch .. "/.env"))
  vim.api.nvim_feedkeys("-", "xt", false)
  assert(
    vim.wait(1000, function()
      return vim.bo.filetype == "neo-tree"
    end),
    "Tree mapping did not open Neo-tree"
  )
  vim.api.nvim_feedkeys("-", "xt", false)
  assert(
    vim.wait(1000, function()
      return vim.bo.filetype ~= "neo-tree"
    end),
    "Tree mapping did not close Neo-tree"
  )
  -- Exercise real save-time formatting with the same Conform callback as Windows.
  vim.cmd("edit " .. vim.fn.fnameescape(scratch .. "/format.lua"))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x={a=1,b=2}", "print(x)" })
  vim.cmd.write()
  local formatted = table.concat(vim.fn.readfile(scratch .. "/format.lua"), "\n")
  assert(formatted:find("local x = {", 1, true), "Save-time formatting did not run")
  -- A live server must attach, install the source mappings, and understand `vim`.
  vim.fn.writefile({ "{}" }, scratch .. "/.luarc.json")
  vim.cmd("edit " .. vim.fn.fnameescape(scratch .. "/lsp.lua"))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "vim.print(softvim_missing_global)" })
  vim.cmd.write()
  assert(
    vim.wait(15000, function()
      return #vim.lsp.get_clients({ bufnr = 0, name = "lua_ls" }) > 0
    end),
    "Lua language server did not attach"
  )
  assert(
    vim.wait(15000, function()
      for _, diagnostic in ipairs(vim.diagnostic.get(0)) do
        if diagnostic.message:find("softvim_missing_global", 1, true) then
          return true
        end
      end
      return false
    end),
    "Lua server did not diagnose an undefined global"
  )
  for _, diagnostic in ipairs(vim.diagnostic.get(0)) do
    assert(not diagnostic.message:find("`vim`", 1, true), "Lua server did not recognize Neovim's global")
  end
  for key in pairs(mirror.lsp.keymaps.lspBuf) do
    assert(vim.fn.maparg(key, "n", false, true).buffer == 1, "LSP mapping was not attached: " .. key)
  end
  assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "Lua syntax highlighting is inactive")
  assert(vim.treesitter.query.get("lua", "textobjects"), "Function text-object queries are missing")
  for _, client in ipairs(vim.lsp.get_clients()) do
    client:stop(true)
  end
  vim.fn.delete(scratch, "rf")
  vim.cmd("cd " .. vim.fn.fnameescape(project_root))
  -- Check final highlight groups with all plugins loaded as well.
  dofile("checks/core.lua")
  assert(#(_G.softvim_errors or {}) == 0, table.concat(_G.softvim_errors or {}, "\n"))
  print("Runtime checks passed: locked plugins, completion, live Lua LSP, finder, tree shortcut, format on save")
end
local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
