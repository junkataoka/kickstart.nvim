-- Task management for ~/notes-md worknotes.
--
-- Task line format (Obsidian Tasks compatible, metadata kept at the end):
--   - [ ] text #tag 📅 2026-11-20 ➕ 2026-11-05 ✅ 2026-11-21 [[worknotes/2026/11/05|from 2026-11-05]]
--     📅 due   ➕ created (auto-stamped on save)   ✅ done (auto-stamped on save)
--
-- States: [ ] todo  [!] important  [~] in progress  [-] pending  [?] unclear
--         [>] on hold  [x] done  [_] cancelled
local M = {}

M.root = vim.env.NOTES_MD_ROOT or vim.fn.expand '~/notes-md'
M.agenda_dirs = { 'projects', 'meetings', 'people' }
M.stale_days = 14
M.load_template = nil -- set via setup(); fn(path) -> string|nil

local ICON = { due = '📅', created = '➕', done = '✅' }
local META_ORDER = { 'due', 'created', 'done' }
local DATE = '%d%d%d%d%-%d%d%-%d%d'
local LINK = '%[%[worknotes/[^%]|]-|from ' .. DATE .. '%]%]'
local OPEN = { [' '] = true, ['!'] = true, ['~'] = true, ['-'] = true, ['?'] = true, ['>'] = true }
local CLOSED_HL = 'Comment'

---------------------------------------------------------------------------
-- Dates
---------------------------------------------------------------------------
local function noon(y, m, d)
  return os.time { year = y, month = m, day = d, hour = 12 }
end

local function to_time(s)
  local y, m, d = s:match '(%d+)%-(%d+)%-(%d+)'
  return noon(tonumber(y), tonumber(m), tonumber(d))
end

function M.today()
  return os.date '%Y-%m-%d'
end

function M.add_days(date, n)
  return os.date('%Y-%m-%d', to_time(date) + n * 86400 + 3600)
end

-- Whole days from a to b (b - a).
function M.days_between(a, b)
  return math.floor((to_time(b) - to_time(a)) / 86400 + 0.5)
end

local WDAYS = { sun = 1, mon = 2, tue = 3, wed = 4, thu = 5, fri = 6, sat = 7 }

-- Parse user date input into YYYY-MM-DD. Accepts: YYYY-MM-DD, MM-DD, M/D,
-- today/tod, tomorrow/tom, +N / +Nd / +Nw / +Nm, weekday (mon..sun, next
-- occurrence), eow (Friday), nw (next Monday), eom (last day of month).
function M.parse_date(input)
  input = vim.trim((input or ''):lower())
  local now = os.date '*t'
  local today = M.today()

  if input == 'today' or input == 'tod' then
    return today
  elseif input == 'tomorrow' or input == 'tom' then
    return M.add_days(today, 1)
  elseif input == 'eom' then
    return os.date('%Y-%m-%d', noon(now.year, now.month + 1, 0))
  elseif input == 'nw' or input == 'next week' then
    local diff = (WDAYS.mon - now.wday) % 7
    return M.add_days(today, diff == 0 and 7 or diff)
  elseif input == 'eow' then
    return M.add_days(today, (WDAYS.fri - now.wday) % 7)
  end

  local n, unit = input:match '^%+?(%d%d?%d?)([dwm]?)$'
  if n then
    n = tonumber(n)
    if unit == 'w' then
      return M.add_days(today, n * 7)
    elseif unit == 'm' then
      return os.date('%Y-%m-%d', noon(now.year, now.month + n, now.day))
    end
    return M.add_days(today, n)
  end

  local wd = input:match '^%a+$' and WDAYS[input:sub(1, 3)]
  if wd then
    local diff = (wd - now.wday) % 7
    return M.add_days(today, diff == 0 and 7 or diff)
  end

  local y, m, d = input:match '^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$'
  if not y then
    m, d = input:match '^(%d%d?)[%-/](%d%d?)$'
    if m then
      y = now.year
      if noon(y, tonumber(m), tonumber(d)) < to_time(today) then
        y = y + 1
      end
    end
  end
  if y then
    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    local out = os.date('%Y-%m-%d', noon(y, m, d))
    if out == string.format('%04d-%02d-%02d', y, m, d) then
      return out
    end
  end
  return nil
end

---------------------------------------------------------------------------
-- Task line parse / format
---------------------------------------------------------------------------
function M.parse(line)
  local indent, state, rest = (line or ''):match '^(%s*)[%-%*%+] %[(.)%](.*)$'
  if not indent or (rest ~= '' and not rest:match '^%s') then
    return nil
  end
  local t = { indent = indent, state = state, meta = {} }
  t.link = rest:match(LINK)
  if t.link then
    rest = rest:gsub(vim.pesc(t.link), '')
  end
  for key, icon in pairs(ICON) do
    local d = rest:match(icon .. '%s*(' .. DATE .. ')')
    if d then
      t.meta[key] = d
      rest = rest:gsub('%s*' .. icon .. '%s*' .. DATE, '')
    end
  end
  t.text = vim.trim(rest)
  return t
end

function M.format(t)
  local parts = { t.indent .. '- [' .. t.state .. ']' }
  if t.text ~= '' then
    table.insert(parts, t.text)
  end
  for _, key in ipairs(META_ORDER) do
    if t.meta[key] then
      table.insert(parts, ICON[key] .. ' ' .. t.meta[key])
    end
  end
  if t.link then
    table.insert(parts, t.link)
  end
  return table.concat(parts, ' ')
end

function M.is_open(t)
  return t and t.text ~= '' and OPEN[t.state] == true
end

-- Apply a state change, keeping ✅ in sync.
function M.set_state(t, state)
  t.state = state
  if state == 'x' or state == 'X' then
    t.meta.done = t.meta.done or M.today()
  else
    t.meta.done = nil
  end
  return t
end

-- Quick-capture syntax: "!text #tag @fri" → important task due Friday.
function M.parse_capture(input)
  local text = vim.trim(input or '')
  local t = { indent = '', state = ' ', meta = { created = M.today() } }
  if text:sub(1, 1) == '!' then
    t.state = '!'
    text = vim.trim(text:sub(2))
  end
  local token
  text = text:gsub('%s*@(%S+)', function(tok)
    token = tok
    return ''
  end)
  if token then
    t.meta.due = M.parse_date(token)
    if not t.meta.due then
      return nil, 'Unrecognized date: @' .. token
    end
  end
  t.text = vim.trim(text)
  if t.text == '' then
    return nil, 'Empty task'
  end
  return t
end

---------------------------------------------------------------------------
-- Worknote files
---------------------------------------------------------------------------
function M.worknote_path(date)
  local y, m, d = date:match '(%d+)%-(%d+)%-(%d+)'
  return string.format('%s/worknotes/%s/%s/%s.md', M.root, y, m, d)
end

function M.worknote_date(path)
  local y, m, d = (path or ''):match '/worknotes/(%d%d%d%d)/(%d%d)/(%d%d)%.md$'
  return y and (y .. '-' .. m .. '-' .. d) or nil
end

local function link_for(date)
  local y, m, d = date:match '(%d+)%-(%d+)%-(%d+)'
  return string.format('[[worknotes/%s/%s/%s|from %s]]', y, m, d, date)
end

-- Most recent worknote on or before `date` - offset days (60-day lookback).
function M.find_worknote(offset, date)
  date = date or M.today()
  for i = offset or 0, 60 do
    local d = M.add_days(date, -i)
    local p = M.worknote_path(d)
    if vim.fn.filereadable(p) == 1 then
      return p, d
    end
  end
end

local function file_lines(path)
  local buf = vim.fn.bufnr(path)
  if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then
    return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  end
  if vim.fn.filereadable(path) == 0 then
    return {}
  end
  return vim.fn.readfile(path)
end

-- Edit a file through a (possibly hidden) buffer; save unless the user
-- already had unsaved changes there.
local function with_file(path, fn)
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  local was_modified = vim.bo[buf].modified
  local result = fn(buf)
  if not was_modified and vim.bo[buf].modified then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd 'silent noautocmd write'
    end)
    M.decorate(buf)
  end
  return result
end

-- Range [s, e) of lines under a "## <name>" heading (1-based, exclusive end).
local function section(lines, name)
  for i, l in ipairs(lines) do
    if l:match('^## ' .. name) then
      for j = i + 1, #lines do
        if lines[j]:match '^## ' then
          return i, j
        end
      end
      return i, #lines + 1
    end
  end
end

---------------------------------------------------------------------------
-- Carry over
---------------------------------------------------------------------------
local function urgency_sort(a, b)
  local da, db = a.meta.due or '9999', b.meta.due or '9999'
  if da ~= db then
    return da < db
  end
  local ia, ib = a.state == '!' and 0 or 1, b.state == '!' and 0 or 1
  if ia ~= ib then
    return ia < ib
  end
  return (a.meta.created or '') < (b.meta.created or '')
end

-- Open tasks from a worknote's Todo + Carried Over sections. Keeps the
-- original origin link and created date so task age survives carrying.
function M.carry_candidates(path, src_date)
  local tasks, seen = {}, {}
  local lines = file_lines(path)
  for _, name in ipairs { 'Todo', 'Carried Over' } do
    local s, e = section(lines, name)
    for i = (s or 0) + 1, (e or 0) - 1 do
      local t = M.parse(lines[i])
      if M.is_open(t) and not seen[t.text] then
        seen[t.text] = true
        t.indent = ''
        t.meta.created = t.meta.created or (t.link and t.link:match(DATE)) or src_date
        t.link = t.link or link_for(src_date)
        table.insert(tasks, t)
      end
    end
  end
  table.sort(tasks, urgency_sort)
  return tasks
end

-- Insert tasks into the "Carried Over" section of buf, replacing blank
-- placeholders and skipping tasks already present. Returns count inserted.
function M.insert_carried(buf, tasks)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local present = {}
  for _, l in ipairs(lines) do
    local t = M.parse(l)
    if t and t.text ~= '' then
      present[t.text] = true
    end
  end
  local out = {}
  for _, t in ipairs(tasks) do
    if not present[t.text] then
      table.insert(out, M.format(t))
    end
  end

  local s, e = section(lines, 'Carried Over')
  if not s then
    if #out > 0 then
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, vim.list_extend({ '', '## Carried Over', '' }, out))
    end
    return #out
  end
  -- Drop blank "- [ ]" placeholders inside the section
  for i = e - 1, s + 1, -1 do
    local t = M.parse(lines[i])
    if t and t.text == '' then
      vim.api.nvim_buf_set_lines(buf, i - 1, i, false, {})
      e = e - 1
    end
  end
  if #out == 0 then
    return 0
  end
  lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local at = s + 1 -- 1-based line to insert before
  for i = s + 1, e - 1 do
    if lines[i]:match '^%s*Tasks from previous' then
      at = i + 1
      if lines[at] == '' then
        at = at + 1
      end
      break
    end
  end
  -- Append after any tasks already in the section
  while at < e and M.parse(lines[at]) do
    at = at + 1
  end
  vim.api.nvim_buf_set_lines(buf, at - 1, at - 1, false, out)
  return #out
end

function M.carry_into(buf, notify)
  local today = M.worknote_date(vim.api.nvim_buf_get_name(buf)) or M.today()
  local prev, prev_date = M.find_worknote(1, today)
  if not prev then
    if notify then
      vim.notify('No previous worknote found (looked back 60 days)', vim.log.levels.WARN)
    end
    return 0
  end
  local tasks = M.carry_candidates(prev, prev_date)
  local n = M.insert_carried(buf, tasks)
  if notify or n > 0 then
    local stale = 0
    for _, t in ipairs(tasks) do
      if M.days_between(t.meta.created, today) >= M.stale_days then
        stale = stale + 1
      end
    end
    local msg = ('Carried %d task(s) from %s'):format(n, prev_date)
    if stale > 0 then
      msg = msg .. ('\n%d task(s) older than %d days — finish, cancel (<leader>tc) or reschedule?'):format(stale, M.stale_days)
    end
    vim.notify(msg, stale > 0 and vim.log.levels.WARN or vim.log.levels.INFO)
  end
  return n
end

-- Ensure today's worknote exists (template + carry) and return its buffer.
function M.today_buf()
  local path = M.worknote_path(M.today())
  local is_new = vim.fn.filereadable(path) == 0
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)
  if is_new and vim.api.nvim_buf_line_count(buf) <= 1 then
    vim.fn.mkdir(vim.fs.dirname(path), 'p')
    local content = M.load_template and M.load_template(M.root .. '/templates/worknote.md')
    if not content then
      vim.notify('Worknote template not found', vim.log.levels.ERROR)
      return nil
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, '\n'))
    M.carry_into(buf)
    vim.api.nvim_buf_call(buf, function()
      vim.cmd 'silent write'
    end)
  end
  return buf, is_new
end

---------------------------------------------------------------------------
-- Capture
---------------------------------------------------------------------------
function M.add(input)
  local t, err = M.parse_capture(input)
  if not t then
    if err ~= 'Empty task' then
      vim.notify(err, vim.log.levels.ERROR)
    end
    return false
  end
  local buf = M.today_buf()
  if not buf then
    return false
  end
  with_file(vim.api.nvim_buf_get_name(buf), function(b)
    local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
    local line = M.format(t)
    local s, e = section(lines, 'Todo')
    if not s then
      vim.api.nvim_buf_set_lines(b, -1, -1, false, { '', '## Todo', '', line })
      return
    end
    local last
    for i = s + 1, e - 1 do
      local p = M.parse(lines[i])
      if p and p.text == '' then
        vim.api.nvim_buf_set_lines(b, i - 1, i, false, { line })
        return
      elseif p then
        last = i
      end
    end
    local at = last or (lines[s + 1] == '' and s + 1 or s)
    vim.api.nvim_buf_set_lines(b, at, at, false, { line })
  end)
  local due = t.meta.due and ('  📅 ' .. t.meta.due) or ''
  vim.notify('Task added: ' .. t.text .. due, vim.log.levels.INFO)
  return true
end

function M.capture(on_done)
  vim.ui.input({ prompt = 'New task  (!important  #tag  @fri @+3d @11-20): ' }, function(input)
    if input and M.add(input) and on_done then
      on_done()
    end
  end)
end

---------------------------------------------------------------------------
-- Current-line editing
---------------------------------------------------------------------------
local function edit_cursor_task(fn)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  local t = M.parse(line)
  if not t then
    vim.notify('Not a task line', vim.log.levels.WARN)
    return
  end
  if fn(t) ~= false then
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { M.format(t) })
  end
end

function M.cursor_set_state(state)
  edit_cursor_task(function(t)
    M.set_state(t, state)
  end)
end

function M.cursor_set_due(arg)
  local function apply(input)
    if input == nil then
      return
    end
    edit_cursor_task(function(t)
      input = vim.trim(input)
      if input == '' or input == '-' then
        t.meta.due = nil
        return
      end
      local d = M.parse_date(input)
      if not d then
        vim.notify('Unrecognized date: ' .. input, vim.log.levels.ERROR)
        return false
      end
      t.meta.due = d
    end)
  end
  if arg and arg ~= '' then
    return apply(arg)
  end
  local t = M.parse(vim.api.nvim_get_current_line())
  if not t then
    vim.notify('Not a task line', vim.log.levels.WARN)
    return
  end
  vim.ui.input({
    prompt = 'Due (fri, +3d, 11-20, eow, nw; empty=clear): ',
    default = t.meta.due or '',
  }, apply)
end

---------------------------------------------------------------------------
-- Save-time stamping: ✅ on done, ➕ on new worknote tasks
---------------------------------------------------------------------------
function M.stamp(buf)
  local note_date = M.worknote_date(vim.api.nvim_buf_get_name(buf))
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, l in ipairs(lines) do
    local t = M.parse(l)
    if t and t.text ~= '' then
      local dirty = false
      local done = t.state == 'x' or t.state == 'X'
      if done and not t.meta.done then
        t.meta.done, dirty = M.today(), true
      elseif not done and t.meta.done then
        t.meta.done, dirty = nil, true
      end
      if note_date and not t.meta.created then
        t.meta.created = (t.link and t.link:match(DATE)) or note_date
        dirty = true
      end
      if dirty then
        vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { M.format(t) })
      end
    end
  end
end

---------------------------------------------------------------------------
-- Decorations: due-date colours + age hint
---------------------------------------------------------------------------
local ns = vim.api.nvim_create_namespace 'md_tasks'

local function due_hl(due, today)
  if due < today then
    return 'DiagnosticError'
  elseif due == today then
    return 'DiagnosticWarn'
  end
  return 'DiagnosticHint'
end

function M.decorate(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local today = M.today()
  for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local t = M.parse(l)
    if t and t.text ~= '' then
      local open = M.is_open(t)
      for key, icon in pairs(ICON) do
        local s, e = l:find(icon .. '%s*' .. DATE)
        if s then
          local hl = (key == 'due' and open) and due_hl(t.meta.due, today) or CLOSED_HL
          vim.api.nvim_buf_set_extmark(buf, ns, i - 1, s - 1, { end_col = e, hl_group = hl })
        end
      end
      local s, e = l:find(LINK)
      if s then
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, s - 1, { end_col = e, hl_group = CLOSED_HL })
      end
      if open and t.meta.created then
        local age = M.days_between(t.meta.created, today)
        if age >= 3 then
          vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
            virt_text = { { ('  %dd old'):format(age), age >= M.stale_days and 'DiagnosticWarn' or CLOSED_HL } },
            virt_text_pos = 'eol',
          })
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- Agenda
---------------------------------------------------------------------------
-- Open tasks from the latest worknote plus curated dirs (projects, ...).
function M.collect()
  local sources = {}
  local latest = M.find_worknote(0)
  if latest then
    table.insert(sources, latest)
  end
  for _, dir in ipairs(M.agenda_dirs) do
    vim.list_extend(sources, vim.fn.globpath(M.root .. '/' .. dir, '**/*.md', false, true))
  end
  local items = {}
  for _, path in ipairs(sources) do
    for lnum, l in ipairs(file_lines(path)) do
      local t = M.parse(l)
      if M.is_open(t) then
        table.insert(items, { path = path, lnum = lnum, task = t })
      end
    end
  end
  return items
end

local function bucket(t, today)
  local due = t.meta.due
  if due then
    local d = M.days_between(today, due)
    if d < 0 then
      return 1
    elseif d == 0 then
      return 2
    elseif d <= 7 then
      return 3
    end
    return 4
  end
  if t.state == '!' or t.state == '~' then
    return 5
  end
  return 6
end

local BUCKETS = {
  { '⚠ Overdue', 'DiagnosticError' },
  { '★ Today', 'DiagnosticWarn' },
  { '◷ Next 7 days', 'DiagnosticHint' },
  { '◌ Later', 'Title' },
  { '! Important / in progress (no date)', 'Title' },
  { '· Someday (no date)', 'Comment' },
}
local STATE_ICON = { [' '] = '○', ['!'] = '!', ['~'] = '◐', ['-'] = '…', ['?'] = '?', ['>'] = '⏸' }

function M.summary()
  local today, over, due_today = M.today(), 0, 0
  for _, it in ipairs(M.collect()) do
    local b = bucket(it.task, today)
    over = over + (b == 1 and 1 or 0)
    due_today = due_today + (b == 2 and 1 or 0)
  end
  return over, due_today
end

local agenda = { buf = nil, win = nil, rows = {} }

local function short_source(path)
  local d = M.worknote_date(path)
  if d then
    return d == M.today() and 'today' or d:sub(6)
  end
  return (path:gsub('^' .. vim.pesc(M.root) .. '/', ''):gsub('%.md$', ''))
end

local function render()
  local buf = agenda.buf
  local today = M.today()
  local groups = {}
  for _, it in ipairs(M.collect()) do
    local b = bucket(it.task, today)
    groups[b] = groups[b] or {}
    table.insert(groups[b], it)
  end

  local lines, hls, rows = {}, {}, {}
  local function add(text, hl, item)
    table.insert(lines, text)
    if hl then
      table.insert(hls, { #lines - 1, hl })
    end
    rows[#lines] = item
  end
  add((' Tasks — %s'):format(os.date '%a %Y-%m-%d'), 'Title')
  add(' a add · x done · c cancel · ! important · d due · > +1 day · w wip · <CR> open · r refresh · q close', 'Comment')

  local total = 0
  for b, def in ipairs(BUCKETS) do
    local items = groups[b]
    if items then
      table.sort(items, function(x, y)
        return urgency_sort(x.task, y.task)
      end)
      add('')
      add((' %s (%d)'):format(def[1], #items), def[2])
      for _, it in ipairs(items) do
        local t = it.task
        local meta = {}
        if t.meta.due then
          local d = M.days_between(today, t.meta.due)
          table.insert(meta, ('📅 %s (%s)'):format(t.meta.due:sub(6), d == 0 and 'today' or (d > 0 and '+' or '') .. d .. 'd'))
        end
        if t.meta.created then
          local age = M.days_between(t.meta.created, today)
          if age > 0 then
            table.insert(meta, age .. 'd old')
          end
        end
        table.insert(meta, short_source(it.path))
        local prefix = ('   %s %s'):format(STATE_ICON[t.state] or t.state, t.text)
        it.meta_col = #prefix
        add(prefix .. '   ' .. table.concat(meta, ' · '), nil, it)
        total = total + 1
      end
    end
  end
  if total == 0 then
    add('')
    add('   Nothing open. 🎉  Press a to add a task.', 'Comment')
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_set_extmark(buf, ns, h[1], 0, { end_row = h[1] + 1, hl_group = h[2], hl_eol = false })
  end
  for row, it in pairs(rows) do
    if it then
      local l = lines[row]
      local s = it.meta_col + 1
      vim.api.nvim_buf_set_extmark(buf, ns, row - 1, s - 1, { end_col = #l, hl_group = 'Comment' })
      if it.task.meta.due then
        local ds, de = l:find('📅 [^·]*', s)
        if ds then
          vim.api.nvim_buf_set_extmark(buf, ns, row - 1, ds - 1, { end_col = de, hl_group = due_hl(it.task.meta.due, today) })
        end
      end
    end
  end
  agenda.rows = rows
end

-- Update the source line of an agenda item, re-locating it by text if the
-- file changed since the agenda was rendered.
local function update_item(item, fn)
  with_file(item.path, function(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local lnum = item.lnum
    local t = M.parse(lines[lnum])
    if not t or t.text ~= item.task.text then
      lnum, t = nil, nil
      for i, l in ipairs(lines) do
        local p = M.parse(l)
        if p and p.text == item.task.text then
          lnum, t = i, p
          break
        end
      end
    end
    if not t then
      vim.notify('Task not found in ' .. item.path, vim.log.levels.WARN)
      return
    end
    fn(t)
    vim.api.nvim_buf_set_lines(buf, lnum - 1, lnum, false, { M.format(t) })
  end)
end

local function current_item()
  return agenda.rows[vim.api.nvim_win_get_cursor(0)[1]]
end

local function act(fn)
  return function()
    local it = current_item()
    if not it then
      return
    end
    update_item(it, fn)
    render()
  end
end

function M.agenda()
  if agenda.win and vim.api.nvim_win_is_valid(agenda.win) then
    vim.api.nvim_set_current_win(agenda.win)
    render()
    return
  end
  agenda.buf = vim.api.nvim_create_buf(false, true)
  local buf = agenda.buf
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'mdtasks'
  local width = math.min(110, math.floor(vim.o.columns * 0.85))
  local height = math.min(35, math.floor(vim.o.lines * 0.75))
  agenda.win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' Agenda ',
    title_pos = 'center',
  })
  vim.wo[agenda.win].cursorline = true
  vim.wo[agenda.win].wrap = false
  render()

  local function map(lhs, fn, desc)
    vim.keymap.set('n', lhs, fn, { buffer = buf, nowait = true, desc = desc })
  end
  local function close()
    if vim.api.nvim_win_is_valid(agenda.win) then
      vim.api.nvim_win_close(agenda.win, true)
    end
  end
  map('q', close, 'Close')
  map('<Esc>', close, 'Close')
  map('r', render, 'Refresh')
  map('x', act(function(t) M.set_state(t, 'x') end), 'Done')
  map('c', act(function(t) M.set_state(t, '_') end), 'Cancel')
  map('w', act(function(t) M.set_state(t, t.state == '~' and ' ' or '~') end), 'Toggle in progress')
  map('!', act(function(t) M.set_state(t, t.state == '!' and ' ' or '!') end), 'Toggle important')
  map('>', act(function(t)
    local base = t.meta.due and t.meta.due > M.today() and t.meta.due or M.today()
    t.meta.due = M.add_days(base, 1)
  end), 'Postpone one day')
  map('d', function()
    local it = current_item()
    if not it then
      return
    end
    vim.ui.input({ prompt = 'Due (fri, +3d, 11-20; empty=clear): ', default = it.task.meta.due or '' }, function(input)
      if input == nil then
        return
      end
      local d = vim.trim(input) ~= '' and M.parse_date(input) or nil
      if vim.trim(input) ~= '' and not d then
        vim.notify('Unrecognized date: ' .. input, vim.log.levels.ERROR)
        return
      end
      update_item(it, function(t)
        t.meta.due = d
      end)
      render()
    end)
  end, 'Set due date')
  map('a', function()
    M.capture(render)
  end, 'Add task')
  map('<CR>', function()
    local it = current_item()
    if not it then
      return
    end
    close()
    vim.cmd.edit(vim.fn.fnameescape(it.path))
    pcall(vim.api.nvim_win_set_cursor, 0, { it.lnum, 0 })
    vim.cmd 'normal! zz'
  end, 'Open task source')
  -- Start on the first task row
  for row = 1, vim.api.nvim_buf_line_count(buf) do
    if agenda.rows[row] then
      vim.api.nvim_win_set_cursor(agenda.win, { row, 0 })
      break
    end
  end
end

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------
local real_root
local function in_vault(buf)
  real_root = real_root or (vim.uv.fs_realpath(M.root) or M.root) .. '/'
  local name = vim.api.nvim_buf_get_name(buf)
  if name:sub(1, #M.root + 1) == M.root .. '/' then
    return true
  end
  local real = vim.uv.fs_realpath(name)
  return real ~= nil and real:sub(1, #real_root) == real_root
end

function M.setup(opts)
  opts = opts or {}
  M.load_template = opts.load_template or M.load_template

  local cmd = vim.api.nvim_create_user_command
  cmd('MdTask', function(o)
    if o.args ~= '' then
      M.add(o.args)
    else
      M.capture()
    end
  end, { nargs = '*', desc = "Quick-add task to today's worknote (!important @due)" })
  cmd('MdAgenda', M.agenda, { desc = 'Task agenda (overdue / today / upcoming)' })
  cmd('MdDue', function(o)
    M.cursor_set_due(o.args)
  end, { nargs = '?', desc = 'Set/clear due date on task under cursor' })
  cmd('MdCarryTasks', function()
    M.carry_into(vim.api.nvim_get_current_buf(), true)
  end, { desc = 'Pull open tasks from previous worknote' })

  local group = vim.api.nvim_create_augroup('md_tasks', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = group,
    pattern = '*.md',
    callback = function(ev)
      if in_vault(ev.buf) then
        M.stamp(ev.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'InsertLeave', 'BufWritePost' }, {
    group = group,
    pattern = '*.md',
    callback = function(ev)
      if in_vault(ev.buf) then
        M.decorate(ev.buf)
      end
    end,
  })
  -- Daily nudge the first time today's worknote is opened in a session
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    pattern = '*/worknotes/*.md',
    callback = function(ev)
      if vim.g.md_tasks_nudged == M.today() or M.worknote_date(vim.api.nvim_buf_get_name(ev.buf)) ~= M.today() then
        return
      end
      vim.g.md_tasks_nudged = M.today()
      vim.schedule(function()
        local over, due_today = M.summary()
        if over + due_today > 0 then
          vim.notify(('📅 %d overdue, %d due today — <leader>nA for agenda'):format(over, due_today), over > 0 and vim.log.levels.WARN or vim.log.levels.INFO)
        end
      end)
    end,
  })
end

-- Buffer-local task keymaps for vault markdown buffers.
function M.buffer_keymaps(buf)
  local function map(lhs, fn, desc)
    vim.keymap.set('n', lhs, fn, { buffer = buf, desc = desc })
  end
  local states = {
    { 'd', 'x', '[T]ask [D]one' },
    { 'u', ' ', '[T]ask [U]ndone' },
    { 'p', '-', '[T]ask [P]ending' },
    { 'i', '!', '[T]ask [I]mportant' },
    { 'q', '?', '[T]ask Uncertain [?]' },
    { 'o', '>', '[T]ask [O]n Hold / Deferred' },
    { 'c', '_', '[T]ask [C]ancelled' },
    { 'w', '~', '[T]ask In-progress / [W]orking' },
  }
  for _, s in ipairs(states) do
    map('<leader>t' .. s[1], function()
      M.cursor_set_state(s[2])
    end, s[3])
  end
  map('<leader>tD', function()
    M.cursor_set_due()
  end, '[T]ask [D]ue date')
  map('<leader>t>', function()
    edit_cursor_task(function(t)
      local base = t.meta.due and t.meta.due > M.today() and t.meta.due or M.today()
      t.meta.due = M.add_days(base, 1)
    end)
  end, '[T]ask postpone one day')
end

return M
