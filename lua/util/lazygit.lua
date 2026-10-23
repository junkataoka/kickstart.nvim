-- Glue between lazygit (running in a Snacks float) and the parent nvim.
--   edit(): called by lazygit's os.edit via `nvim --server $NVIM --remote-send`;
--           hides the lazygit float and opens the file in the window you came from.
--   refresh(): after leaving lazygit, reload changed buffers, drop buffers whose
--           files vanished (e.g. after a branch switch) and refresh git UI.
local M = {}

local function is_lazygit(buf)
  local t = vim.b[buf].snacks_terminal
  if not t then return false end
  local cmd = type(t.cmd) == 'table' and table.concat(t.cmd, ' ') or tostring(t.cmd or '')
  return cmd:find('lazygit', 1, true) ~= nil
end

local function hide_lazygit()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if is_lazygit(vim.api.nvim_win_get_buf(win)) then
      pcall(vim.api.nvim_win_hide, win)
    end
  end
end

--- @param file string path as given by lazygit (may be shell-quoted)
--- @param line? integer
function M.edit(file, line)
  file = file:gsub("^'(.*)'$", '%1')
  hide_lazygit()
  vim.cmd.stopinsert()
  vim.cmd.edit(vim.fn.fnameescape(file))
  if line and line > 0 then
    pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
    vim.cmd.normal { 'zz', bang = true }
  end
end

function M.refresh()
  pcall(vim.cmd.checktime)
  local gone = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].buflisted and vim.bo[buf].buftype == '' and name ~= ''
      and vim.api.nvim_buf_is_loaded(buf) and not vim.uv.fs_stat(name) then
      if vim.bo[buf].modified then
        vim.notify(('%s no longer exists on disk (kept: unsaved changes)'):format(vim.fn.fnamemodify(name, ':~:.')), vim.log.levels.WARN)
      else
        gone[#gone + 1] = vim.fn.fnamemodify(name, ':~:.')
        if _G.Snacks and Snacks.bufdelete then
          Snacks.bufdelete { buf = buf, force = true }
        else
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end
    end
  end
  if #gone > 0 then
    vim.notify('Closed buffers for files that no longer exist:\n' .. table.concat(gone, '\n'), vim.log.levels.INFO)
  end
  if package.loaded.gitsigns then
    pcall(require('gitsigns').refresh)
  end
  if package.loaded.lualine then
    pcall(require('lualine').refresh)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd({ 'TermClose', 'BufLeave', 'WinLeave' }, {
    group = vim.api.nvim_create_augroup('LazygitRefresh', { clear = true }),
    callback = function(ev)
      if is_lazygit(ev.buf) then
        vim.defer_fn(M.refresh, 50)
      end
    end,
  })
end

return M
