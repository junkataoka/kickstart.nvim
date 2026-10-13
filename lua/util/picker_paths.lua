-- Snacks picker actions that copy the selected file path(s), relative to the
-- current Neovim cwd or absolute, to the unnamed register and the system
-- clipboard ('+'). The picker stays open. Wired globally in snacks.lua.
local M = {}

local uv = vim.uv or vim.loop

local function canonical(path)
  path = vim.fs.normalize(vim.fn.fnamemodify(path, ':p'))
  return uv.fs_realpath(path) or path
end

-- Path of `target` relative to `base`, using `..` when target is outside base.
function M.relative(base, target)
  base, target = canonical(base), canonical(target)
  local direct = vim.fs.relpath(base, target)
  if direct then
    return direct
  end
  local b, t = vim.split(base, '/', { trimempty = true }), vim.split(target, '/', { trimempty = true })
  local i = 1
  while b[i] and t[i] and b[i] == t[i] do
    i = i + 1
  end
  local parts = {}
  for _ = i, #b do
    parts[#parts + 1] = '..'
  end
  vim.list_extend(parts, t, i)
  return table.concat(parts, '/')
end

local function copy(picker, absolute)
  local paths = {}
  for _, item in ipairs(picker:selected { fallback = true }) do
    local path = Snacks.picker.util.path(item)
    if path then
      path = canonical(path)
      paths[#paths + 1] = absolute and path or M.relative(vim.fn.getcwd(), path)
    end
  end
  if #paths == 0 then
    return vim.notify('Copy path: selected item has no file path', vim.log.levels.WARN)
  end
  local value = table.concat(paths, '\n')
  vim.fn.setreg('"', value)
  local ok, err = pcall(vim.fn.setreg, '+', value)
  local kind = absolute and 'absolute' or 'relative'
  if ok then
    vim.notify(('Copied %s path:\n%s'):format(kind, value))
  else
    vim.notify(('Copied %s path to unnamed register only (clipboard failed: %s):\n%s'):format(kind, err, value), vim.log.levels.WARN)
  end
end

M.actions = {
  copy_path_relative = {
    action = function(picker)
      copy(picker, false)
    end,
    desc = 'Copy path (relative to cwd)',
  },
  copy_path_absolute = {
    action = function(picker)
      copy(picker, true)
    end,
    desc = 'Copy path (absolute)',
  },
}

M.keys = {
  ['<a-y>'] = { 'copy_path_relative', mode = { 'n', 'i' } },
  ['<a-Y>'] = { 'copy_path_absolute', mode = { 'n', 'i' } },
}

return M
