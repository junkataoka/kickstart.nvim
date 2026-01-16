return {
  'ahmedkhalf/project.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  opts = {
    detection_methods = { 'pattern', 'lsp' },
    patterns = { '.git', 'pyproject.toml', 'package.json', 'Makefile', '.venv' },
    silent_chdir = true,
  },
  config = function(_, opts)
    require('project_nvim').setup(opts)
    require('telescope').load_extension 'projects'

    local history = require 'project_nvim.utils.history'
    local projects_root = vim.fn.expand '~/projects'
    local uv = vim.loop
    local stat = uv.fs_stat(projects_root)
    if stat and stat.type == 'directory' then
      local scan = uv.fs_scandir(projects_root)
      if scan then
        while true do
          local name, type = uv.fs_scandir_next(scan)
          if not name then
            break
          end
          if type == 'directory' then
            table.insert(history.session_projects, projects_root .. '/' .. name)
          end
        end
      end
    end
  end,
}
