return {
  'HakonHarnes/img-clip.nvim',
  event = 'VeryLazy',
  opts = {
    default = {
      dir_path = 'assets/images', -- directory to save images
      relative_to_current_file = true,
      use_absolute_path = false,
      prompt_for_file_name = true,
      show_dir_path_in_prompt = true,
    },
  },
  keys = {
    { '<leader>pi', '<cmd>PasteImage<cr>', desc = 'Paste image from clipboard' },
  },
}
