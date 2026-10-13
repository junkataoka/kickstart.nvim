return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre', 'BufRead', 'BufNewFile' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      local disable_filetypes = { c = true, cpp = true }
      local lsp_format_opt
      if disable_filetypes[vim.bo[bufnr].filetype] then
        lsp_format_opt = 'never'
      else
        lsp_format_opt = 'fallback'
      end
      return {
        -- markdown runs markdownlint --fix + prettier (~0.15s each); 500ms
        -- timed out under load, skipping fixes and leaving lint warnings.
        timeout_ms = vim.bo[bufnr].filetype == 'markdown' and 2000 or 500,
        lsp_format = lsp_format_opt,
      }
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'ruff_organize_imports', 'ruff_format' },
      markdown = { 'markdownlint', 'prettier' },
    },
  },
}
