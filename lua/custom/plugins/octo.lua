-- GitHub PR review (octo.nvim). Entry points and the Copilot CLI pane live in
-- lua/util/pr_review.lua; see :h octo for buffer-local <localleader> maps.
return {
  'pwntester/octo.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'folke/snacks.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  cmd = 'Octo',
  init = function()
    -- octo:// buffers are remote views; swap files only cause E325 when the same
    -- PR is opened in a second nvim (or after a crash) and abort octo's render.
    vim.api.nvim_create_autocmd({ 'BufNew', 'BufFilePost' }, {
      group = vim.api.nvim_create_augroup('OctoNoSwap', { clear = true }),
      pattern = { 'octo://*', '*/octo/null' }, -- octo/null = octo's "Loading..." placeholder
      callback = function(ev)
        vim.bo[ev.buf].swapfile = false
      end,
    })
    require('util.pr_review').setup()
  end,
  config = function()
    require('octo').setup {
      enable_builtin = true,
      default_remote = { 'upstream', 'origin' },
      default_merge_method = 'squash',
      picker = 'snacks',
      -- octo spawns gh with a whitelisted env that drops GH_TOKEN; pass it
      -- through (plus HTTPS_PROXY) so util/gh_account's per-repo account applies.
      gh_env = function()
        return { GH_TOKEN = vim.env.GH_TOKEN, HTTPS_PROXY = require('util.gh_account').proxy }
      end,
      use_local_fs = true, -- right side of review diffs = real files (LSP, gitsigns, gd work)
      suppress_missing_scope = { projects_v2 = true },
      reviews = {
        auto_show_threads = true,
        focus = 'right',
      },
      file_panel = { size = 12 },
      ui = { use_signcolumn = true },
      mappings = {
        -- defaults (<C-a>/<C-m>/<C-r>) are dangerous: <C-m> == <CR>, so Enter in
        -- normal mode posted the review; <C-a>/<C-r> shadow increment/redo.
        submit_win = {
          approve_review = { lhs = '<localleader>A', desc = 'approve review', mode = { 'n' } },
          comment_review = { lhs = '<localleader>C', desc = 'comment review', mode = { 'n' } },
          request_changes = { lhs = '<localleader>R', desc = 'request changes', mode = { 'n' } },
          close_review_tab = { lhs = '<C-c>', desc = 'close review tab', mode = { 'n' } },
        },
        -- octo only binds delete in the thread buffer; this works from the diff
        -- line (util/pr_review.lua registers the action)
        review_diff = {
          pr_review_delete_comment = { lhs = '<localleader>cd', desc = 'delete my comment on this line' },
        },
      },
    }
    require('util.pr_review').patch_octo()
  end,
}
