-- Newest-first file picker over the working directories of ALL tmux panes
-- (every session/window, including this one) plus Copilot CLI session files.
--
-- Files are discovered on disk with `rg --files` (asynchronously), so files that
-- were never opened or printed anywhere still show up. Ordering is by creation
-- time (birthtime) when the filesystem reports it, otherwise modification time.
local M = {}

M.config = {
  tmux = { 'tmux' }, -- command prefix, e.g. { 'tmux', '-L', 'socket' }
  rg = 'rg',
  copilot_root = '~/.copilot/session-state',
  -- Copilot session subtrees to include (relative to copilot_root); skips bulky metadata such as events.jsonl
  copilot_globs = { '*/files/**', '*/plan.md' },
  -- Excluded everywhere in addition to .gitignore/.ignore rules
  exclude = { '.git', 'node_modules', '.venv', 'venv', '__pycache__', '.mypy_cache', '.pytest_cache', '.ruff_cache', '.tox', '.cache', '.DS_Store' },
}

local uv = vim.uv or vim.loop

local function realpath(path)
  path = vim.fs.normalize(vim.fn.expand(path))
  return uv.fs_realpath(path) or path
end

-- Is `a` equal to or a parent directory of `b`?
local function contains(a, b)
  return a == b or a == '/' or b:sub(1, #a + 1) == a .. '/'
end

local function rg_cmd(root, extra)
  local cmd = { M.config.rg, '--files', '--hidden', '--null' }
  for _, name in ipairs(M.config.exclude) do
    vim.list_extend(cmd, { '--glob', '!' .. name })
  end
  vim.list_extend(cmd, extra or {})
  cmd[#cmd + 1] = '.' -- run inside root: rg matches path globs relative to the search path
  return cmd
end

local function run(cmd, cb, cwd)
  local ok, err = pcall(vim.system, cmd, { text = true, cwd = cwd }, cb)
  if not ok then
    cb { code = -1, stdout = '', stderr = tostring(err) }
  end
end

--- Working directories of every tmux pane (empty when not inside tmux).
local function pane_dirs(cb)
  if not vim.env.TMUX then
    return cb({}, nil)
  end
  local cmd = vim.list_extend(vim.deepcopy(M.config.tmux), { 'list-panes', '-a', '-F', '#{pane_current_path}' })
  run(cmd, function(res)
    if res.code ~= 0 then
      return cb({}, ('tmux list-panes failed: %s'):format(vim.trim(res.stderr or '')))
    end
    cb(vim.split(res.stdout or '', '\n', { trimempty = true }), nil)
  end)
end

--- Decide which directories to scan and how.
--- @return {root:string, args:string[]}[] scans, string[] notes
function M.plan(dirs, home)
  home = realpath(home or vim.env.HOME)
  local notes, roots, seen = {}, {}, {}
  for _, dir in ipairs(dirs) do
    local root = realpath(dir)
    if not seen[root] then
      seen[root] = true
      if root ~= home and contains(root, home) then
        notes[#notes + 1] = ('skipped %s (parent of $HOME, too broad to scan)'):format(root)
      else
        roots[#roots + 1] = root
      end
    end
  end
  table.sort(roots, function(a, b) return #a < #b end)
  local scans = {}
  for _, root in ipairs(roots) do
    if root == home then
      scans[#scans + 1] = { root = root, args = { '--max-depth', '1' } }
      notes[#notes + 1] = ('%s scanned top-level only ($HOME)'):format(root)
    else
      -- Every pane dir gets its own scan, so a nested dir that the parent's ignore
      -- rules hide (e.g. a git worktree under an excluded .worktrees/) still shows up.
      -- The parent skips it via an anchored glob to avoid scanning it twice.
      local args = {}
      for _, other in ipairs(roots) do
        if other ~= root and other ~= home and contains(root, other) then
          local rel = other:sub(#root + 2):gsub('[%[%]%*%?{}!\\]', '\\%0')
          vim.list_extend(args, { '--glob', '!/' .. rel })
        end
      end
      scans[#scans + 1] = { root = root, args = args }
    end
  end
  local copilot = realpath(M.config.copilot_root)
  local stat = uv.fs_stat(copilot)
  if stat and stat.type == 'directory' then
    local args = {}
    for _, g in ipairs(M.config.copilot_globs) do
      vim.list_extend(args, { '--glob', g })
    end
    scans[#scans + 1] = { root = copilot, args = args }
  else
    notes[#notes + 1] = ('Copilot session root %s not found'):format(copilot)
  end
  return scans, notes
end

--- Asynchronously collect files, newest first.
--- cb(items, errors, notes) may run in a fast event context; use vim.schedule for API calls.
function M.collect(cb)
  local cwd = vim.fn.getcwd()
  pane_dirs(vim.schedule_wrap(function(dirs, tmux_err)
    local errors = { tmux_err }
    table.insert(dirs, cwd)
    local scans, notes = M.plan(dirs)
    local files, pending = {}, #scans

    local function stat_all()
      local list = vim.tbl_keys(files)
      local items, left = {}, #list
      if left == 0 then
        return cb(items, errors, notes)
      end
      for _, path in ipairs(list) do
        uv.fs_stat(path, function(err, st)
          if st then
            local t = (st.birthtime and st.birthtime.sec > 0) and st.birthtime or st.mtime
            items[#items + 1] = { file = path, text = path, time = t.sec, nsec = t.nsec }
          elseif err and not err:match '^ENOENT' then
            errors[#errors + 1] = err
          end
          left = left - 1
          if left == 0 then
            table.sort(items, function(a, b)
              if a.time ~= b.time then return a.time > b.time end
              if a.nsec ~= b.nsec then return a.nsec > b.nsec end
              return a.file < b.file
            end)
            cb(items, errors, notes)
          end
        end)
      end
    end

    if pending == 0 then
      return stat_all()
    end
    for _, scan in ipairs(scans) do
      run(rg_cmd(scan.root, scan.args), function(res)
        for _, path in ipairs(vim.split(res.stdout or '', '\0', { trimempty = true })) do
          files[scan.root .. '/' .. path:gsub('^%./', '')] = true
        end
        -- rg exits 1 when nothing matched; 2 = partial errors (stdout still usable)
        if res.code ~= 0 and res.code ~= 1 or (res.code == 1 and vim.trim(res.stderr or '') ~= '') then
          errors[#errors + 1] = ('rg in %s (exit %d): %s'):format(scan.root, res.code, vim.trim(res.stderr or ''))
        end
        pending = pending - 1
        if pending == 0 then
          stat_all()
        end
      end, scan.root)
    end
  end))
end

local function format(item, picker)
  local ret = { { os.date('%m-%d %H:%M ', item.time), 'SnacksPickerTime' } }
  return vim.list_extend(ret, require('snacks.picker.format').file(item, picker))
end

function M.pick()
  M.collect(function(items, errors, notes)
    vim.schedule(function()
      errors = vim.tbl_filter(function(e) return e ~= nil end, errors)
      if #errors > 0 then
        vim.notify('Recent files:\n' .. table.concat(errors, '\n'), #items > 0 and vim.log.levels.WARN or vim.log.levels.ERROR)
      end
      if #notes > 0 then
        vim.notify('Recent files:\n' .. table.concat(notes, '\n'), vim.log.levels.INFO)
      end
      if #items == 0 then
        if #errors == 0 then
          vim.notify('Recent files: no files found', vim.log.levels.WARN)
        end
        return
      end
      Snacks.picker.pick {
        title = 'Recent files (tmux panes + Copilot)',
        items = items,
        format = format,
        sort = { fields = { 'score:desc', 'idx' } },
      }
    end)
  end)
end

return M
