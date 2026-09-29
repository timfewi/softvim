local M = {}
local source = require("softvim.data").mirror.theme
local settings = require("softvim.settings")

local function colorize(value, palette)
  if type(value) == "string" then
    return value:gsub("{{(%w+)}}", function(role)
      return assert(palette[role], "Missing theme role: " .. role)
    end)
  end
  if type(value) ~= "table" then
    return value
  end
  local result = {}
  for key, item in pairs(value) do
    result[key] = colorize(item, palette)
  end
  return result
end

function M.lualine()
  return colorize(source.lualine, source.palettes[settings.theme][settings.mode])
end

function M.apply()
  local palette = assert(source.palettes[settings.theme], "Unknown theme: " .. settings.theme)[settings.mode]
  assert(palette, "Theme mode must be dark or light")
  vim.o.background = settings.mode
  -- Clear groups first: switching from light to dark must also remove light-only styles.
  vim.cmd.colorscheme("default")
  for group, style in pairs(colorize(source[settings.mode], palette)) do
    vim.api.nvim_set_hl(0, group, style)
  end
  local ok, lualine = pcall(require, "lualine")
  if ok then
    lualine.setup({ options = { theme = M.lualine() } })
  end
end

function M.setup()
  M.apply()
  local group = vim.api.nvim_create_augroup("SoftvimTheme", { clear = true })
  vim.api.nvim_create_autocmd("VimEnter", { group = group, callback = M.apply })
  vim.api.nvim_create_user_command("SoftvimTheme", function(args)
    local name, mode = settings.theme, settings.mode
    for _, item in ipairs(args.fargs) do
      if item == "toggle" then
        mode = mode == "dark" and "light" or "dark"
      elseif item == "dark" or item == "light" then
        mode = item
      elseif source.palettes[item] then
        name = item
      else
        error("Unknown theme or mode: " .. item)
      end
    end
    settings.theme, settings.mode = name, mode
    M.apply()
    vim.notify("Theme: " .. name .. " " .. mode)
  end, {
    nargs = "*",
    complete = function()
      return vim.list_extend(vim.tbl_keys(source.palettes), { "dark", "light", "toggle" })
    end,
    desc = "Select the shared dotfiles palette and mode",
  })
end
return M
