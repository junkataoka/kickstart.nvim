return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    -- Set debug logging
    log_level = 'DEBUG',

    -- Configure adapters using new API
    adapters = {
      http = {
        copilot = function()
          return require('codecompanion.adapters').extend('copilot', {
            schema = {
              model = {
                default = 'claude-sonnet-4.5',
              },
            },
          })
        end,
      },
    },

    -- Set default adapter for all strategies
    strategies = {
      chat = {
        adapter = 'copilot',
      },
      inline = {
        adapter = 'copilot',
      },
      agent = {
        adapter = 'copilot',
      },
    },
  },
}
