-- Both plugins together (most common setup)
return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      -- Python venv indicator
      local function python_venv()
        local venv = os.getenv 'VIRTUAL_ENV'
        if venv then
          return ' ' .. vim.fn.fnamemodify(venv, ':t')
        end
        return ''
      end

      require('lualine').setup {
        options = {
          theme = 'tokyonight',
          section_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = {
            { python_venv, cond = function() return vim.bo.filetype == 'python' end },
            'encoding',
            'fileformat',
            'filetype',
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        tabline = {}, -- Let bufferline handle the top
      }
    end,
  },
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('bufferline').setup {
        options = {
          diagnostics = 'nvim_lsp',
          separator_style = 'thin',
          show_buffer_close_icons = true,
          show_close_icon = false,
        },
      }
      -- Buffer navigation
      vim.keymap.set('n', '<A-l>', ':BufferLineCycleNext<CR>', { silent = true })
      vim.keymap.set('n', '<A-h>', ':BufferLineCyclePrev<CR>', { silent = true })
      vim.keymap.set('n', '<A-d>', ':bdelete<CR>', { silent = true })
    end,
  },
}
