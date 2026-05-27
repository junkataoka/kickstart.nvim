return {
  'echasnovski/mini.diff',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    require('mini.diff').setup {
      source = require('mini.diff').gen_source.none(),
    }
  end,
}
