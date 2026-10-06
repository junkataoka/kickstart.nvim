-- Browser preview for Markdown/HTML/AsciiDoc/SVG. Serves files from cwd, so
-- relative links to other .md files open rendered (markdown-preview.nvim 404'd).

-- Each nvim gets its own free port so several instances can preview at once
-- (a shared port makes the browser hit another instance's server/root).
local function free_port(start)
  for port = start, start + 100 do
    local tcp = vim.uv.new_tcp()
    local ok = tcp and tcp:bind('127.0.0.1', port) == 0 and tcp:listen(1, function() end) == 0
    if tcp then tcp:close() end
    if ok then return port end
  end
end

local function start(file)
  if file then vim.cmd.edit(vim.fn.fnameescape(file)) end
  local lp = require 'livepreview'
  if not lp.is_running() then
    require('livepreview.config').set { port = free_port(5500) }
  end
  vim.cmd 'LivePreview start'
end

-- Plugin's built-in `snacks.picker` option is broken (no picker.snacks fn).
local function pick()
  Snacks.picker.files {
    title = 'Live Preview',
    ft = { 'md', 'markdown', 'html', 'adoc', 'asciidoc', 'svg' },
    confirm = function(picker, item)
      picker:close()
      if item then start(Snacks.picker.util.path(item)) end
    end,
  }
end

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
          start()
        end
      end,
      desc = '[M]arkdown [P]review toggle',
      ft = 'markdown',
    },
    { '<leader>mP', pick, desc = '[M]arkdown [P]review pick file' },
  },
  config = function()
    require('livepreview.config').set { sync_scroll = true }
  end,
}
