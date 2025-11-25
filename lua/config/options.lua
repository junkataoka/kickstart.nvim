-- Leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Enable auto reload
vim.o.autoread = true
vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'CursorHoldI', 'FocusGained' }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = { '*' },
})

-- Spell checking
vim.o.spell = true
vim.o.spelllang = 'en_us'

-- Nerd Font
vim.g.have_nerd_font = true

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Mouse mode
vim.opt.mouse = 'a'

-- Don't show mode (already in statusline)
vim.opt.showmode = false

-- Clipboard
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Break indent
vim.opt.breakindent = true

-- Undo history
vim.opt.undofile = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Sign column
vim.opt.signcolumn = 'yes'

-- Update time
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Splits
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Whitespace characters
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions
vim.opt.inccommand = 'split'

-- Cursor line
vim.opt.cursorline = true

-- Scroll offset
vim.opt.scrolloff = 10
