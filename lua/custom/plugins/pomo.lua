-- Pomodoro timer: 25m work / 5m break, long 15m break after 4 rounds.
-- Notifications go through vim.notify (Snacks notifier) + macOS system alerts.

-- Snacks picker over active timers (<CR> pause/resume, <C-x> stop).
local function pick_timers()
  local pomo = require 'pomo'
  local items = {}
  for _, timer in ipairs(pomo.get_all_timers()) do
    table.insert(items, { text = tostring(timer), timer_id = timer.id })
  end
  -- Timers are per Neovim instance; offer to start one when none are running here.
  if #items == 0 then
    local choices = {
      { label = 'Pomodoro session (4x25m)', cmd = 'TimerSession pomodoro' },
      { label = '25m Work', cmd = 'TimerStart 25m Work' },
      { label = '5m Break', cmd = 'TimerStart 5m Break' },
      { label = '15m Long Break', cmd = 'TimerStart 15m Long Break' },
    }
    vim.ui.select(choices, {
      prompt = 'No active timers in this Neovim. Start one:',
      format_item = function(c) return c.label end,
    }, function(choice)
      if choice then
        vim.cmd(choice.cmd)
      end
    end)
    return
  end
  Snacks.picker.pick {
    title = 'Pomodoro timers',
    items = items,
    format = 'text',
    layout = { preset = 'select' },
    confirm = function(picker, item)
      picker:close()
      local timer = pomo.get_timer(item.timer_id)
      if not timer then
        return
      end
      if timer.paused then
        pomo.resume_timer(timer)
      else
        pomo.pause_timer(timer)
      end
    end,
    actions = {
      pomo_stop = function(picker, item)
        picker:close()
        pomo.stop_timer(item.timer_id)
      end,
    },
    win = { input = { keys = { ['<c-x>'] = { 'pomo_stop', mode = { 'n', 'i' } } } } },
  }
end

return {
  'epwalsh/pomo.nvim',
  version = '*',
  cmd = { 'TimerStart', 'TimerRepeat', 'TimerSession', 'TimerStop', 'TimerPause', 'TimerResume', 'TimerShow', 'TimerHide' },
  keys = {
    { '<leader>Pp', '<cmd>TimerSession pomodoro<cr>', desc = 'Start [P]omodoro session (4x25m)' },
    { '<leader>Pw', '<cmd>TimerStart 25m Work<cr>', desc = 'Start 25m [W]ork timer' },
    { '<leader>Pb', '<cmd>TimerStart 5m Break<cr>', desc = 'Start 5m short [B]reak' },
    { '<leader>PB', '<cmd>TimerStart 15m Long Break<cr>', desc = 'Start 15m long [B]reak' },
    { '<leader>Ps', '<cmd>TimerStop<cr>', desc = '[S]top timer' },
    { '<leader>Pz', '<cmd>TimerPause<cr>', desc = 'Pause timer' },
    { '<leader>Pr', '<cmd>TimerResume<cr>', desc = '[R]esume timer' },
    { '<leader>Pv', '<cmd>TimerShow<cr>', desc = 'Show timer [V]iew' },
    { '<leader>Ph', '<cmd>TimerHide<cr>', desc = '[H]ide timer' },
    { '<leader>Pl', pick_timers, desc = '[L]ist timers (picker)' },
  },
  opts = {
    update_interval = 1000,
    notifiers = {
      { name = 'Default', opts = { sticky = false } },
      { name = 'System' }, -- macOS notification when a timer finishes
    },
    sessions = {
      pomodoro = {
        { name = 'Work', duration = '25m' },
        { name = 'Short Break', duration = '5m' },
        { name = 'Work', duration = '25m' },
        { name = 'Short Break', duration = '5m' },
        { name = 'Work', duration = '25m' },
        { name = 'Short Break', duration = '5m' },
        { name = 'Work', duration = '25m' },
        { name = 'Long Break', duration = '15m' },
      },
    },
  },
}
