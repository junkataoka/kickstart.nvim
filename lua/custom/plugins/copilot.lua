return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  build = ':Copilot auth',
  event = 'InsertEnter',
  opts = {
    suggestion = {
      enabled = not vim.g.ai_cmp,
      auto_trigger = true,
      keymap = {
        accept = '<C-y>', -- handled by nvim-cmp / blink.cmp
        next = '<C-n>',
        prev = '<C-p>',
      },
    },
    panel = { enabled = true },
    filetypes = {
      markdown = true,
      help = true,
      python = true,
      lua = true,
      yaml = true,
    },
  },
}
