return {
  'pwntester/octo.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  cmd = 'Octo',
  keys = {
    { '<leader>op', '<cmd>Octo pr list<cr>', desc = 'List PRs' },
    { '<leader>or', '<cmd>Octo review start<cr>', desc = 'Start review' },
    { '<leader>os', '<cmd>Octo review submit<cr>', desc = 'Submit review' },
    { '<leader>oc', '<cmd>Octo review comments<cr>', desc = 'View review comments' },
    { '<leader>od', '<cmd>Octo review discard<cr>', desc = 'Discard review' },
    { '<leader>oi', '<cmd>Octo issue list<cr>', desc = 'List issues' },
  },
  config = function()
    require('octo').setup {
      enable_builtin = true,
      default_remote = { 'upstream', 'origin' },
      picker = 'telescope',
      comment_icon = '',
      outdated_icon = '󰅒 ',
      resolved_icon = ' ',
      reaction_viewer_hint_icon = ' ',
      user_icon = ' ',
      timeline_marker = '',
      timeline_indent = 2,
      right_bubble_delimiter = '',
      left_bubble_delimiter = '',
      suppress_missing_scope = {
        projects_v2 = true,
      },
      mappings = {
        review_diff = {
          add_review_comment = { lhs = '<leader>ca', desc = 'Add review comment' },
          add_review_suggestion = { lhs = '<leader>cs', desc = 'Add review suggestion' },
        },
      },
    }
  end,
}
