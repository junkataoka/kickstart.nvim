-- Mini.nvim - Collection of small independent plugins
return {
  'echasnovski/mini.nvim',
  config = function()
    -- Better Around/Inside textobjects
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    -- Examples:
    -- - gsa iw) - [G]o [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - gsd'    - [G]o [S]urround [D]elete [']quotes
    -- - gsr)'   - [G]o [S]urround [R]eplace [)] [']
    require('mini.surround').setup {
      mappings = {
        add = 'gsa',
        delete = 'gsd',
        find = 'gsf',
        find_left = 'gsF',
        highlight = 'gsh',
        replace = 'gsr',
        update_n_lines = 'gsn',
      },
    }
  end,
}
