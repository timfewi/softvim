vim.opt.rtp:prepend(vim.fn.getcwd() .. "/nvim")
local mirror = require("softvim.data").mirror
require("softvim.options")
require("softvim.keymaps")
require("softvim.theme").setup()
assert(vim.g.mapleader == " ")
for name, value in pairs(mirror.options) do
  local actual = type(value) == "table" and vim.opt[name]:get() or vim.o[name]
  assert(vim.deep_equal(actual, value), "Option differs from dotfiles: " .. name)
end
assert(vim.diagnostic.config().severity_sort and vim.diagnostic.config().virtual_text)
assert(vim.fn.isdirectory(vim.o.undodir) == 1, "Persistent undo directory is missing")
for _, mapping in ipairs(mirror.keymaps) do
  local modes = type(mapping.mode) == "table" and mapping.mode or { mapping.mode }
  for _, mode in ipairs(modes) do
    local actual = vim.fn.maparg(mapping.key, mode, false, true)
    assert(actual.desc == mapping.options.desc, "Missing mapping: " .. mapping.key)
    if type(mapping.action) == "string" then
      assert(actual.rhs == mapping.action, "Changed mapping: " .. mapping.key)
    else
      assert(type(actual.callback) == "function", "Missing callback: " .. mapping.key)
    end
  end
end
for _, group in ipairs(mirror.pluginSettings["which-key"].spec) do
  assert(group[1] and group.group, "Nix positional values were not converted")
end
-- Exercise every palette and both directions of mode switching, including style removal.
for name, modes in pairs(mirror.theme.palettes) do
  for mode, palette in pairs(modes) do
    vim.cmd("SoftvimTheme " .. name .. " " .. mode)
    assert(vim.o.background == mode)
    for group, expected in pairs(mirror.theme[mode]) do
      local actual = vim.api.nvim_get_hl(0, { name = group, link = true })
      for field, value in pairs(expected) do
        if type(value) == "string" and value:match("^{{") then
          value = palette[value:match("{{(%w+)}}")]
        end
        if field == "fg" or field == "bg" or field == "sp" then
          value = value == "NONE" and nil or tonumber(value:sub(2), 16)
        end
        assert(actual[field] == value, "Theme differs: " .. name .. " " .. mode .. " " .. group .. " " .. field)
      end
    end
  end
end
vim.cmd("SoftvimTheme portable light")
vim.cmd("SoftvimTheme toggle")
local keyword = vim.api.nvim_get_hl(0, { name = "Keyword" })
assert(keyword.italic and not keyword.bold, "Dark mode retained light keyword style")
assert(vim.api.nvim_get_hl(0, { name = "Normal" }).bg == nil, "Background must stay transparent")
print("Core checks passed: source options, keymaps, undo, and all dark/light palettes")
