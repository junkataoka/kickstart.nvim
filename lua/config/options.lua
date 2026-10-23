-- Leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Enable auto reload
vim.o.autoread = true
vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'CursorHoldI', 'FocusGained' }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = { '*' },
})

-- Spell checking: prose filetypes only (see autocmds.lua)
vim.o.spelllang = 'en_us'

-- Diff: histogram aligns moved/reordered blocks better than myers; higher
-- linematch pairs up more partially-changed lines (0.12 already adds inline:char)
vim.opt.diffopt:append { 'algorithm:histogram' }
vim.opt.diffopt:remove { 'linematch:40' }
vim.opt.diffopt:append { 'linematch:60' }

-- Nerd Font
vim.g.have_nerd_font = true

vim.filetype.add {
  extension = {
    jsonl = 'json',
  },
}

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

-- Enable line wrapping
vim.opt.wrap = true

-- Ensure a Neovim server for lazygit edits
if vim.v.servername == '' then
  local server = string.format('%s/nvim-%d.sock', vim.fn.stdpath 'cache', vim.fn.getpid())
  vim.fn.serverstart(server)
end
vim.env.NVIM = vim.v.servername
