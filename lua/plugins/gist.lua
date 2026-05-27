-- gist.nvim — snippet manager backed by GitHub gists (via `gh` CLI)
-- Workflow:
--   <leader>Gn  new gist from selection (visual) or buffer
--   <leader>Gl  list/preview gists; <CR> appends content at cursor
--   <leader>Gf  fork a gist by URL
--   <leader>Gd  delete gist under cursor (in list)
return {
  'Rawnly/gist.nvim',
  cmd = { 'GistCreate', 'GistCreateFromFile', 'GistsList' },
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('gist').setup {
      clipboard = '+',
      prompts = {
        create = {
          private = true,
          description = true,
          confirmation = false,
        },
      },
      platforms = {
        github = {
          private = true,
          cmd = 'gh',
          list = { limit = 100, read_only = false },
        },
      },
      list = {
        use_multiplexer = true,
        mappings = { next_file = '<C-n>', prev_file = '<C-p>' },
      },
    }

    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
    end

    map('n', '<leader>Gn', '<cmd>GistCreateFromFile<cr>', '[G]ist [N]ew from file')
    map('v', '<leader>Gn', ':GistCreate<cr>',           '[G]ist [N]ew from selection')
    map('n', '<leader>Gl', '<cmd>GistsList<cr>',         '[G]ist [L]ist')
  end,
}
