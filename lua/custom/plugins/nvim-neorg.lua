return {
  'nvim-neorg/neorg',
  lazy = false,
  version = '*',
  config = function()
    require('neorg').setup {
      load = {
        ['core.defaults'] = {},
        ['core.concealer'] = {
          config = {
            icon_preset = 'varied',
            icons = {
              delimiter = {
                horizontal_line = {
                  highlight = '@neorg.delimiters.horizontal_line',
                },
              },
              code_block = {
                -- If true will only dim the content of the code block (without the
                -- `@code` and `@end` lines), not the entirety of the code block itself.
                content_only = true,
                -- The width to use for code block backgrounds.
                --
                -- When set to `fullwidth` (the default), will create a background
                -- that spans the width of the buffer.
                --
                -- When set to `content`, will only span as far as the longest line
                -- within the code block.
                width = 'content',
                -- Additional padding to apply to either the left or the right. Making
                -- these values negative is considered undefined behaviour (it is
                -- likely to work, but it's not officially supported).
                padding = {
                  -- left = 20,
                  -- right = 20,
                },
                -- If `true` will conceal (hide) the `@code` and `@end` portion of the code
                -- block.
                conceal = true,
                nodes = { 'ranged_verbatim_tag' },
                highlight = 'CursorLine',
                -- render = module.public.icon_renderers.render_code_block,
                insert_enabled = true,
              },
            },
          },
        },
        ['core.integrations.treesitter'] = {},
        ['core.dirman'] = {
          config = {
            workspaces = {
              notes = '~/notes',
            },
            default_workspace = 'notes',
            index = 'index.norg',
          },
        },
        ['core.itero'] = {},
      },
    }
    vim.wo.foldlevel = 99
    vim.wo.conceallevel = 2
    -- Fix indentation issues with code blocks
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'norg',
      callback = function()
        vim.opt_local.indentexpr = ''
        vim.opt_local.autoindent = true
        vim.opt_local.smartindent = true
      end,
    })
  end,
}
