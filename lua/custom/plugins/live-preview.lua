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

-- Server root is cwd, so files outside it (e.g. ~/.copilot/session-state/*.md)
-- 404. For those, serve the file's own directory instead (dynamic_root).
local function outside_cwd(file)
  local real = vim.uv.fs_realpath(file)
  local cwd = vim.uv.fs_realpath(vim.uv.cwd() or '')
  return not (real and cwd and vim.fs.relpath(cwd, real))
end

local previewed -- file the running server was started for

local function start(file)
  if file then vim.cmd.edit(vim.fn.fnameescape(file)) end
  local lp = require 'livepreview'
  previewed = vim.api.nvim_buf_get_name(0)
  local cfg = { dynamic_root = outside_cwd(previewed) }
  if not lp.is_running() then cfg.port = free_port(5500) end
  require('livepreview.config').set(cfg)
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
        -- Server root is fixed at start; on another file, restart (re-rooting
        -- if needed) instead of closing, else the old tab 404s.
        if require('livepreview').is_running() and vim.api.nvim_buf_get_name(0) == previewed then
          vim.cmd 'LivePreview close'
        else
          start()
        end
      end,
      desc = '[M]arkdown [P]review toggle (restarts on other file)',
      ft = 'markdown',
    },
    { '<leader>mP', pick, desc = '[M]arkdown [P]review pick file' },
  },
  config = function()
    require('livepreview.config').set { sync_scroll = true }
  end,
}
