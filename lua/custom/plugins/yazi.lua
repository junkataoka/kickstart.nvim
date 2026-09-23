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
    open_file_function = function(chosen_file, config, state)
      local binary_exts = { pdf = true, doc = true, docx = true, xls = true, xlsx = true, ppt = true, pptx = true, key = true, numbers = true, pages = true }
      local ext = (chosen_file:match '%.([^.]+)$' or ''):lower()
      if binary_exts[ext] then
        vim.system({ 'open', chosen_file }, { detach = true })
        return
      end
      vim.cmd('edit ' .. vim.fn.fnameescape(chosen_file))
    end,
  },
  -- 👇 if you use `open_for_directories=true`, this is recommended
  init = function()
    -- mark netrw as loaded so it's not loaded at all.
    --
    -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
    vim.g.loaded_netrwPlugin = 1
  end,
}
