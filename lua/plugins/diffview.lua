return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory', 'DiffviewToggleFiles', 'DiffviewRefresh' },
  keys = {
    { '<leader>gvo', '<cmd>DiffviewOpen<cr>', desc = 'Diff[v]iew [o]pen' },
    { '<leader>gvh', '<cmd>DiffviewFileHistory %<cr>', desc = 'Diff[v]iew file [h]istory' },
    { '<leader>gvb', '<cmd>DiffviewFileHistory<cr>', desc = 'Diff[v]iew [b]ranch history' },
    { '<leader>gvq', '<cmd>DiffviewClose<cr>', desc = 'Diff[v]iew [q]uit' },
  },
  opts = {
    enhanced_diff_hl = true,
    view = {
      merge_tool = { layout = 'diff3_mixed' },
    },
  },
}
