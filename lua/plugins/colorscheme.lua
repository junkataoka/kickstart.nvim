return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  opts = {
    flavour = 'mocha',
    transparent_background = false, -- translucency behind text hurts markdown contrast
    no_italic = false,
    styles = { comments = {} },
    integrations = {
      blink_cmp = true,
      markview = true,
      noice = true,
      snacks = { enabled = true },
      which_key = true,
      gitsigns = true,
      mason = true,
      treesitter = true,
      native_lsp = { enabled = true },
    },
  },
  config = function(_, opts)
    require('catppuccin').setup(opts)
    vim.cmd.colorscheme 'catppuccin-mocha'
  end,
}
