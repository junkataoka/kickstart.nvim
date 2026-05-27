return {
  'stevearc/aerial.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  opts = {
    backends = { 'lsp', 'treesitter', 'markdown', 'man' },
    layout = {
      max_width = { 40, 0.2 },
      min_width = 20,
      default_direction = 'prefer_left',
    },
    attach_mode = 'global',
    filter_kind = false,
    show_guides = true,
    guides = {
      mid_item = '├─',
      last_item = '└─',
      nested_top = '│ ',
      whitespace = '  ',
    },
  },
  keys = {
    { '<leader>a', '<cmd>AerialToggle!<CR>', desc = '[A]erial toggle' },
    { '{', '<cmd>AerialPrev<CR>', desc = 'Aerial previous symbol' },
    { '}', '<cmd>AerialNext<CR>', desc = 'Aerial next symbol' },
  },
}
