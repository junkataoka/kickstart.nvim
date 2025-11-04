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
            icon_preset = 'diamond',
            icons = {
              code_block = {
                conceal = true,
              },
            },
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
      },
    }

    -- Set concealing options for norg files
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'norg',
      callback = function()
        vim.opt_local.conceallevel = 2
        vim.opt_local.concealcursor = ''
      end,
    })
  end,
}
