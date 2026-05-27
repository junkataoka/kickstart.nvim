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
    -- Checkbox rendering — match obsidian.nvim task states
    markdown_inline = {
      checkboxes = {
        enable = true,
        -- [ ] undone
        unchecked = { text = '󰄰', hl = 'MarkviewCheckboxUnchecked' },
        -- [x] done
        checked = { text = '󰗠', hl = 'MarkviewCheckboxChecked', scope_hl = 'MarkviewCheckboxChecked' },
        -- [-] pending (scope_hl = false overrides the default's "MarkviewCheckboxStriked" strikethrough)
        ['-'] = { text = '󰥔', hl = 'MarkviewCheckboxPending', scope_hl = false },
        -- [~] in-progress / working
        ['~'] = { text = '󰔟', hl = 'MarkviewCheckboxProgress' },
        -- [!] important
        ['!'] = { text = '󰀦', hl = 'MarkviewCheckboxUnchecked' },
        -- [?] uncertain / ambiguous
        ['?'] = { text = '󰋗', hl = 'MarkviewCheckboxPending' },
        -- [>] on hold / deferred
        ['>'] = { text = '󰒲', hl = 'MarkviewCheckboxPending' },
        -- [_] cancelled
        ['_'] = { text = '󰜺', hl = 'MarkviewCheckboxCancelled', scope_hl = 'MarkviewCheckboxStriked' },
      },
    },
  },
}
