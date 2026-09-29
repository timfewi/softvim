local settings = require("softvim.settings").voice
if vim.fn.executable(settings.command) ~= 1 then
  return
end
vim.g.parloquent_command = settings.command
vim.g.parloquent_language = settings.language
for key, action in pairs({ ez = "narrate", ec = "summarize", ee = "explain", eo = "one_sentence" }) do
  vim.keymap.set("n", "<leader>" .. key, function()
    require("parloquent")[action]()
  end, { desc = "Parloquent " .. action })
  vim.keymap.set("x", "<leader>" .. key, function()
    require("parloquent")[action .. "_selection"]()
  end, { desc = "Parloquent " .. action .. " selection" })
end
