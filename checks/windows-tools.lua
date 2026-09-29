local function run()
  assert(vim.v.errmsg == "", "Startup error: " .. vim.v.errmsg)
  require("nvim-treesitter").install({ "lua" }):wait(180000)
  local parser_file = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "parser", "lua.so")
  assert(vim.uv.fs_stat(parser_file), "Tree-sitter did not build the Lua parser")
  assert(vim.treesitter.language.add("lua", { path = parser_file }), "The native Lua parser could not load")
  vim.cmd.enew()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local answer = 42" })
  vim.bo.filetype = "lua"
  local trees = vim.treesitter.get_parser(0, "lua"):parse()
  assert(trees[1] and not trees[1]:root():has_error(), "The Lua parser did not parse valid Lua")
  local registry = require("mason-registry")
  local refreshed = false
  local refresh_success = false
  registry.refresh(function(success)
    refresh_success = success
    refreshed = true
  end)
  assert(
    vim.wait(60000, function()
      return refreshed
    end),
    "Mason registry refresh timed out"
  )
  assert(refresh_success, "Mason registry refresh failed")
  local package = registry.get_package("stylua")
  assert(package:is_installable(), "Mason did not support StyLua on this platform")
  package:install()
  assert(
    vim.wait(120000, function()
      return package:is_installed()
    end),
    "Mason did not install StyLua; inspect :MasonLog"
  )
  assert(vim.fn.executable("stylua") == 1, "Mason StyLua is missing from PATH")
  assert(#(_G.softvim_errors or {}) == 0, table.concat(_G.softvim_errors or {}, "\n"))
  print("Windows tools checks passed: native Lua syntax parser and Mason StyLua installation")
end
local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
