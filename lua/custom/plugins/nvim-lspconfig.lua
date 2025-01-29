return {
  'neovim/nvim-lspconfig',
  opts = {
    servers = {
      pyright = {}, -- Python LSP
    },
    setup = {
      -- Extend or modify your keymaps
      on_attach = function(client, bufnr)
        local keys = {
          {
            'gd',
            function()
              require('telescope.builtin').lsp_definitions { reuse_win = true }
            end,
            desc = 'Goto Definition',
            has = 'definition',
          },
          { 'gr', '<cmd>Telescope lsp_references<cr>', desc = 'References', nowait = true },
          {
            'gI',
            function()
              require('telescope.builtin').lsp_implementations { reuse_win = true }
            end,
            desc = 'Goto Implementation',
          },
          {
            'gy',
            function()
              require('telescope.builtin').lsp_type_definitions { reuse_win = true }
            end,
            desc = 'Goto T[y]pe Definition',
          },
        }
        -- Apply keymaps
        for _, key in ipairs(keys) do
          if not key.has or client.server_capabilities[key.has .. 'Provider'] then
            vim.keymap.set('n', key[1], key[2], { buffer = bufnr, desc = key.desc })
          end
        end
      end,
    },
  },
}
