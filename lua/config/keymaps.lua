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
vim.keymap.set('n', '<leader>wl', ':vertical resize -20<CR>', { silent = true, desc = 'Decrease window width' })
vim.keymap.set('n', '<leader>wh', ':vertical resize +20<CR>', { silent = true, desc = 'Increase window width' })
vim.keymap.set('n', '<leader>wj', ':resize -20<CR>', { silent = true, desc = 'Decrease window height' })
vim.keymap.set('n', '<leader>wk', ':resize +20<CR>', { silent = true, desc = 'Increase window height' })

-- Increment number
vim.keymap.set('n', '<C-s>', '<C-a>', { desc = 'Increment number' })
