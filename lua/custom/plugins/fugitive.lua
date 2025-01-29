return {
  'tpope/vim-fugitive',
  cmd = 'Git',
  -- Optionally, you can add keymaps
  keys = {
    { '<leader>gg', '<cmd>Git<cr>', desc = 'Git status' },
    { '<leader>gb', '<cmd>Git blame<cr>', desc = 'Git blame' },
  },
}
