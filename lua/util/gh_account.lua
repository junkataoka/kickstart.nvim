-- Per-repo GitHub account for every child process (gh, Snacks.gh, lazygit,
-- :terminal, git push via `gh auth git-credential`).
-- gh's active account can be any of several logins, each of which 404s on the
-- others' repos, so pin GH_TOKEN by repo owner. Orgs behind an IP allow list
-- also need the per-URL git proxy (`http.<url>.proxy` in ~/.gitconfig) for gh,
-- which ignores git's proxy config. It's kept in M.proxy (not exported) so only
-- gh consumers (octo gh_env, the review pane) use it, not Copilot/LSPs.
local M = {}

local PERSONAL_USER = 'junkataoka'
local WORK_USER = 'junkataoka_microsoft'
M.WORK_USER = WORK_USER
local OWNER_USER = {
  [PERSONAL_USER] = PERSONAL_USER,
  aicdevelopment = 'ext-jun-kataoka-1_stargate',
  ['ai-partner'] = 'ext-jun-kataoka-1_stargate',
  ['digital-cockpit'] = 'ext-jun-kataoka-1_stargate',
}
local original = vim.env.GH_TOKEN
local tokens = {}

local function owner_of(url)
  if url:find('github-personal:', 1, true) then
    return PERSONAL_USER
  end
  return url:match('github%.com[:/]([^/]+)/')
end

function M.token(user)
  if tokens[user] == nil then
    local tok = user == PERSONAL_USER and vim.env.GITHUB_PAT_PERSONAL or nil
    if not tok or tok == '' then
      local r = vim.system({ 'gh', 'auth', 'token', '--user', user }, { text = true }):wait()
      tok = r.code == 0 and vim.trim(r.stdout) or ''
    end
    tokens[user] = tok ~= '' and tok or false
  end
  return tokens[user] or nil
end

local function git_proxy(owner)
  local r = vim.system({ 'git', 'config', '--get-urlmatch', 'http.proxy', 'https://github.com/' .. owner .. '/' }, { text = true }):wait()
  local p = r.code == 0 and vim.trim(r.stdout) or ''
  return p ~= '' and p or nil
end

function M.update()
  local r = vim.system({ 'git', 'remote', 'get-url', 'origin' }, { text = true, cwd = vim.fn.getcwd() }):wait()
  local owner = r.code == 0 and owner_of(vim.trim(r.stdout)) or nil
  local user = owner and OWNER_USER[owner]
  if not user and original and original ~= '' then
    vim.env.GH_TOKEN = original
    M.account = 'default'
  else
    user = user or WORK_USER
    vim.env.GH_TOKEN = M.token(user) or original
    M.account = user
  end
  M.proxy = owner and git_proxy(owner) or nil
end

function M.setup()
  M.update()
  vim.api.nvim_create_autocmd('DirChanged', {
    group = vim.api.nvim_create_augroup('GhAccount', { clear = true }),
    callback = M.update,
  })
end

return M
