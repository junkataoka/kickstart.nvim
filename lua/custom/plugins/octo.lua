return {
  'pwntester/octo.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  cmd = 'Octo',
  keys = {
    -- PR workflow
    { '<leader>op', '<cmd>Octo pr list<cr>', desc = 'List PRs' },
    { '<leader>or', '<cmd>Octo review start<cr>', desc = 'Start review' },
    { '<leader>oR', '<cmd>Octo review resume<cr>', desc = 'Resume review' },
    { '<leader>os', '<cmd>Octo review submit<cr>', desc = 'Submit review' },
    { '<leader>oc', '<cmd>Octo review comments<cr>', desc = 'View review comments' },
    { '<leader>od', '<cmd>Octo review discard<cr>', desc = 'Discard review' },
    -- Issues
    { '<leader>oi', '<cmd>Octo issue list<cr>', desc = 'List issues' },
    -- Quick actions
    { '<leader>ob', '<cmd>Octo pr browser<cr>', desc = 'Open PR in browser' },
    { '<leader>of', '<cmd>Octo pr changes<cr>', desc = 'List changed files' },
    { '<leader>om', '<cmd>Octo pr merge<cr>', desc = 'Merge PR' },
  },
  config = function()
    require('octo').setup {
      enable_builtin = true,
      default_remote = { 'upstream', 'origin' },
      default_merge_method = 'squash',
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
      snippet_context_lines = 8,
      ui = {
        use_signcolumn = true,
        use_statuscolumn = true,
        use_foldtext = true,
      },
      reviews = {
        auto_show_threads = true,
        focus = 'right',
      },
      file_panel = {
        size = 15,
        use_icons = true,
      },
      suppress_missing_scope = {
        projects_v2 = true,
      },
      mappings = {
        submit_win = {
          approve_review = { lhs = '<leader>ra', desc = 'approve review' },
          comment_review = { lhs = '<leader>rm', desc = 'comment review' },
          request_changes = { lhs = '<leader>rr', desc = 'request changes' },
          close_review_tab = { lhs = '<C-c>', desc = 'close review tab' },
        },
      },
    }

    -- Workaround for octo.nvim#323: duplicate review comments on repeated :w
    -- save() checks id == -1 to decide create vs update, but id is set in
    -- async callback. Repeated :w before callback completes → dupe creates.
    -- Patch: skip save if any new comment create is already in-flight.
    local ok, octo_buffer = pcall(require, 'octo.model.octo-buffer')
    if ok and octo_buffer.OctoBuffer then
      local OctoBuffer = octo_buffer.OctoBuffer
      local original_save = OctoBuffer.save
      OctoBuffer.save = function(self)
        for _, c in ipairs(self.commentsMetadata or {}) do
          if tonumber(c.id) == -1 and c._octo_pending then
            vim.notify('[octo] create in-flight, skipping save to prevent dupe', vim.log.levels.WARN)
            return
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
        return original_save(self)
      end
    end
  end,
}
