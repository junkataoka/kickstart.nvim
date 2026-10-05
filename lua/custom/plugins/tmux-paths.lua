return {
  'junkataoka/tmux-paths.nvim',
  dependencies = { 'folke/snacks.nvim' },
  cmd = 'TmuxPaths',
  keys = {
    { '<leader>so', '<cmd>TmuxPaths<cr>', desc = '[S]earch paths from [O]ther tmux pane' },
  },
  opts = {},
}
