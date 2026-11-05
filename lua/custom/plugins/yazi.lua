return {
  'mikavilpas/yazi.nvim',
  version = '*', -- use the latest stable version
  event = 'VeryLazy',
  dependencies = {
    { 'nvim-lua/plenary.nvim', lazy = true },
  },
  keys = {
    -- 👇 in this section, choose your own keymappings!
    {
      '\\',
      mode = { 'n', 'v' },
      '<cmd>Yazi<cr>',
      desc = 'Open yazi at the current file',
    },
    {
      -- Open in the current working directory
      '=\\',
      '<cmd>Yazi cwd<cr>',
      desc = "Open the file manager in nvim's working directory",
    },
    {
      -- Open in the project root (requires project.nvim)
      '<leader>p\\',
      '<cmd>ProjectRoot | Yazi cwd<cr>',
      desc = 'Open yazi in project root',
    },
    {
      '<leader>\\',
      '<cmd>Yazi toggle<cr>',
      desc = 'Resume the last yazi session',
    },
  },
  ---@type YaziConfig | {}
  opts = {
    -- if you want to open yazi instead of netrw, see below for more info
    open_for_directories = false,
    keymaps = {
      show_help = '<f1>',
    },
  },
  -- 👇 if you use `open_for_directories=true`, this is recommended
  init = function()
    -- mark netrw as loaded so it's not loaded at all.
    --
    -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
    vim.g.loaded_netrwPlugin = 1

    -- Hand binary docs to the OS viewer no matter how they get opened
    -- (yazi enter/split/tab/multi-select, :edit, pickers, ...).
    local exts = { 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'key', 'numbers', 'pages' }
    local patterns = {}
    for _, e in ipairs(exts) do
      table.insert(patterns, '*.' .. e)
      table.insert(patterns, '*.' .. e:upper())
    end
    vim.api.nvim_create_autocmd('BufReadCmd', {
      group = vim.api.nvim_create_augroup('open-binary-externally', { clear = true }),
      pattern = patterns,
      callback = function(ev)
        vim.ui.open(vim.fn.fnamemodify(ev.match, ':p'))
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(ev.buf) then
            return
          end
          for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
            vim.api.nvim_win_call(win, function()
              vim.cmd 'silent! buffer #'
            end)
          end
          pcall(vim.api.nvim_buf_delete, ev.buf, { force = true })
        end)
      end,
    })
  end,
}
