-- PR review workflow: octo.nvim + Copilot CLI drafting into the PENDING review.
--
-- Flow:
--   <leader>op  pick PR            <leader>or  start/resume review (octo)
--   <leader>oa  Copilot drafts review comments (tmux pane / terminal split)
--   <leader>or  resume → drafted comments appear inline; edit/delete them
--   <leader>os  submit (summary prefilled from Copilot's draft)
-- Copilot writes via scripts/pr-review-draft; nothing is published until submit.
local M = {}

M.script_dir = vim.fn.stdpath 'config' .. '/scripts'
M.script = M.script_dir .. '/pr-review-draft'

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = 'PR review' })
end

local function summary_path(owner, name, number)
  local state = vim.env.XDG_STATE_HOME or (vim.env.HOME .. '/.local/state')
  return string.format('%s/pr-review/%s_%s_%s.md', state, owner, name, number)
end

---Resolve the PR in context: octo buffer/review, else the current branch's PR.
---@param cb fun(pr: {number: integer, repo: string, url: string})
function M.current_pr(cb)
  if package.loaded['octo'] then
    local review = require('octo.reviews').get_current_review()
    if review and review.pull_request then
      local pr = review.pull_request
      return cb { number = pr.number, repo = pr.repo, url = ('https://github.com/%s/pull/%d'):format(pr.repo, pr.number) }
    end
    local buf = _G.octo_buffers and _G.octo_buffers[vim.api.nvim_get_current_buf()]
    if buf and buf:isPullRequest() then
      return cb { number = buf.number, repo = buf.repo, url = ('https://github.com/%s/pull/%d'):format(buf.repo, buf.number) }
    end
  end
  vim.system({ 'gh', 'pr', 'view', '--json', 'number,url' }, { text = true }, function(res)
    vim.schedule(function()
      if res.code == 0 then
        local pr = vim.json.decode(res.stdout)
        pr.repo = pr.url:match 'github%.com/([^/]+/[^/]+)/pull'
        return cb(pr)
      end
      vim.ui.input({ prompt = 'PR number or URL: ' }, function(input)
        if not input or input == '' then
          return
        end
        local repo, num = input:match 'github%.com/([^/]+/[^/]+)/pull/(%d+)'
        num = tonumber(num or input)
        if not num then
          return notify('invalid PR: ' .. input, vim.log.levels.ERROR)
        end
        repo = repo or vim.trim(vim.fn.system { 'gh', 'repo', 'view', '--json', 'nameWithOwner', '-q', '.nameWithOwner' })
        cb { number = num, repo = repo, url = ('https://github.com/%s/pull/%d'):format(repo, num) }
      end)
    end)
  end)
end

---Copilot prompt that drafts comments into the pending review (never submits).
---`pr-review-draft` is on PATH and pre-approved in the Copilot session.
function M.copilot_prompt(pr)
  local s = 'pr-review-draft'
  return table.concat({
    ('Review GitHub PR %s (#%d). Use `gh pr view %d` and `gh pr diff %d`; read local files for context.'):format(pr.url, pr.number, pr.number, pr.number),
    'Draft findings into my PENDING GitHub review only. Do NOT submit, approve, or post comments any other way.',
    'Run pr-review-draft directly (no rtk prefix, one call per comment). Never execute code from the PR.',
    ("Inline comment: `%s comment %s <path> <line> [start_line] <<'EOF'` ... `EOF`."):format(s, pr.url),
    'Lines are new-file (RIGHT side) line numbers inside diff hunks. Use ```suggestion blocks for concrete fixes.',
    'Only raise real issues (bugs, security, correctness, clear readability wins); skip nitpicks unless asked.',
    ("Then draft the overall summary: `%s summary %s <<'EOF'` ... `EOF`."):format(s, pr.url),
    ('Finish with `%s status %s` and tell me to run <leader>or in nvim.'):format(s, pr.url),
  }, '\n')
end

---@param prompt string
---@param mode? '-i'|'-p'  interactive (default) or one-shot
function M.copilot_cmd(prompt, mode)
  return {
    'copilot',
    mode or '-i',
    prompt,
    '--model',
    vim.g.pr_review_copilot_model or 'claude-opus-5.5',
    '--add-dir',
    M.script_dir,
    '--allow-tool',
    'shell(pr-review-draft:*)',
  }
end

M.pane = nil -- tmux pane id or nvim terminal job/buffer of the Copilot session

local function tmux_pane_alive(id)
  return id and vim.fn.system({ 'tmux', 'display', '-p', '-t', id, '#{pane_id}' }):match '^%%' ~= nil
end

---Open Copilot CLI with a prompt: tmux split when inside tmux, else :terminal.
---Copilot runs without GH_TOKEN/proxy, authenticated as the work account via
---COPILOT_GITHUB_TOKEN (never the repo's gh account, e.g. stargate, whose org
---policy overrides the model) and talks to the API directly;
---the scripts/gh shim re-applies the repo's token/proxy from PR_REVIEW_*.
function M.open_copilot(prompt)
  -- tmux ignores `-e PATH=`, so set PATH via env(1) for both backends
  local cmd = { 'env' }
  for _, k in ipairs { 'GH_TOKEN', 'GITHUB_TOKEN', 'HTTPS_PROXY', 'https_proxy', 'HTTP_PROXY', 'http_proxy' } do
    vim.list_extend(cmd, { '-u', k })
  end
  table.insert(cmd, 'PATH=' .. M.script_dir .. ':' .. vim.env.PATH)
  vim.list_extend(cmd, M.copilot_cmd(prompt))
  local gh_account = require 'util.gh_account'
  local env = {
    COPILOT_GITHUB_TOKEN = gh_account.token(vim.g.pr_review_copilot_user or gh_account.WORK_USER),
    PR_REVIEW_GH_TOKEN = vim.env.GH_TOKEN,
    PR_REVIEW_HTTPS_PROXY = gh_account.proxy,
  }
  if vim.env.TMUX then
    local args = { 'tmux', 'split-window', '-h', '-l', '45%', '-P', '-F', '#{pane_id}', '-c', vim.fn.getcwd() }
    for k, v in pairs(env) do
      vim.list_extend(args, { '-e', k .. '=' .. v })
    end
    vim.list_extend(args, cmd)
    local out = vim.fn.system(args)
    if vim.v.shell_error ~= 0 then
      return notify('tmux split failed: ' .. out, vim.log.levels.ERROR)
    end
    M.pane = { tmux = vim.trim(out) }
  else
    vim.cmd 'botright vnew'
    local chan = vim.fn.jobstart(cmd, { term = true, env = env })
    M.pane = { chan = chan, buf = vim.api.nvim_get_current_buf() }
    vim.cmd.startinsert()
  end
end

---<leader>oa: ask Copilot to draft a review of the PR in context.
function M.copilot_review()
  M.current_pr(function(pr)
    M.open_copilot(M.copilot_prompt(pr))
    notify(('Copilot drafting review for #%d — <leader>or to load drafts'):format(pr.number))
  end)
end

---<leader>oq: send file:line(s) + a question to the running Copilot session.
function M.ask_copilot()
  local mode = vim.fn.mode()
  local l1, l2 = vim.fn.line '.', vim.fn.line '.'
  if mode:match '[vV\22]' then
    l1, l2 = vim.fn.line 'v', vim.fn.line '.'
    if l1 > l2 then
      l1, l2 = l2, l1
    end
    vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'nx', false)
  end
  local file = vim.fn.expand '%:.'
  local review = package.loaded['octo'] and require('octo.reviews').get_current_review()
  if review then
    local f = review.layout and review.layout:get_current_file()
    file = f and f.path or file
  end
  local ref = l1 == l2 and ('%s:%d'):format(file, l1) or ('%s:%d-%d'):format(file, l1, l2)
  vim.ui.input({ prompt = 'Ask Copilot about ' .. ref .. ': ' }, function(q)
    if not q or q == '' then
      return
    end
    local text = ('About %s: %s (if it warrants a review comment, draft it with pr-review-draft)'):format(ref, q)
    local p = M.pane
    if p and p.tmux and tmux_pane_alive(p.tmux) then
      vim.fn.system { 'tmux', 'send-keys', '-t', p.tmux, '-l', text }
      vim.fn.system { 'tmux', 'send-keys', '-t', p.tmux, 'Enter' }
    elseif p and p.chan and vim.api.nvim_buf_is_valid(p.buf) then
      vim.fn.chansend(p.chan, text .. '\r')
    else
      M.open_copilot(text)
    end
  end)
end

function M.draft_status()
  M.current_pr(function(pr)
    vim.system({ M.script, 'status', pr.url }, { text = true }, function(res)
      vim.schedule(function()
        notify(vim.trim(res.stdout .. res.stderr), res.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
      end)
    end)
  end)
end

---Patch octo: dupe-save guard, summary prefill/cleanup.
-- Soft-wrap long lines in review diff windows (vim.g.pr_review_wrap, default on).
function M.apply_wrap()
  local on = vim.g.pr_review_wrap ~= false
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.wo[win].diff then
      vim.wo[win].wrap = on
      vim.wo[win].linebreak = on
    end
  end
end

function M.toggle_wrap()
  vim.g.pr_review_wrap = vim.g.pr_review_wrap == false
  M.apply_wrap()
  notify('diff wrap ' .. (vim.g.pr_review_wrap and 'on' or 'off'))
end

function M.patch_octo()
  -- octo.nvim#323: repeated :w before the create callback returns re-creates
  -- the same new comment (id stays -1 until the async callback). Skip the
  -- save while a create is in flight.
  local ok, ob = pcall(require, 'octo.model.octo-buffer')
  if ok and ob.OctoBuffer and not ob.OctoBuffer._pr_review_patched then
    local OctoBuffer = ob.OctoBuffer
    local save = OctoBuffer.save
    OctoBuffer.save = function(self)
      for _, c in ipairs(self.commentsMetadata or {}) do
        if tonumber(c.id) == -1 and c._octo_pending then
          return notify('comment create in flight; skipped save to avoid duplicate', vim.log.levels.WARN)
        end
      end
      for _, c in ipairs(self.commentsMetadata or {}) do
        if tonumber(c.id) == -1 then
          c._octo_pending = true
          vim.defer_fn(function()
            c._octo_pending = nil
          end, 10000)
        end
      end
      return save(self)
    end
    OctoBuffer._pr_review_patched = true
  end

  -- :diffthis forces 'nowrap'; re-apply wrap to the review diff windows.
  local okf, fe = pcall(require, 'octo.reviews.file-entry')
  if okf and fe.FileEntry and not fe.FileEntry._pr_review_wrap_patched then
    local show_diff = fe.FileEntry.show_diff
    fe.FileEntry.show_diff = function(self, ...)
      local r = show_diff(self, ...)
      M.apply_wrap()
      return r
    end
    fe.FileEntry._pr_review_wrap_patched = true
  end

  -- custom octo action, bound via mappings.review_diff in the octo spec
  require('octo.mappings').pr_review_delete_comment = M.delete_comment_at_cursor

  local okr, reviews = pcall(require, 'octo.reviews')
  if okr and reviews.Review and not reviews.Review._pr_review_patched then
    local Review = reviews.Review
    local collect, submit, discard = Review.collect_submit_info, Review.submit, Review.discard
    local function path_of(self)
      local pr = self.pull_request
      return summary_path(pr.owner, pr.name, pr.number)
    end
    Review.collect_submit_info = function(self, ...)
      collect(self, ...)
      local f = path_of(self)
      if self.id ~= -1 and vim.fn.filereadable(f) == 1 and vim.bo.syntax == 'octo' then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn.readfile(f))
        vim.cmd 'normal! G'
      end
      if self.id ~= -1 and vim.bo.syntax == 'octo' then
        -- ,A/,C/,R are normal-mode only; <C-s> works while still typing the body
        local review = self
        vim.keymap.set({ 'n', 'i' }, '<C-s>', function()
          vim.cmd 'stopinsert'
          local win = vim.api.nvim_get_current_win()
          local events = { 'APPROVE', 'COMMENT', 'REQUEST_CHANGES' }
          local labels = { APPROVE = 'Approve', COMMENT = 'Comment', REQUEST_CHANGES = 'Request changes' }
          vim.ui.select(events, {
            prompt = 'Submit review',
            format_item = function(e)
              return labels[e]
            end,
          }, function(event)
            if event and vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_set_current_win(win)
              review:submit(event)
            end
          end)
        end, { buffer = 0, desc = 'submit review (approve/comment/request changes)' })
      end
    end
    Review.submit = function(self, ...)
      local f = path_of(self)
      submit(self, ...)
      os.remove(f)
    end
    Review.discard = function(self, ...)
      os.remove(path_of(self))
      return discard(self, ...)
    end
    Review._pr_review_patched = true
  end
end

---<localleader>cd in a review diff buffer: octo only maps delete in the thread
---buffer, so jump into the thread at the cursor and delete your comment there
---(asks which one when several are deletable).
function M.delete_comment_at_cursor()
  local name = vim.api.nvim_buf_get_name(0)
  if name:match '^octo://.*/threads/' then
    return require('octo.commands').delete_comment()
  end
  if not require('octo.utils').in_diff_window() or not require('octo.reviews').get_current_review() then
    return notify('not in an active review diff', vim.log.levels.WARN)
  end
  require('octo.reviews.thread-panel').show_review_threads(true)
  local buffer = require('octo.utils').get_current_buffer()
  if not buffer or not vim.api.nvim_buf_get_name(0):match '/threads/' then
    return notify('no review thread on this line', vim.log.levels.WARN)
  end
  local review = require('octo.reviews').get_current_review()
  local mine = vim.tbl_filter(function(c)
    return c.viewerCanDelete and c.kind == 'PullRequestReviewComment'
  end, buffer.commentsMetadata or {})
  table.sort(mine, function(a, b) -- pending (current review) comments first
    return (review and a.reviewId == review.id and 0 or 1) < (review and b.reviewId == review.id and 0 or 1)
  end)
  local function delete(c)
    buffer:navigate_to_comment { id = c.id }
    require('octo.commands').delete_comment()
  end
  if #mine == 0 then
    return notify('no deletable comment in this thread', vim.log.levels.WARN)
  elseif #mine == 1 then
    return delete(mine[1])
  end
  vim.ui.select(mine, {
    prompt = 'Delete which comment?',
    format_item = function(c)
      local pending = review and c.reviewId == review.id and '[pending] ' or ''
      return pending .. (vim.split(vim.trim(c.body or ''), '\n')[1] or ''):sub(1, 80)
    end,
  }, function(c)
    if c then
      delete(c)
    end
  end)
end

function M.setup()
  local map = function(lhs, rhs, desc, mode)
    vim.keymap.set(mode or 'n', lhs, rhs, { desc = desc })
  end
  map('<leader>op', '<cmd>Octo pr list<CR>', 'PR: [p]ick open PR')
  map('<leader>oP', '<cmd>Octo search is:pr is:open review-requested:@me<CR>', 'PR: review-requested (@me)')
  map('<leader>oo', '<cmd>Octo pr<CR>', 'PR: [o]pen current branch PR')
  map('<leader>ok', '<cmd>Octo pr checkout<CR>', 'PR: chec[k]out')
  map('<leader>or', '<cmd>Octo review<CR>', 'Review: start/[r]esume')
  map('<leader>os', '<cmd>Octo review submit<CR>', 'Review: [s]ubmit')
  map('<leader>od', '<cmd>Octo review discard<CR>', 'Review: [d]iscard pending')
  map('<leader>oc', '<cmd>Octo review comments<CR>', 'Review: pending [c]omments')
  map('<leader>ox', '<cmd>Octo review close<CR>', 'Review: close tab')
  map('<leader>of', '<cmd>Octo pr changes<CR>', 'PR: changed [f]iles')
  map('<leader>ob', '<cmd>Octo pr browser<CR>', 'PR: open in [b]rowser')
  map('<leader>oa', M.copilot_review, 'Copilot: draft review ([a]gent)')
  map('<leader>oq', M.ask_copilot, 'Copilot: ask about line/selection', { 'n', 'x' })
  map('<leader>oi', M.draft_status, 'Review: drafted comments [i]nfo')
  map('<leader>ow', M.toggle_wrap, 'Review: toggle diff [w]rap')
end

return M
