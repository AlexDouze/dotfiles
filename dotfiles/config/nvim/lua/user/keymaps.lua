local opts = { noremap = true, silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

-- Remap leader key
keymap('', '<Space>', '<Nop>', opts)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Better window navigation
keymap('n', '<C-h>', '<C-w>h', opts)
keymap('n', '<C-j>', '<C-w>j', opts)
keymap('n', '<C-k>', '<C-w>k', opts)
keymap('n', '<C-l>', '<C-w>l', opts)

-- NvimTree
keymap('n', '<leader>t', ':NvimTreeToggle<cr>', opts)
keymap('n', '<leader>e', ':NvimTreeOpen<cr>', opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)
keymap("v", "p", '"_dP', opts) -- Paste without yanking

keymap("n", "<leader>y", '"+y', opts) -- Copy to clipboard in normal, visual, select and operator modes
keymap("v", "<leader>y", '"+y', opts) -- Copy to clipboard in normal, visual, select and operator modes
