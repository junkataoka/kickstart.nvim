-- Snacks.nvim — dashboard, indent guides, scope, statuscolumn, and small utilities.
-- Currently we only enable the modules we want; other modules stay off so this
-- doesn't conflict with existing plugins (lualine, gitsigns, noice, etc).
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  keys = {
    { '<leader>lg', function() Snacks.lazygit() end, desc = 'LazyGit' },

    -- Files / buffers
    { '<leader>sf', function() Snacks.picker.smart() end, desc = '[S]earch [F]iles (smart)' },
    { '<leader>sF', function() Snacks.picker.files() end, desc = '[S]earch [F]iles (plain)' },
    { '<leader>s.', function() Snacks.picker.recent() end, desc = '[S]earch Recent Files' },
    { '<leader><leader>', function() Snacks.picker.buffers() end, desc = '[ ] Find existing buffers' },
    { '<leader>sn', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, desc = '[S]earch [N]eovim files' },
    { '<leader>sz', function() Snacks.picker.zoxide() end, desc = '[S]earch with [Z]oxide' },
    { '<leader>sp', function() Snacks.picker.projects() end, desc = '[S]earch [P]rojects' },

    -- Grep
    { '<leader>sg', function() Snacks.picker.grep() end, desc = '[S]earch by [G]rep' },
    { '<leader>sw', function() Snacks.picker.grep_word() end, desc = '[S]earch current [W]ord', mode = { 'n', 'x' } },
    { '<leader>s/', function() Snacks.picker.grep_buffers() end, desc = '[S]earch [/] in Open Files' },
    { '<leader>/', function() Snacks.picker.lines() end, desc = '[/] Fuzzily search in current buffer' },

    -- Symbols: LSP when attached, treesitter otherwise
    {
      '<leader>ss',
      function()
        local has_lsp = #vim.lsp.get_clients { bufnr = 0, method = 'textDocument/documentSymbol' } > 0
        if has_lsp then
          Snacks.picker.lsp_symbols()
        else
          Snacks.picker.treesitter()
        end
      end,
      desc = '[S]earch [S]ymbols (buffer)',
    },
    { '<leader>sS', function() Snacks.picker.lsp_workspace_symbols() end, desc = '[S]earch [S]ymbols (workspace)' },

    -- Misc
    { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [H]elp' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = '[S]earch [K]eymaps' },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = '[S]earch [D]iagnostics' },
    { '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, desc = '[S]earch Buffer [D]iagnostics' },
    { '<leader>sr', function() Snacks.picker.resume() end, desc = '[S]earch [R]esume' },
    { '<leader>sa', function() Snacks.picker.pickers() end, desc = '[S]earch [A]ll pickers' },
  },
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true }, -- disable expensive features on huge files
    quickfile = { enabled = true }, -- render the file before plugins load
    notifier = { enabled = true }, -- vim.notify backend (noice.notify is off)
    statuscolumn = { enabled = false },
    indent = { enabled = true },
    picker = {
      enabled = true,
      ui_select = true,
      formatters = {
        file = { filename_first = true },
      },
      sources = {
        files = { hidden = true },
        grep = { hidden = true },
        grep_word = { hidden = true },
        zoxide = { confirm = 'cd' },
      },
    },
    lazygit = {
      configure = false, -- we manage ~/.config/lazygit/config.yml ourselves
      win = { style = 'lazygit' },
    },

    dashboard = {
      preset = {
        -- Use the launcher app for `q` and `c` so they actually trigger plugins lazily.
        keys = {
          { icon = ' ', key = 'f', desc = 'Find File',       action = ':lua Snacks.picker.smart()' },
          { icon = ' ', key = 'n', desc = 'New File',        action = ':ene | startinsert' },
          { icon = ' ', key = 'r', desc = 'Recent Files',    action = ':lua Snacks.picker.recent()' },
          { icon = ' ', key = 'g', desc = 'Find Text',       action = ':lua Snacks.picker.grep()' },
          { icon = ' ', key = 'p', desc = 'Projects',        action = ':lua Snacks.picker.zoxide()' },
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
