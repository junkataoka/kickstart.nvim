return {
  'christoomey/vim-tmux-navigator',
  lazy = false,
  keys = {
    { '<c-h>', '<cmd>TmuxNavigateLeft<cr>', desc = 'Tmux navigate left' },
    { '<c-j>', '<cmd>TmuxNavigateDown<cr>', desc = 'Tmux navigate down' },
    { '<c-k>', '<cmd>TmuxNavigateUp<cr>', desc = 'Tmux navigate up' },
    { '<c-l>', '<cmd>TmuxNavigateRight<cr>', desc = 'Tmux navigate right' },
    { '<c-\\>', '<cmd>TmuxNavigatePrevious<cr>', desc = 'Tmux navigate previous' },
  },
  config = function()
    local function term_nav(direction)
      return function()
        local cfg = vim.api.nvim_win_get_config(0)
        if cfg.relative ~= '' then
          vim.cmd('close')
        else
          vim.cmd('stopinsert')
        end
        vim.cmd('TmuxNavigate' .. direction)
      end
    end
    vim.api.nvim_create_autocmd('TermOpen', {
      callback = function(args)
        local opts = { buffer = args.buf, silent = true }
        vim.keymap.set('t', '<c-h>', term_nav('Left'), opts)
        vim.keymap.set('t', '<c-j>', term_nav('Down'), opts)
        vim.keymap.set('t', '<c-k>', term_nav('Up'), opts)
        vim.keymap.set('t', '<c-l>', term_nav('Right'), opts)
      end,
    })
  end,
}
