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
                default = 'claude-sonnet-4',
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

    -- Display configuration (ADD THIS HERE)
    display = {
      chat = {
        intro_message = 'Welcome to CodeCompanion ✨!',
        separator = '─',
        show_context = true,
        show_header_separator = false,
        show_settings = false,
        show_token_count = true,
        start_in_insert_mode = false,

        -- Customize icons
        icons = {
          chat_context = '📎️',
          chat_fold = ' ',
        },

        -- Fold context for cleaner look
        fold_context = true,
        fold_reasoning = true,
      },
    },
  },
}
