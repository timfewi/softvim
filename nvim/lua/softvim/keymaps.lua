local mirror = require("softvim.data").mirror
for _, mapping in ipairs(mirror.keymaps) do
  vim.keymap.set(mapping.mode, mapping.key, mapping.action, mapping.options or {})
end
for key, picker in pairs(mirror.telescopeMappings) do
  vim.keymap.set("n", key, "<cmd>Telescope " .. picker .. "<cr>", { desc = "Telescope " .. picker })
end
