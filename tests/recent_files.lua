-- Focused checks for util.recent_files with fake tmux output and temp fixtures.
-- Run: nvim --headless -u NONE -l nvim/tests/recent_files.lua  (from the config repo)
local here = vim.fs.dirname(vim.fs.normalize(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p')))
local config = vim.fs.dirname(here)
package.path = config .. '/lua/?.lua;' .. package.path
local rf = require 'util.recent_files'
local snacks = vim.fn.stdpath 'data' .. '/lazy/snacks.nvim' -- before $HOME is faked below
local spec = dofile(config .. '/lua/custom/plugins/snacks.lua')

local fx = here .. '/.fixture'
vim.fn.delete(fx, 'rf')
local function write(path, text)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile({ text or 'x' }, path)
end
local function sh(cmd)
  local res = vim.system(cmd):wait()
  assert(res.code == 0, table.concat(cmd, ' ') .. ': ' .. (res.stderr or ''))
end

local A, B, C = fx .. '/proj a', fx .. '/proj b', fx .. '/copilot'
local home = fx .. '/home'
sh { 'git', 'init', '-q', A }
write(A .. '/.gitignore', 'ignored.log')
write(A .. '/ignored.log')
write(A .. '/node_modules/dep.js')
write(A .. '/.cache/blob')
write(A .. '/sub/nested.lua')
write(home .. '/deep/inner.txt')
write(home .. '/top.txt')
write(C .. '/sess1/events.jsonl')
write(B .. '/old.txt')
vim.wait(1100)
write(A .. '/new note.md') -- untracked, never opened, path with space
write(A .. '/.hidden.md')
vim.wait(1100)
write(C .. '/sess1/files/artifact.md')
write(C .. '/sess1/plan.md')
vim.wait(1100)
vim.fn.writefile({ 'modified later' }, B .. '/old.txt', 'a') -- newer mtime, old birthtime

-- Fake tmux: current pane in A, A/sub in another window, B in a second session, $HOME and its parents
local fake = fx .. '/tmux'
local panes = fx .. '/panes.txt'
vim.fn.writefile({ A, A .. '/sub', B, home, fx, '/' }, panes)
vim.fn.writefile({ '#!/bin/sh', '[ -f "' .. fx .. '/fail" ] && { echo "no server running" >&2; exit 1; }', 'case "$*" in *"list-panes -a"*) cat "' .. panes .. '";; *) exit 2;; esac' }, fake)
sh { 'chmod', '+x', fake }

rf.config.tmux = { fake }
rf.config.copilot_root = C
vim.env.TMUX = 'fake'
vim.env.HOME = home
vim.cmd.cd(vim.fn.fnameescape(B))

local function collect()
  local out
  rf.collect(function(items, errors, notes) out = { items = items, errors = errors, notes = notes } end)
  assert(vim.wait(10000, function() return out ~= nil end), 'collect timed out')
  local index = {}
  for i, item in ipairs(out.items) do
    index[item.file] = i
  end
  out.index = index
  return out
end
local real = function(p) return vim.uv.fs_realpath(p) end

local ok, err = xpcall(function()
  local r = collect()
  assert(#vim.tbl_keys(r.errors) == 0, vim.inspect(r.errors))
  local ix = r.index
  for _, f in ipairs { '/new note.md', '/.hidden.md', '/sub/nested.lua', '/.gitignore' } do
    assert(ix[real(A) .. f], 'missing ' .. f)
  end
  for _, f in ipairs { '/ignored.log', '/node_modules/dep.js', '/.cache/blob' } do
    assert(not ix[real(A) .. f], 'should exclude ' .. f)
  end
  assert(ix[real(B) .. '/old.txt'], 'second tmux session dir must be scanned')
  assert(ix[real(C) .. '/sess1/files/artifact.md'] and ix[real(C) .. '/sess1/plan.md'], 'copilot artifacts')
  assert(not ix[real(C) .. '/sess1/events.jsonl'], 'copilot metadata excluded')
  assert(ix[real(home) .. '/top.txt'] and not ix[real(home) .. '/deep/inner.txt'], '$HOME top-level only')
  assert(not ix[real(A) .. '/.git/HEAD'], '.git excluded')
  local skipped = table.concat(r.notes, '\n')
  assert(skipped:find('skipped ' .. real(fx), 1, true) and skipped:find('skipped /', 1, true), skipped)
  assert(#r.items == vim.tbl_count(ix), 'items must be deduplicated')
  local scans = rf.plan({ A, A .. '/sub', B, B }, home)
  assert(#scans == 3, 'nested/duplicate roots must collapse (A, B, copilot)')
  for i = 2, #r.items do
    assert(r.items[i - 1].time >= r.items[i].time, 'newest first')
  end
  assert(ix[real(C) .. '/sess1/files/artifact.md'] < ix[real(A) .. '/new note.md'], 'newer artifact first')
  if ((vim.uv.fs_stat(B .. '/old.txt').birthtime or {}).sec or 0) > 0 then
    assert(ix[real(A) .. '/new note.md'] < ix[real(B) .. '/old.txt'], 'birthtime must win over later mtime')
  end

  -- tmux failure is surfaced; Neovim cwd is still scanned
  write(fx .. '/fail')
  r = collect()
  assert(table.concat(r.errors, '\n'):find('no server running', 1, true), 'tmux error surfaced')
  assert(r.index[real(B) .. '/old.txt'] and not r.index[real(A) .. '/new note.md'], 'cwd fallback')
  vim.fn.delete(fx .. '/fail')

  -- missing rg is an error, and pick() reports it instead of opening an empty picker
  rf.config.rg = 'rg-does-not-exist'
  r = collect()
  assert(#r.items == 0 and table.concat(r.errors, '\n'):find('rg', 1, true), 'rg error surfaced')
  local notified = {}
  local orig_notify = vim.notify
  vim.notify = function(msg, level) notified[#notified + 1] = { msg, level } end
  _G.Snacks = { picker = { pick = function() error 'picker must not open' end } }
  rf.pick()
  assert(vim.wait(5000, function()
    for _, n in ipairs(notified) do
      if n[2] == vim.log.levels.ERROR then return true end
    end
  end), 'pick must notify error')
  vim.notify = orig_notify
  rf.config.rg = 'rg'

  -- mapping wired: <leader>so opens this picker; copy keys are global picker keys
  local mapped
  for _, k in ipairs(spec.keys) do
    if k[1] == '<leader>so' then mapped = k[2] end
  end
  local orig_pick, called = rf.pick, false
  rf.pick = function() called = true end
  assert(type(mapped) == 'function', '<leader>so mapping missing')
  mapped()
  assert(called, '<leader>so must call util.recent_files.pick')
  rf.pick = orig_pick
  local ikeys = spec.opts.picker.win.input.keys
  assert(ikeys['<a-y>'][1] == 'copy_path_relative' and ikeys['<a-Y>'][1] == 'copy_path_absolute')
  assert(spec.opts.picker.win.list.keys['<a-y>'] and spec.opts.picker.actions.copy_path_absolute)

  -- real Snacks picker (configured with the picker opts from snacks.lua)
  if vim.uv.fs_stat(snacks) then
    local clip = {}
    vim.g.clipboard = {
      name = 'test',
      copy = { ['+'] = function(lines) clip['+'] = table.concat(lines, '\n') end, ['*'] = function() end },
      paste = { ['+'] = function() return {} end, ['*'] = function() return {} end },
    }
    vim.opt.rtp:prepend(snacks)
    _G.Snacks = nil
    require('snacks').setup { picker = spec.opts.picker }
    local msgs = {}
    vim.notify = function(msg) msgs[#msgs + 1] = msg end
    local function open(fn)
      fn()
      local picker
      assert(vim.wait(10000, function()
        picker = Snacks.picker.get()[1]
        return picker and picker:count() > 0 and picker:current() ~= nil
      end), 'picker did not open')
      return picker
    end
    local picker = open(rf.pick)
    local first = picker:current()
    assert(first.file == real(C) .. '/sess1/plan.md' or first.file == real(C) .. '/sess1/files/artifact.md', first.file)
    picker:action 'copy_path_relative'
    local rel = '../copilot/sess1/' .. first.file:match 'sess1/(.*)$'
    assert(clip['+'] == rel and vim.fn.getreg '"' == rel, ('relative: %s / %s'):format(clip['+'], vim.fn.getreg '"'))
    assert(msgs[#msgs]:find(rel, 1, true), 'copied path must be notified')
    picker:action 'copy_path_absolute'
    assert(clip['+'] == first.file and vim.fn.getreg '"' == first.file, 'absolute copy')
    assert(not picker.closed and Snacks.picker.get()[1] == picker, 'picker must stay open after copy')
    picker:action 'confirm'
    assert(vim.wait(5000, function() return vim.api.nvim_buf_get_name(0) == first.file end), 'confirm must open file')

    -- standard files picker (item.file relative to item.cwd) with a path containing a space
    picker = open(function() Snacks.picker.files { cwd = A, pattern = 'new note' } end)
    assert(vim.wait(5000, function()
      local it = picker:current()
      return it and it.file:find('new note', 1, true)
    end), 'files picker must find "new note.md"')
    picker:action 'copy_path_absolute'
    assert(clip['+'] == real(A) .. '/new note.md', 'files picker absolute: ' .. tostring(clip['+']))
    picker:action 'copy_path_relative'
    assert(clip['+'] == '../proj a/new note.md', 'files picker relative: ' .. tostring(clip['+']))
    picker:close()
  else
    print('snacks.nvim not installed; skipped live picker check')
  end
end, debug.traceback)

vim.fn.delete(fx, 'rf')
if not ok then
  error(err)
end
print 'recent_files: all focused checks passed'
