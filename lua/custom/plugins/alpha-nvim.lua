return {
  'goolord/alpha-nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local alpha = require 'alpha'
    local dashboard = require 'alpha.themes.dashboard'

    dashboard.section.header.val = {
      '                                                     ',
      '           ██████╗ ███████╗██╗   ██╗                 ',
      '           ██╔══██╗██╔════╝██║   ██║                 ',
      '           ██║  ██║█████╗  ██║   ██║                 ',
      '           ██║  ██║██╔══╝  ╚██╗ ██╔╝                 ',
      '           ██████╔╝███████╗ ╚████╔╝                  ',
      '           ╚═════╝ ╚══════╝  ╚═══╝                   ',
      '                                                     ',
      '   🍄 Power-up your code with magic mashrooms! 🍄   ',
      '                                                     ',
      '         ⭐ ┌─┐┬ ┬┌┐ ┌─┐┬─┐  ┌┬┐┌─┐┬  ┬ ⭐           ',
      '         🔥 │  └┬┘├┴┐├┤ ├┬┘   ││├┤ └┐┌┘ 🔥           ',
      '         👑 └─┘ ┴ └─┘└─┘┴└─  ─┴┘└─┘ └┘  👑           ',
      '                                                     ',
      "         🌟 It's-a me, your coding editor! 🌟       ",
      '                                                     ',
    }
    dashboard.section.buttons.val = {
      dashboard.button('f', '  Find file', ':Telescope find_files <CR>'),
      dashboard.button('r', '  Recent files', ':Telescope oldfiles <CR>'),
      dashboard.button('g', '  Find text', ':Telescope live_grep <CR>'),
      dashboard.button('c', '⚙  Config', ':e $MYVIMRC <CR>'),
      dashboard.button('q', '  Quit', ':qa<CR>'),
    }

    dashboard.section.footer.val = '🚀 Code with passion, debug with patience 🚀'

    alpha.setup(dashboard.opts)
  end,
}
