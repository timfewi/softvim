vim.opt.rtp:prepend(vim.fn.getcwd() .. "/nvim")
local installs, enables, errors = 0, 0, {}
local fixtures = {
  ["lua-language-server"] = { supported = true },
  nixd = { supported = false },
  pyright = { supported = true, installing = true },
  clangd = { supported = true, installed = true },
}
local success = true
package.loaded["softvim.lsp"] = {
  enable_available = function()
    enables = enables + 1
  end,
}
package.loaded["mason-registry"] = {
  -- Run in a fast event to exercise the real async callback boundary.
  refresh = function(callback)
    local timer = vim.uv.new_timer()
    timer:start(1, 0, function()
      timer:close()
      callback(success)
    end)
  end,
  has_package = function(name)
    return fixtures[name] ~= nil
  end,
  get_package = function(name)
    local state = fixtures[name]
    local listener
    return {
      is_installable = function()
        return state.supported
      end,
      is_installed = function()
        return state.installed or false
      end,
      is_installing = function()
        return state.installing or false
      end,
      once = function(_, event, callback)
        assert(event == "install:success")
        listener = callback
      end,
      install = function()
        assert(state.supported and not state.installed and not state.installing, "Installed an unavailable tool")
        installs = installs + 1
        listener()
      end,
    }
  end,
}
vim.notify = function(message, level)
  assert(not vim.in_fast_event(), "Notification escaped into a fast event")
  if level == vim.log.levels.ERROR then
    errors[#errors + 1] = message
  end
end
require("softvim.tools").install()
assert(
  vim.wait(1000, function()
    return enables == 1
  end),
  "New tools did not enable their language server"
)
assert(installs == 1, "Unsupported, installed, or pending tools were installed again")
success = false
require("softvim.tools").install()
assert(
  vim.wait(1000, function()
    return #errors == 1
  end),
  "Registry failure did not report recovery instructions"
)
assert(errors[1]:find(":SoftvimInstall", 1, true))
print("Tool checks passed: async completion, unsupported platforms, duplicate installs, and registry failure")
