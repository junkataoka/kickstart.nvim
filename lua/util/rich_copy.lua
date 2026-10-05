-- Copy Markdown to the system clipboard as rich text (HTML) so it pastes with
-- headings, tables, and lists into Loop, Teams, Outlook, Word, etc.
-- Plain-text paste targets still receive the original Markdown.
local M = {}

local function strip_frontmatter(lines)
  if lines[1] ~= '---' then
    return lines
  end
  for i = 2, #lines do
    if lines[i] == '---' then
      return vim.list_slice(lines, i + 1)
    end
  end
  return lines
end

-- Relative links (repo docs, wikilinks) are dead outside the editor; keep their text.
local function strip_local_links(md)
  md = md:gsub('%[%[([^%]|]+)|([^%]]+)%]%]', '%2')
  md = md:gsub('%[%[([^%]]+)%]%]', '%1')
  md = md:gsub('%[([^%]]+)%]%(([^%)]+)%)', function(text, target)
    if target:match '^%a[%w+.-]*:' or target:match '^#' then
      return nil
    end
    return text
  end)
  return md
end

local function to_html(md)
  local res = vim.system({ 'pandoc', '-f', 'gfm', '-t', 'html' }, { stdin = md, text = true }):wait()
  if res.code ~= 0 then
    return nil, res.stderr
  end
  return res.stdout
end

local function set_clipboard(html, md)
  if vim.fn.has 'mac' == 1 then
    local hex = html:gsub('.', function(c)
      return string.format('%02x', c:byte())
    end)
    local tmp = vim.fn.tempname()
    vim.fn.writefile(vim.split(md, '\n', { plain = true }), tmp)
    local script = ('set the clipboard to {«class HTML»:«data HTML%s», string:(read POSIX file "%s" as «class utf8»)}'):format(hex, tmp)
    local res = vim.system({ 'osascript', '-e', script }):wait()
    vim.fn.delete(tmp)
    return res.code == 0, res.stderr
  end
  local cmd
  if vim.fn.executable 'wl-copy' == 1 then
    cmd = { 'wl-copy', '--type', 'text/html' }
  elseif vim.fn.executable 'xclip' == 1 then
    cmd = { 'xclip', '-selection', 'clipboard', '-t', 'text/html' }
  else
    return false, 'no HTML-capable clipboard tool (osascript, wl-copy, xclip)'
  end
  local res = vim.system(cmd, { stdin = html }):wait()
  return res.code == 0, res.stderr
end

---@param line1 integer|nil first line (1-based); whole buffer when nil
---@param line2 integer|nil last line (1-based)
function M.copy(line1, line2)
  if vim.fn.executable 'pandoc' == 0 then
    vim.notify('CopyRich: pandoc not found', vim.log.levels.ERROR)
    return
  end
  local whole = line1 == nil
  local lines = vim.api.nvim_buf_get_lines(0, (line1 or 1) - 1, line2 or -1, false)
  if whole or line1 == 1 then
    lines = strip_frontmatter(lines)
  end
  local md = strip_local_links(table.concat(lines, '\n')):gsub('^%s*\n', '')

  local html, err = to_html(md)
  if not html then
    vim.notify('CopyRich: pandoc failed: ' .. (err or ''), vim.log.levels.ERROR)
    return
  end
  local ok, cerr = set_clipboard(html, md)
  if not ok then
    vim.notify('CopyRich: clipboard failed: ' .. (cerr or ''), vim.log.levels.ERROR)
    return
  end
  vim.notify(('CopyRich: copied %d lines as rich text'):format(#lines))
end

return M
