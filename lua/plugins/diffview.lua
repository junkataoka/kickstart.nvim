-- Side-by-side diffs, file history, branch review and the 3-way merge tool.
-- In a merge/rebase with conflicts, <leader>gvo opens the merge view.
local function default_branch()
  local r = vim.system({ 'git', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD' }, { text = true }):wait()
  if r.code == 0 then return vim.trim(r.stdout) end
  for _, b in ipairs { 'origin/main', 'origin/master', 'main', 'master' } do
    if vim.system({ 'git', 'rev-parse', '--verify', '--quiet', b }):wait().code == 0 then return b end
  end
end

local close = { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } }

return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory', 'DiffviewToggleFiles', 'DiffviewRefresh' },
  keys = {
    { '<leader>gvo', '<cmd>DiffviewOpen<cr>', desc = 'Diff[v]iew [o]pen (working tree / conflicts)' },
    {
      '<leader>gvm',
      function()
        local base = default_branch()
        if not base then return vim.notify('No default branch found', vim.log.levels.WARN) end
        vim.cmd('DiffviewOpen ' .. base .. '...HEAD')
      end,
      desc = 'Diff[v]iew branch vs [m]ain (PR view)',
    },
    { '<leader>gvh', '<cmd>DiffviewFileHistory %<cr>', desc = 'Diff[v]iew file [h]istory' },
    { '<leader>gvh', ":'<,'>DiffviewFileHistory<cr>", mode = 'x', desc = 'Diff[v]iew selection [h]istory' },
    { '<leader>gvb', '<cmd>DiffviewFileHistory<cr>', desc = 'Diff[v]iew [b]ranch history' },
    { '<leader>gvq', '<cmd>DiffviewClose<cr>', desc = 'Diff[v]iew [q]uit' },
  },
  opts = {
    enhanced_diff_hl = true,
    view = {
      merge_tool = { layout = 'diff3_mixed' },
    },
    keymaps = {
      view = { close },
      file_panel = { close },
      file_history_panel = { close },
    },
  },
}
