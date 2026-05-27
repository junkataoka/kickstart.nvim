return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  build = ':Copilot auth',
  event = 'InsertEnter',
  config = function()
    require('copilot').setup {
      suggestion = {
        enabled = not vim.g.ai_cmp,
        auto_trigger = true,
        keymap = {
          accept = '<C-]>',
          dismiss = '<C-e>',
          next = '<M-]>',
          prev = '<M-[>',
        },
      },
      panel = {
        enabled = true,
        auto_refresh = false,
        keymap = {
          open = '<M-p>',
        },
      },
      filetypes = {
        markdown = true,
        help = true,
        python = true,
        lua = true,
        yaml = true,
        javascript = true,
        typescript = true,
        rust = true,
        go = true,
      },
    }
  end,
}
