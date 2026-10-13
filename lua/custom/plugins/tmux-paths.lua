return {
  'junkataoka/tmux-paths.nvim',
  dir = '~/projects/tmux-paths.nvim', -- local dev copy; remove after pushing upstream
  dependencies = { 'folke/snacks.nvim' },
  cmd = 'TmuxPaths', -- <leader>so now opens util.recent_files (see snacks.lua)
  opts = {},
}
