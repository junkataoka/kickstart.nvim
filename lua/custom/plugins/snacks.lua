-- Snacks.nvim — dashboard, indent guides, scope, statuscolumn, and small utilities.
-- Currently we only enable the modules we want; other modules stay off so this
-- doesn't conflict with existing plugins (lualine, gitsigns, noice, etc).

-- zoxide/projects: <CR> cds and opens files there. Built-in `cd` leaves the
-- picker open; built-in `load_session` replaces all windows. <A-s> keeps it.
local dir_pick = {
  confirm = function(picker, item)
    picker:close()
    if not item then return end
    local dir = Snacks.picker.util.dir(item)
    vim.fn.chdir(dir)
    vim.notify('cwd: ' .. vim.fn.fnamemodify(dir, ':~'))
    Snacks.picker.files()
  end,
  -- ~/.config/nvim is a symlink into ~/projects/config: show each dir once
  transform = function(item, ctx)
    ctx.meta.seen = ctx.meta.seen or {}
    local real = vim.uv.fs_realpath(item.file) or item.file
    if ctx.meta.seen[real] then return false end
    ctx.meta.seen[real] = true
  end,
  win = { input = { keys = { ['<a-s>'] = { 'load_session', mode = { 'n', 'i' } } } } },
}

return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  init = function() require('util.lazygit').setup() end,
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
    -- Newest files on disk under ALL tmux pane cwds + Copilot session files; see lua/util/recent_files.lua
    { '<leader>so', function() require('util.recent_files').pick() end, desc = '[S]earch newest files from tmux panes/c[O]pilot' },

    -- Copilot CLI session artifacts (~/.copilot/session-state/<id>/files/*), newest first
    {
      '<leader>sc',
      function()
        local root = vim.fn.expand '~/.copilot/session-state'
        local paths = vim.fn.glob(root .. '/*/files/**/*', false, true)
        local items = {}
        for _, p in ipairs(paths) do
          local stat = vim.uv.fs_stat(p)
          if stat and stat.type == 'file' then
            local rel = p:sub(#root + 2)
            table.insert(items, { file = p, text = rel, mtime = stat.mtime.sec })
          end
        end
        table.sort(items, function(a, b) return a.mtime > b.mtime end)
        Snacks.picker.pick {
          title = 'Copilot session files',
          items = items,
          format = 'file',
          sort = { fields = { 'score:desc', 'idx' } },
        }
      end,
      desc = '[S]earch [C]opilot session files',
    },
    {
      '<leader>sC',
      function()
        Snacks.picker.grep {
          title = 'Grep Copilot session files',
          dirs = { vim.fn.expand '~/.copilot/session-state' },
          glob = '*/files/**',
          hidden = true,
        }
      end,
      desc = '[S]earch [C]opilot session files (grep)',
    },

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
      -- <a-y>/<a-Y>: copy selected file path (relative to cwd / absolute) in every picker; see lua/util/picker_paths.lua
      actions = require('util.picker_paths').actions,
      win = {
        input = { keys = require('util.picker_paths').keys },
        list = { keys = require('util.picker_paths').keys },
      },
      sources = {
        files = { hidden = true },
        grep = { hidden = true },
        grep_word = { hidden = true },
        zoxide = dir_pick,
        projects = dir_pick,
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
