return {
  'tpope/vim-fugitive',
  cmd = { 'Git', 'Gvdiffsplit', 'Gdiffsplit', 'Gedit', 'Gread', 'Gwrite', 'Gblame' },
  -- Optionally, you can add keymaps
  keys = {
    { '<leader>gg', '<cmd>Git<cr>', desc = 'Git status' },
    { '<leader>gb', '<cmd>Git blame<cr>', desc = 'Git blame' },
    { '<leader>gd', '<cmd>Gvdiffsplit!<cr>', desc = 'Git 3-way merge diff' },
    { '<leader>gD', '<cmd>Gvdiffsplit<cr>', desc = 'Git diff vs index' },
    { '<leader>gh', '<cmd>diffget //2<cr>', desc = 'Get from LEFT (ours)' },
    { '<leader>gl', '<cmd>diffget //3<cr>', desc = 'Get from RIGHT (theirs)' },
  },
}
