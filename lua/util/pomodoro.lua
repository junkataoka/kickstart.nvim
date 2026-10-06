-- Drive the tmux-pomodoro-plus timer (shown in the tmux status bar) from Neovim.
-- One global timer shared by every tmux pane and nvim instance.
local M = {}

local script = vim.fn.expand '~/.tmux/plugins/tmux-pomodoro-plus/scripts/pomodoro.sh'

local function status()
  local out = vim.fn.system { script }
  out = out:gsub('#%[[^%]]*%]', ''):gsub('%s+$', ''):gsub('^%s+', '')
  return out ~= '' and out or 'no timer'
end

function M.run(cmd)
  if not vim.env.TMUX then
    vim.notify('Pomodoro timer runs in tmux; start nvim inside tmux', vim.log.levels.WARN, { title = 'pomodoro' })
    return
  end
  if vim.fn.executable(script) == 0 then
    vim.notify('tmux-pomodoro-plus not installed (prefix + I in tmux)', vim.log.levels.ERROR, { title = 'pomodoro' })
    return
  end
  -- run-shell inside tmux so menu/prompt commands attach to the current client
  vim.system({ 'tmux', 'run-shell', script .. ' ' .. cmd }, {}, function()
    vim.schedule(function()
      if cmd ~= 'menu' and cmd ~= 'custom' then
        vim.notify(status(), vim.log.levels.INFO, { title = 'pomodoro ' .. cmd })
      end
    end)
  end)
end

function M.setup()
  local maps = {
    { 'p', 'toggle', 'Start/pause [P]omodoro' },
    { 's', 'cancel', '[S]top (cancel) pomodoro' },
    { 'n', 'skip', 'Skip to [N]ext pomodoro/break' },
    { 'r', 'restart', '[R]estart pomodoro' },
    { 'm', 'menu', 'Pomodoro [M]enu (tmux)' },
    { 'c', 'custom', '[C]ustom pomodoro length' },
  }
  for _, m in ipairs(maps) do
    vim.keymap.set('n', '<leader>P' .. m[1], function() M.run(m[2]) end, { desc = m[3] })
  end
  vim.api.nvim_create_user_command('Pomodoro', function(o) M.run(o.args ~= '' and o.args or 'toggle') end, {
    nargs = '?',
    complete = function() return { 'toggle', 'cancel', 'skip', 'restart', 'menu', 'custom' } end,
    desc = 'Control tmux pomodoro timer',
  })
end

return M
