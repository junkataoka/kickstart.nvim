return {
  'linux-cultist/venv-selector.nvim',
  dependencies = {
    'neovim/nvim-lspconfig',
    'folke/snacks.nvim',
  },
  ft = 'python',
  keys = {
    { '<leader>vs', '<cmd>VenvSelect<CR>', desc = 'Select Python virtual environment' },
  },
  opts = {},
}
