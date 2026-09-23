return {
  'folke/tokyonight.nvim',
  priority = 1000,
  opts = {
    transparent = false, -- solid bg: translucency behind text hurt markdown contrast
  },
  init = function()
    vim.cmd.colorscheme 'tokyonight-night'
    vim.cmd.hi 'Comment gui=none'
  end,
}
