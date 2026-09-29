local M = {}
M.root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))))

-- This is repository-owned configuration generated from Nix, including Lua callbacks.
function M.resolve(value)
  if type(value) ~= "table" then
    return value
  end
  if value.__raw then
    return assert(loadstring("return " .. value.__raw, "dotfiles callback"))()
  end
  local result = {}
  for key, item in pairs(value) do
    if type(key) == "string" then
      key = tonumber(key:match("^__unkeyed%-(%d+)$")) or key
    end
    result[key] = M.resolve(item)
  end
  return result
end

M.mirror = M.resolve(vim.json.decode(table.concat(vim.fn.readfile(M.root .. "/lua/softvim/mirror.json"), "\n")))
return M
