-- Per-repo GitHub account for every child process (gh, Snacks.gh, lazygit,
-- :terminal, git push via `gh auth git-credential`).
-- gh's active account is the work one, which 404s on private personal repos, so
-- inside junkataoka/* repos export the personal token as GH_TOKEN; elsewhere
-- restore whatever GH_TOKEN nvim was started with.
local M = {}

local PERSONAL_USER = 'junkataoka'
local original = vim.env.GH_TOKEN
local personal_token

local function is_personal(url)
  return url:find('github-personal:', 1, true) ~= nil
    or url:find('github%.com[:/]' .. PERSONAL_USER .. '/') ~= nil
end

local function token()
  if personal_token == nil then
    local tok = vim.env.GITHUB_PAT_PERSONAL
    if not tok or tok == '' then
      local r = vim.system({ 'gh', 'auth', 'token', '--user', PERSONAL_USER }, { text = true }):wait()
      tok = r.code == 0 and vim.trim(r.stdout) or ''
    end
    personal_token = tok ~= '' and tok or false
  end
  return personal_token or nil
end

function M.update()
  local r = vim.system({ 'git', 'remote', 'get-url', 'origin' }, { text = true, cwd = vim.fn.getcwd() }):wait()
  local personal = r.code == 0 and is_personal(r.stdout)
  vim.env.GH_TOKEN = personal and token() or original
  M.account = personal and PERSONAL_USER or 'default'
end

function M.setup()
  M.update()
  vim.api.nvim_create_autocmd('DirChanged', {
    group = vim.api.nvim_create_augroup('GhAccount', { clear = true }),
    callback = M.update,
  })
end

return M
