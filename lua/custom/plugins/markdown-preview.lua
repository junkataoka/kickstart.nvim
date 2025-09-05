return {
  'iamcco/markdown-preview.nvim',
  cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  build = 'cd app && npx --yes yarn install',
  init = function()
    vim.g.mkdp_filetypes = { 'markdown' }
    vim.g.mkdp_browser = 'safari' -- For Edge
    vim.g.mkdp_auto_start = 0
    vim.g.mkdp_auto_close = 1
  end,
  ft = { 'markdown' },
}
