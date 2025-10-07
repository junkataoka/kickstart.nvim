return {
  'echasnovski/mini.diff',
  config = function()
    require('mini.diff').setup {
      source = require('mini.diff').gen_source.none(),
    }
  end,
}
