return {
  'OXY2DEV/markview.nvim',
  lazy = false,
  opts = {
    preview = {
      filetypes = { 'markdown', 'codecompanion' },
      ignore_buftypes = {},
      modes = { 'n', 'no', 'c' },
      hybrid_modes = { 'n' }, -- Show raw markdown on cursor line even in normal mode
      callbacks = {
        on_enable = function(_, win)
          vim.wo[win].conceallevel = 2
          vim.wo[win].concealcursor = ''
        end,
      },
    },
  },
}
