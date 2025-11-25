-- Clear highlights on search
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Window resizing
vim.keymap.set('n', '<leader>wl', ':vertical resize -10<CR>', { silent = true, desc = 'Decrease window width' })
vim.keymap.set('n', '<leader>wh', ':vertical resize +10<CR>', { silent = true, desc = 'Increase window width' })
vim.keymap.set('n', '<leader>wj', ':resize -10<CR>', { silent = true, desc = 'Decrease window height' })
vim.keymap.set('n', '<leader>wk', ':resize +10<CR>', { silent = true, desc = 'Increase window height' })

-- Increment number
vim.keymap.set('n', '<C-s>', '<C-a>', { desc = 'Increment number' })
