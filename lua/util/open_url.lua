local M = {}

local function cursor_is_within(cursor_col, start_col, end_col)
  return cursor_col >= start_col and cursor_col <= end_col
end

function M.from_line(line, cursor_col)
  local search_from = 1

  while true do
    local start_col, end_col, url = line:find('%[[^%]]-%]%((https?://[^%s%)]+)%)', search_from)
    if not start_col then
      break
    end
    if cursor_is_within(cursor_col, start_col, end_col) then
      return url
    end
    search_from = end_col + 1
  end

  search_from = 1
  while true do
    local start_col, end_col = line:find('https?://[^%s<>"%[%]]+', search_from)
    if not start_col then
      return nil
    end

    local url = line:sub(start_col, end_col):gsub('[%)%]%},;.!?]+$', '')
    local url_end_col = start_col + #url - 1
    if cursor_is_within(cursor_col, start_col, end_col) then
      return url, url_end_col
    end
    search_from = end_col + 1
  end
end

function M.open_under_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local url = M.from_line(line, cursor[2] + 1)
  if not url then
    return false
  end

  local ok, process, err = pcall(vim.ui.open, url)
  if not ok or not process then
    vim.notify(('Could not open URL: %s'):format(err or process or 'unknown error'), vim.log.levels.ERROR)
  end
  return true
end

return M
