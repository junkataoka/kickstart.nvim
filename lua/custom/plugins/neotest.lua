-- neotest.lua
--
-- Test runner UI. Reuses nvim-dap / dap-python / dap-go from debug.lua for
-- the `dap` strategy (<leader>td).
-- <leader>ts/ta/tx are taken by tts, <leader>th by LSP inlay hints.

local function neotest()
  return require 'neotest'
end

return {
  'nvim-neotest/neotest',
  cmd = 'Neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'nvim-neotest/neotest-python',
    'fredrikaverpil/neotest-golang',
  },
  keys = {
    { '<leader>tr', function() neotest().run.run() end, desc = '[T]est [R]un nearest' },
    { '<leader>tf', function() neotest().run.run(vim.fn.expand '%') end, desc = '[T]est run [F]ile' },
    { '<leader>tA', function() neotest().run.run(vim.uv.cwd()) end, desc = '[T]est run [A]ll' },
    { '<leader>tl', function() neotest().run.run_last() end, desc = '[T]est run [L]ast' },
    { '<leader>td', function() neotest().run.run { strategy = 'dap' } end, desc = '[T]est [D]ebug nearest' },
    { '<leader>tQ', function() neotest().run.stop() end, desc = '[T]est stop' },
    { '<leader>tS', function() neotest().summary.toggle() end, desc = '[T]est [S]ummary' },
    { '<leader>to', function() neotest().output.open { enter = true, auto_close = true } end, desc = '[T]est [O]utput' },
    { '<leader>tO', function() neotest().output_panel.toggle() end, desc = '[T]est [O]utput panel' },
    { '<leader>tw', function() neotest().watch.toggle(vim.fn.expand '%') end, desc = '[T]est [W]atch file' },
    { ']t', function() neotest().jump.next { status = 'failed' } end, desc = 'Next failed test' },
    { '[t', function() neotest().jump.prev { status = 'failed' } end, desc = 'Prev failed test' },
  },
  config = function()
    local adapters = {
      require 'neotest-python' {
        runner = 'pytest',
        dap = { justMyCode = false },
      },
    }

    -- neotest-golang errors without the go binary and Tree-sitter parser.
    if vim.fn.executable 'go' == 1 and pcall(vim.treesitter.language.add, 'go') then
      table.insert(adapters, require 'neotest-golang' { dap_go_enabled = true })
    end

    require('neotest').setup {
      adapters = adapters,
      status = { virtual_text = true },
      output = { open_on_run = false },
      quickfix = { open = false },
    }
  end,
}
