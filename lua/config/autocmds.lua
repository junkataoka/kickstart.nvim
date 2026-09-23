-- Highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Enable spell checking for prose',
  group = vim.api.nvim_create_augroup('prose-spell', { clear = true }),
  pattern = { 'markdown', 'text', 'gitcommit', 'tex', 'plaintex', 'octo' },
  callback = function()
    vim.opt_local.spell = true
  end,
})
