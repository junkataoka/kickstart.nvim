-- Inline merge-conflict resolution. Only active in buffers with conflict markers:
--   co / ct / cb / c0  choose ours / theirs / both / none
--   ]x / [x            next / previous conflict
--   <leader>gx         all conflicts to quickfix
return {
  'akinsho/git-conflict.nvim',
  version = '*',
  event = { 'BufReadPre', 'BufNewFile' },
  keys = {
    { '<leader>gx', '<cmd>GitConflictListQf<cr>', desc = 'Git conflicts to quickfi[x]' },
  },
  opts = {
    default_mappings = true,
    -- plugin's own option calls vim.diagnostic.disable (removed in nvim 0.12); handled below
    disable_diagnostics = false,
  },
  config = function(_, opts)
    require('git-conflict').setup(opts)
    local group = vim.api.nvim_create_augroup('user_git_conflict_diag', { clear = true })
    -- LSP errors on marker lines are just noise while resolving
    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'GitConflictDetected',
      callback = function(ev) vim.diagnostic.enable(false, { bufnr = ev.buf }) end,
    })
    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'GitConflictResolved',
      callback = function(ev) vim.diagnostic.enable(true, { bufnr = ev.buf }) end,
    })
  end,
}
