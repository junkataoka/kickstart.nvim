local ensure_installed = {
  'bash',
  'c',
  'diff',
  'dockerfile',
  'go',
  'gomod',
  'gosum',
  'html',
  'json',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'python',
  'query',
  'toml',
  'vim',
  'vimdoc',
  'yaml',
}

local function configure_incremental_selection()
  local api = vim.api
  local selections = {}

  local function vim_range(node, bufnr)
    local start_row, start_col, end_row, end_col = node:range()
    start_row = start_row + 1
    start_col = start_col + 1
    end_row = end_row + 1

    if end_col == 0 then
      end_row = end_row - 1
      local line = api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, false)[1] or ''
      end_col = math.max(#line, 1)
    end

    return start_row, start_col, end_row, end_col
  end

  local function select_node(node)
    if not node then
      return
    end

    local bufnr = api.nvim_get_current_buf()
    local start_row, start_col, end_row, end_col = vim_range(node, bufnr)
    if api.nvim_get_mode().mode ~= 'v' then
      api.nvim_cmd({ cmd = 'normal', bang = true, args = { 'v' } }, {})
    end
    api.nvim_win_set_cursor(0, { start_row, start_col - 1 })
    api.nvim_cmd({ cmd = 'normal', bang = true, args = { 'o' } }, {})
    api.nvim_win_set_cursor(0, { end_row, end_col - 1 })
  end

  local function init_selection()
    local bufnr = api.nvim_get_current_buf()
    local node = vim.treesitter.get_node({ bufnr = bufnr, ignore_injections = false })
    if not node then
      return
    end

    selections[bufnr] = {
      changedtick = api.nvim_buf_get_changedtick(bufnr),
      nodes = { node },
    }
    select_node(node)
  end

  local function change_selection(direction)
    local bufnr = api.nvim_get_current_buf()
    local state = selections[bufnr]
    if not state or state.changedtick ~= api.nvim_buf_get_changedtick(bufnr) then
      init_selection()
      return
    end

    if direction < 0 then
      if #state.nodes > 1 then
        table.remove(state.nodes)
        select_node(state.nodes[#state.nodes])
      end
      return
    end

    local node = state.nodes[#state.nodes]
    local start_row, start_col, end_row, end_col = node:range()
    repeat
      node = node:parent()
    until not node or not vim.deep_equal({ node:range() }, { start_row, start_col, end_row, end_col })

    if node then
      table.insert(state.nodes, node)
      select_node(node)
    end
  end

  vim.keymap.set('n', '<leader>v', init_selection, { desc = 'Start Tree-sitter selection' })
  vim.keymap.set('x', '<Tab>', function()
    change_selection(1)
  end, { desc = 'Grow Tree-sitter selection' })
  vim.keymap.set('x', '<S-Tab>', function()
    change_selection(1)
  end, { desc = 'Grow Tree-sitter selection to scope' })
  vim.keymap.set('x', '<BS>', function()
    change_selection(-1)
  end, { desc = 'Shrink Tree-sitter selection' })
end

local function configure_textobjects()
  local textobjects = require 'nvim-treesitter-textobjects'
  if type(textobjects.setup) ~= 'function' then
    vim.notify_once(
      'nvim-treesitter-textobjects is still on its legacy branch; run :Lazy sync and restart Neovim',
      vim.log.levels.WARN
    )
    return
  end

  textobjects.setup({
    select = { lookahead = true },
    move = { set_jumps = true },
  })

  local select = require 'nvim-treesitter-textobjects.select'
  local move = require 'nvim-treesitter-textobjects.move'

  local selections = {
    af = '@function.outer',
    ['if'] = '@function.inner',
    ac = '@class.outer',
    ic = '@class.inner',
    aa = '@parameter.outer',
    ia = '@parameter.inner',
  }
  for key, capture in pairs(selections) do
    local query = capture
    vim.keymap.set({ 'x', 'o' }, key, function()
      select.select_textobject(query, 'textobjects')
    end)
  end

  local movements = {
    [']f'] = { move.goto_next_start, '@function.outer' },
    [']c'] = { move.goto_next_start, '@class.outer' },
    [']F'] = { move.goto_next_end, '@function.outer' },
    [']C'] = { move.goto_next_end, '@class.outer' },
    ['[f'] = { move.goto_previous_start, '@function.outer' },
    ['[c'] = { move.goto_previous_start, '@class.outer' },
    ['[F'] = { move.goto_previous_end, '@function.outer' },
    ['[C'] = { move.goto_previous_end, '@class.outer' },
  }
  for key, movement in pairs(movements) do
    local action = movement[1]
    local query = movement[2]
    vim.keymap.set({ 'n', 'x', 'o' }, key, function()
      action(query, 'textobjects')
    end)
  end
end

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    dependencies = {
      {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        config = configure_textobjects,
      },
    },
    config = function()
      local treesitter = require 'nvim-treesitter'
      treesitter.setup({})
      treesitter.install(ensure_installed)

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local filetype = vim.bo[args.buf].filetype
          if filetype == 'latex' then
            return
          end

          if pcall(vim.treesitter.start, args.buf) and filetype ~= 'ruby' then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      configure_incremental_selection()
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-context',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      enable = true,
      max_lines = 3,
    },
  },
}
