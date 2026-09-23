return {
  'olimorris/codecompanion.nvim',
  cmd = { 'CodeCompanion', 'CodeCompanionChat', 'CodeCompanionActions', 'CodeCompanionCmd' },
  keys = {
    { '<leader>cc', '<cmd>CodeCompanionChat Toggle<CR>', mode = { 'n', 'v' }, desc = '[C]odeCompanion: [C]hat toggle' },
    { '<leader>ca', '<cmd>CodeCompanionActions<CR>', mode = { 'n', 'v' }, desc = '[C]odeCompanion: [A]ctions palette' },
    { '<leader>ci', '<cmd>CodeCompanion<CR>', mode = 'n', desc = '[C]odeCompanion: [I]nline' },
    { '<leader>ci', '<cmd>CodeCompanion<CR>', mode = 'v', desc = '[C]odeCompanion: [I]nline w/ selection' },
    { '<leader>cp', '<cmd>CodeCompanionChat Add<CR>', mode = { 'n', 'v' }, desc = '[C]odeCompanion: [P]ush buffer/selection to chat' },
    { '<leader>cq', ':CodeCompanion ', mode = 'n', desc = '[C]odeCompanion: [Q]uick prompt' },
  },
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
                default = 'gpt-6-astra',
              },
              ['reasoning.effort'] = {
                default = 'high',
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
