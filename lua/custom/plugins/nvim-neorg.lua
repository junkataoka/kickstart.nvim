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
                content_only = true,
                width = 'content',
                padding = {},
                conceal = true,
                nodes = { 'ranged_verbatim_tag' },
                highlight = 'CursorLine',
                insert_enabled = true,
              },
            },
          },
        },
        ['core.integrations.treesitter'] = {},
        ['core.esupports.indent'] = {
          config = {
            enabled = false,
          },
        },
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

    -- Use BufEnter with defer to override neorg's indentexpr after it loads
    vim.api.nvim_create_autocmd('FileType', {
      pattern = '*.norg',
      callback = function()
        vim.wo.foldlevel = 99
        vim.opt_local.conceallevel = 2
        vim.opt_local.concealcursor = ''

        -- Defer to ensure it runs after neorg sets its indentexpr
        vim.schedule(function()
          vim.opt_local.indentexpr = ''
          vim.opt_local.autoindent = false
          vim.opt_local.smartindent = false
        end)
      end,
    })
  end,
}
