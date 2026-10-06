-- Browser preview for Markdown/HTML/AsciiDoc/SVG. Serves files from cwd, so
-- relative links to other .md files open rendered (markdown-preview.nvim 404'd).
return {
  'brianhuster/live-preview.nvim',
  dependencies = { 'folke/snacks.nvim' },
  cmd = 'LivePreview',
  keys = {
    {
      '<leader>mp',
      function()
        if require('livepreview').is_running() then
          vim.cmd 'LivePreview close'
        else
          vim.cmd 'LivePreview start'
        end
      end,
      desc = '[M]arkdown [P]review toggle',
      ft = 'markdown',
    },
    { '<leader>mP', '<cmd>LivePreview pick<cr>', desc = '[M]arkdown [P]review pick file' },
  },
  opts = {
    picker = 'snacks.picker',
    sync_scroll = true,
  },
}
