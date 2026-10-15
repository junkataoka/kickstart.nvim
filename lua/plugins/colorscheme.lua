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

    -- Dim when the tmux pane/terminal loses focus (matches tmux window-style bg).
    -- Opaque swap instead of transparency, so markdown contrast is unaffected.
    local dim_bg = '#11111b'
    local groups = { 'Normal', 'NormalNC', 'SignColumn', 'EndOfBuffer', 'LineNr', 'FoldColumn' }
    local saved = {}
    local aug = vim.api.nvim_create_augroup('FocusDim', { clear = true })
    vim.api.nvim_create_autocmd('FocusLost', {
      group = aug,
      callback = function()
        if next(saved) then return end
        for _, g in ipairs(groups) do
          local hl = vim.api.nvim_get_hl(0, { name = g, link = false })
          saved[g] = hl
          vim.api.nvim_set_hl(0, g, vim.tbl_extend('force', hl, { bg = dim_bg }))
        end
      end,
    })
    vim.api.nvim_create_autocmd('FocusGained', {
      group = aug,
      callback = function()
        for g, hl in pairs(saved) do
          vim.api.nvim_set_hl(0, g, hl)
        end
        saved = {}
      end,
    })
  end,
}
