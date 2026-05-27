-- Snacks.nvim — dashboard, indent guides, scope, statuscolumn, and small utilities.
-- Currently we only enable the modules we want; other modules stay off so this
-- doesn't conflict with existing plugins (lualine, gitsigns, noice, etc).
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  keys = {
    { '<leader>lg', function() Snacks.lazygit() end, desc = 'LazyGit' },
  },
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true }, -- disable expensive features on huge files
    quickfile = { enabled = true }, -- render the file before plugins load
    notifier = { enabled = false }, -- noice already handles this
    statuscolumn = { enabled = false },
    indent = { enabled = false }, -- indent-blankline already handles this
    lazygit = {
      configure = false, -- we manage ~/.config/lazygit/config.yml ourselves
      win = { style = 'lazygit' },
    },

    dashboard = {
      preset = {
        -- Use the launcher app for `q` and `c` so they actually trigger plugins lazily.
        keys = {
          { icon = ' ', key = 'f', desc = 'Find File',       action = ':Telescope find_files' },
          { icon = ' ', key = 'n', desc = 'New File',        action = ':ene | startinsert' },
          { icon = ' ', key = 'r', desc = 'Recent Files',    action = ':Telescope oldfiles' },
          { icon = ' ', key = 'g', desc = 'Find Text',       action = ':Telescope live_grep' },
          { icon = ' ', key = 'p', desc = 'Projects',        action = ':Telescope zoxide list' },
          { icon = ' ', key = 's', desc = 'Restore Session', section = 'session' },
          { icon = '󰒲 ', key = 'L', desc = 'Lazy',            action = ':Lazy',  enabled = package.loaded.lazy ~= nil },
          { icon = ' ', key = 'm', desc = 'Mason',           action = ':Mason' },
          { icon = ' ', key = 'c', desc = 'Config',          action = ':e $MYVIMRC' },
          { icon = ' ', key = 'q', desc = 'Quit',            action = ':qa' },
        },
        header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
]],
      },
      sections = {
        { section = 'header' },
        { section = 'keys', gap = 1, padding = 1 },
        { pane = 2, icon = ' ', title = 'Recent Files', section = 'recent_files', indent = 2, padding = 1 },
        { pane = 2, icon = ' ', title = 'Projects',     section = 'projects',     indent = 2, padding = 1 },
        {
          pane = 2,
          icon = ' ',
          title = 'Git Status',
          section = 'terminal',
          enabled = function()
            return Snacks.git.get_root() ~= nil
          end,
          cmd = 'git status --short --branch --renames',
          height = 5,
          padding = 1,
          ttl = 5 * 60,
          indent = 3,
        },
        { section = 'startup' },
      },
    },
  },
}
