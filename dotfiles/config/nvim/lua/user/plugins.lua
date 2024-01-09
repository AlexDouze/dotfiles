-- disable netrw for nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- install lazy.nvim if not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- install plugins
require("lazy").setup({
  "nvim-lua/plenary.nvim",
  {
    'maxmx03/solarized.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = 'light' -- or 'light'
      vim.cmd.colorscheme 'solarized'
    end,
  },
  "nvim-tree/nvim-tree.lua",
  "nvim-tree/nvim-web-devicons",
  "github/copilot.vim",
  "rstacruz/vim-closer",
  {
      'numToStr/Comment.nvim',
      lazy = false,
  },
  {"nvim-treesitter/nvim-treesitter", run = ":TSUpdate"},
  "JoosepAlviste/nvim-ts-context-commentstring",
  "lewis6991/gitsigns.nvim",
  "akinsho/toggleterm.nvim",
  "cormacrelf/dark-notify",
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
   },
})

-- empty setup using defaults
require("nvim-tree").setup()

-- copilot
vim.g.copilot_filetypes = {
  yaml = true,
  gitrebase = true
}
