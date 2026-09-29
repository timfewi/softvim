local mirror = require("softvim.data").mirror
local settings = mirror.pluginSettings

local function plugin(repo, name, module, extra)
  return vim.tbl_extend("force", {
    repo,
    main = module,
    opts = settings[name],
  }, extra or {})
end

local function build_fzf(p)
  for _, command in ipairs({
    { "cmake", "-S", ".", "-B", "build", "-DCMAKE_BUILD_TYPE=Release" },
    { "cmake", "--build", "build", "--config", "Release" },
  }) do
    local result = vim.system(command, { cwd = p.dir, text = true }):wait()
    if result.code ~= 0 then
      error("Could not build Telescope FZF: " .. (result.stderr or result.stdout or "unknown error"))
    end
  end
  -- Single-config generators write here already. MSVC writes into Release/.
  -- Installing the library onto itself can remove it during RPATH adjustment.
  local library = "libfzf." .. (vim.fn.has("win32") == 1 and "dll" or "so")
  local destination = vim.fs.joinpath(p.dir, "build", library)
  if not vim.uv.fs_stat(destination) then
    local source = vim.fs.joinpath(p.dir, "build", "Release", library)
    local ok, err = vim.uv.fs_copyfile(source, destination)
    assert(ok, "Telescope FZF library was not built: " .. tostring(err))
  end
end

return {
  plugin("nvim-tree/nvim-web-devicons", "web-devicons", "nvim-web-devicons"),
  plugin("folke/which-key.nvim", "which-key", "which-key"),
  plugin("folke/trouble.nvim", "trouble", "trouble"),
  plugin("folke/noice.nvim", "noice", "noice", { dependencies = { "MunifTanjim/nui.nvim" } }),
  plugin("nvim-neo-tree/neo-tree.nvim", "neo-tree", "neo-tree", {
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "nvim-tree/nvim-web-devicons" },
  }),
  plugin("akinsho/bufferline.nvim", "bufferline", "bufferline"),
  plugin("sindrets/diffview.nvim", "diffview", "diffview", { dependencies = { "nvim-lua/plenary.nvim" } }),
  plugin("lewis6991/gitsigns.nvim", "gitsigns", "gitsigns"),
  plugin("nvim-lualine/lualine.nvim", "lualine", "lualine", {
    opts = function()
      return { options = { theme = require("softvim.theme").lualine() } }
    end,
  }),
  plugin("echasnovski/mini.ai", "mini-ai", "mini.ai"),
  plugin("echasnovski/mini.move", "mini-move", "mini.move"),
  plugin("folke/flash.nvim", "flash", "flash"),
  plugin("m4xshen/hardtime.nvim", "hardtime", "hardtime", { dependencies = { "MunifTanjim/nui.nvim" } }),
  plugin("akinsho/toggleterm.nvim", "toggleterm", "toggleterm", {
    opts = function()
      local opts = vim.deepcopy(settings.toggleterm)
      if vim.fn.has("win32") == 1 then
        opts.shell = vim.fn.executable("pwsh") == 1 and "pwsh"
          or (vim.fn.executable("powershell") == 1 and "powershell" or vim.o.shell)
      end
      return opts
    end,
  }),
  plugin("nvim-telescope/telescope.nvim", "telescope", "telescope", {
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = build_fzf },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
    end,
  }),
  plugin("saghen/blink.cmp", "blink-cmp", "blink.cmp", { version = "1.*" }),
  plugin("stevearc/conform.nvim", "conform-nvim", "conform"),
  {
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = mirror.lint.lintersByFt
      vim.api.nvim_create_autocmd(mirror.lint.autoCmd.event, {
        group = vim.api.nvim_create_augroup("SoftvimLint", { clear = true }),
        callback = function()
          local available = {}
          for _, name in ipairs(lint.linters_by_ft[vim.bo.filetype] or {}) do
            local command = lint.linters[name].cmd
            if type(command) == "function" then
              command = command()
            end
            if vim.fn.executable(command) == 1 then
              available[#available + 1] = name
            end
          end
          if #available > 0 then
            lint.try_lint(available)
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({})
      local group = vim.api.nvim_create_augroup("SoftvimTreesitter", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
          local language = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if language and pcall(vim.treesitter.language.add, language) then
            pcall(vim.treesitter.start, args.buf, language)
          end
        end,
      })
      vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        once = true,
        callback = function()
          if require("softvim.settings").install_parsers then
            require("nvim-treesitter").install(mirror.parsers)
          end
        end,
      })
    end,
  },
  plugin("nvim-treesitter/nvim-treesitter-textobjects", "treesitter-textobjects", "nvim-treesitter-textobjects", {
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  }),
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp", { "mason-org/mason.nvim", version = "v2.1.0", opts = {} } },
    config = function()
      require("softvim.lsp").setup()
      require("softvim.tools").setup()
    end,
  },
}
