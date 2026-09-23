return {
  {
    dir = vim.fn.stdpath 'config',
    name = 'local-tts',
    lazy = false,
    config = function()
      vim.g.tts_voice = 'Zoe (Premium)'
      vim.g.tts_rate = 240
      require 'tts'
    end,
  },
}
