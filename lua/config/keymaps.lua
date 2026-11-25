-- Clear highlights on search
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Open URLs or files under the cursor, falling back to an LSP definition.
vim.keymap.set('n', 'gf', function()
  if require('util.open_url').open_under_cursor() then
    return
  end

  local opened, err = pcall(vim.cmd, 'normal! gf')
  if opened then
    return
  end

  if not tostring(err):match 'E447' then
    error(err)
  end

  local clients = vim.lsp.get_clients {
    bufnr = 0,
    method = vim.lsp.protocol.Methods.textDocument_definition,
  }
  if #clients == 0 then
    vim.notify('No file or LSP definition found under cursor', vim.log.levels.WARN)
    return
  end

  Snacks.picker.lsp_definitions()
end, { desc = 'Open URL, file, or LSP definition under cursor' })

-- Map Ctrl-[ to Esc in all modes (kitty kkp distinguishes them; restore legacy behavior)
vim.keymap.set({ 'n', 'i', 'v', 's', 'x', 'c', 'o', 't' }, '<C-[>', '<Esc>', { desc = 'Ctrl-[ as Escape' })

-- Diagnostic keymaps (not <leader>q: that would delay the <leader>q* session maps)
vim.keymap.set('n', '<leader>sq', vim.diagnostic.setloclist, { desc = 'Diagnostics to loclist' })

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window navigation: <C-hjkl> come from vim-tmux-navigator (crosses into tmux panes)

-- Window resizing
-- Like tmux `prefix C-hjkl` (bind -r): <leader>w{hjkl} moves the split border in
-- that direction, then bare h/j/k/l keep resizing until 600ms idle or another key.
local function resize_border(dir)
  local horiz = dir == 'h' or dir == 'l'
  local has_next = vim.fn.winnr(horiz and 'l' or 'j') ~= vim.fn.winnr()
  local grow = (dir == 'l' or dir == 'j') == has_next
  local step = horiz and 15 or 7
  vim.cmd((horiz and 'vertical ' or '') .. 'resize ' .. (grow and '+' or '-') .. step)
end

local function resize_mode(dir)
  return function()
    resize_border(dir)
    while true do
      vim.cmd.redraw()
      if not vim.wait(600, function() return vim.fn.getchar(1) ~= 0 end, 10) then return end
      local c = vim.fn.getcharstr()
      if not c:match('^[hjkl]$') then
        vim.api.nvim_feedkeys(c, 'm', false)
        return
      end
      resize_border(c)
    end
  end
end

for _, d in ipairs { 'h', 'j', 'k', 'l' } do
  vim.keymap.set('n', '<leader>w' .. d, resize_mode(d), { desc = 'Resize: move border ' .. ({ h = 'left', j = 'down', k = 'up', l = 'right' })[d] .. ' (repeatable)' })
end

-- Increment number
vim.keymap.set('n', '<C-s>', '<C-a>', { desc = 'Increment number' })

-- Copy Markdown as rich text (HTML) for pasting into Loop/Teams/Outlook
vim.api.nvim_create_user_command('CopyRich', function(opts)
  if opts.range == 0 then
    require('util.rich_copy').copy()
  else
    require('util.rich_copy').copy(opts.line1, opts.line2)
  end
end, { range = true, desc = 'Copy Markdown as rich text (HTML)' })
vim.keymap.set('n', '<leader>my', '<cmd>CopyRich<CR>', { desc = '[M]arkdown [y]ank as rich text' })
vim.keymap.set('x', '<leader>my', ':CopyRich<CR>', { silent = true, desc = '[M]arkdown [y]ank selection as rich text' })
