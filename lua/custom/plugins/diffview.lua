return {
  'sindrets/diffview.nvim',
  dependencies = 'nvim-lua/plenary.nvim',
  cmd = { 'DiffviewOpen' },
  keys = {
    { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = 'DiffView' },
  },
}
