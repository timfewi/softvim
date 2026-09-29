local defaults = {
  theme = "portable",
  mode = "dark",
  install_tools = true,
  install_parsers = true,
  voice = { command = "parloquent", language = "de" },
  -- Values here extend/override the source server settings.
  servers = {},
}
local path = require("softvim.data").root .. "/lua/softvim/local.lua"
if vim.uv.fs_stat(path) then
  return vim.tbl_deep_extend("force", defaults, assert(dofile(path)))
end
return defaults
