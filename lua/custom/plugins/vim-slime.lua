return {
  'jpalardy/vim-slime',
  init = function()
    vim.g.slime_target = 'tmux'
    -- Default to the pane below in the current window
    vim.g.slime_default_config = {
      socket_name = 'default',
      target_pane = '{down-of}',
    }
    vim.g.slime_dont_ask_default = 1
    -- Use a temp file instead of a socket for reliability
    vim.g.slime_bracketed_paste = 1
    -- Python-friendly: handle indentation properly
    vim.g.slime_python_ipython = 0
  end,
  keys = {
    { '<leader>sc', '<Plug>SlimeConfig', desc = '[S]lime [C]onfig — pick target pane' },
    { '<leader>ss', '<Plug>SlimeParagraphSend', desc = '[S]lime [S]end paragraph' },
    { '<leader>ss', '<Plug>SlimeRegionSend', mode = 'v', desc = '[S]lime [S]end selection' },
    { '<leader>sl', '<Plug>SlimeLineSend', desc = '[S]lime send [L]ine' },
  },
}
