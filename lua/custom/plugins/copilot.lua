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
        accept = '<Tab>', -- handled by nvim-cmp / blink.cmp
        next = '<M-]>',
        prev = '<M-[>',
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
