-- obsidian.nvim (community fork) — Obsidian-like markdown workflow
-- Replaces Neorg workflow with markdown-based notes at ~/notes-md/
return {
  'obsidian-nvim/obsidian.nvim',
  version = '*',
  ft = 'markdown',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'hrsh7th/nvim-cmp',
    'nvim-telescope/telescope.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  -- Register global keymaps eagerly so which-key shows them and they work
  -- before any markdown file is opened. Each keymap also triggers lazy-load.
  keys = {
    { '<leader>nw', '<cmd>MdWorknote<CR>', desc = '[N]otes: [W]orknote' },
    { '<leader>nj', '<cmd>MdJournal<CR>', desc = '[N]otes: [J]ournal' },
    { '<leader>nc', '<cmd>MdCarryTasks<CR>', desc = '[N]otes: [C]arry tasks' },
    { '<leader>nm', '<cmd>MdMeetings<CR>', desc = '[N]otes: [M]eetings' },
    { '<leader>np', '<cmd>MdProject<CR>', desc = '[N]otes: [P]roject' },
    { '<leader>nP', '<cmd>MdLinkProject<CR>', desc = '[N]otes: Link [P]roject to worknote' },
    { '<leader>nb', '<cmd>Obsidian backlinks<CR>', desc = '[N]otes: [B]acklinks' },
    { '<leader>nl', '<cmd>Obsidian link<CR>', mode = 'v', desc = '[N]otes: [L]ink selection' },
    { '<leader>nL', '<cmd>Obsidian link new<CR>', mode = 'v', desc = '[N]otes: [L]ink selection to new note' },
    { '<leader>ns', '<cmd>Obsidian search<CR>', desc = '[N]otes: [S]earch' },
    { '<leader>nt', '<cmd>Obsidian tags<CR>', desc = '[N]otes: [T]ags' },
    { '<leader>nf', '<cmd>Obsidian quick_switch<CR>', desc = '[N]otes: [F]ind / quick switch' },
    { '<leader>ni', '<cmd>Obsidian paste_img<CR>', desc = '[N]otes: Paste [I]mage from clipboard' },
  },
  opts = {
    workspaces = {
      {
        name = 'notes',
        path = '~/notes-md',
      },
    },

    -- Notes directory (flat by default, custom commands handle subdirs)
    notes_subdir = nil,

    -- Daily notes configuration (used by :ObsidianToday, :ObsidianYesterday, etc.)
    daily_notes = {
      folder = 'daily',
      date_format = '%Y-%m-%d',
      alias_format = '%B %-d, %Y',
      default_tags = { 'daily' },
      template = nil, -- We handle daily notes through custom worknote/journal commands
    },

    -- Completion via nvim-cmp (obsidian.nvim auto-registers & injects sources per-buffer)
    completion = {
      nvim_cmp = true,
      min_chars = 1,
    },

    -- Wiki-style links
    link = { style = 'wiki' },

    -- Wiki link function — use the default wiki_link_id_prefix which renders as
    -- [[id|label]] or [[id]]. This uses note IDs (not full paths) for cleaner links
    -- that resolve correctly via obsidian.nvim's search. No custom override needed.

    -- Note ID generation — use filename-friendly slugs
    note_id_func = function(title)
      local suffix = ''
      if title ~= nil then
        -- Slugify: lowercase, replace spaces with hyphens, strip non-alphanumeric
        suffix = title:gsub('%s+', '-'):gsub('[^%w%-]', ''):lower()
      else
        -- If no title, use a timestamp-based ID
        suffix = tostring(os.time())
      end
      return suffix
    end,

    -- Where new notes go by default
    new_notes_location = 'current_dir',

    -- Note frontmatter (YAML)
    frontmatter = {
      func = function(note)
        local out = { id = note.id, aliases = note.aliases, tags = note.tags }
        -- Keep any extra metadata the user has added
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end
        return out
      end,
    },

    -- Templates
    templates = {
      folder = 'templates',
      date_format = '%Y-%m-%d',
      time_format = '%H:%M',
      substitutions = {
        -- Custom substitution for project_name (overridden per-call in custom commands)
        project_name = function()
          return '{{project_name}}'
        end,
      },
    },

    -- Picker (telescope integration)
    picker = {
      name = 'telescope.nvim',
      note_mappings = {
        new = '<C-x>',
        insert_link = '<C-l>',
      },
      tag_mappings = {
        tag_note = '<C-x>',
        insert_tag = '<C-l>',
      },
    },

    -- Attachments — use standard markdown image syntax so image.nvim can render them.
    -- Wiki-style ![[img]] is not recognised by Tree-sitter's markdown_inline grammar.
    -- Spaces in filenames must be percent-encoded or Tree-sitter won't parse the link.
    attachments = {
      folder = 'attachments',
      ---@param path string|obsidian.Path
      ---@return string
      img_text_func = function(path)
        local name = vim.fs.basename(tostring(path))
        -- Percent-encode spaces (CommonMark requires this for link destinations)
        local encoded = name:gsub(' ', '%%20')
        return string.format('![%s](attachments/%s)', name, encoded)
      end,
    },

    -- Disable legacy commands (ObsidianX -> Obsidian x)
    legacy_commands = false,

    -- Checkbox / task states — maps to Neorg-like workflow:
    --   [ ] undone, [-] pending, [>] deferred/on-hold, [~] in-progress,
    --   [!] important, [?] ambiguous, [x] done, [_] cancelled
    checkbox = {
      enabled = true,
      create_new = true,
      order = { ' ', '-', '~', '!', '?', '>', '_', 'x' },
    },

    -- UI / concealment handled by markview.nvim — disable obsidian's own UI
    ui = {
      enable = false,
    },
  },

  config = function(_, opts)
    require('obsidian').setup(opts)

    ---------------------------------------------------------------------------
    -- Helper: inject placeholders into template content
    ---------------------------------------------------------------------------
    local function inject_metadata(content, extra)
      extra = extra or {}
      local date = os.date '%Y-%m-%d'
      local time = os.date '%H:%M'
      local datetime = os.date '%Y-%m-%dT%H:%M:%S+0900'
      local year = os.date '%Y'
      local month = os.date '%m'
      local day = os.date '%d'

      content = content:gsub('{{date}}', date)
      content = content:gsub('{{time}}', time)
      content = content:gsub('{{datetime}}', datetime)
      content = content:gsub('{{year}}', year)
      content = content:gsub('{{month}}', month)
      content = content:gsub('{{day}}', day)

      for key, value in pairs(extra) do
        content = content:gsub('{{' .. key .. '}}', value)
      end

      return content
    end

    ---------------------------------------------------------------------------
    -- Helper: load a template file and inject placeholders
    ---------------------------------------------------------------------------
    local function load_template(template_path, extra)
      local file = io.open(vim.fn.expand(template_path), 'r')
      if not file then
        vim.notify('Template not found: ' .. template_path, vim.log.levels.ERROR)
        return nil
      end
      local content = file:read '*a'
      file:close()
      return inject_metadata(content, extra)
    end

    ---------------------------------------------------------------------------
    -- Helper: find the most recent previous worknote (up to 30 days back)
    ---------------------------------------------------------------------------
    local function find_previous_worknote(days_back)
      days_back = days_back or 1
      local max_lookback = 30

      for i = days_back, max_lookback do
        local timestamp = os.time() - (i * 86400)
        local y = os.date('%Y', timestamp)
        local m = os.date('%m', timestamp)
        local d = os.date('%d', timestamp)
        local filepath = vim.fn.expand('~/notes-md/worknotes/' .. y .. '/' .. m .. '/' .. d .. '.md')

        if vim.fn.filereadable(filepath) == 1 then
          return filepath, os.date('%Y-%m-%d', timestamp)
        end
      end
      return nil, nil
    end

    ---------------------------------------------------------------------------
    -- Helper: extract incomplete tasks from a markdown worknote
    -- Carries over tasks that are NOT [x] (done) or [_] (cancelled)
    -- Recognized states: [ ] undone, [-] pending, [~] in-progress,
    --   [!] important, [?] ambiguous, [>] deferred/on-hold
    ---------------------------------------------------------------------------
    local function extract_incomplete_tasks(filepath, source_date)
      local file = io.open(filepath, 'r')
      if not file then
        return {}
      end

      local tasks = {}
      local in_todo_section = false
      local in_carried_section = false

      for line in file:lines() do
        -- Detect sections by ## headings
        if line:match '^## Todo' then
          in_todo_section = true
          in_carried_section = false
        elseif line:match '^## Carried Over' then
          in_carried_section = true
          in_todo_section = false
        elseif line:match '^## ' then
          in_todo_section = false
          in_carried_section = false
        end

        -- Extract incomplete tasks: anything not [x] (done) or [_] (cancelled)
        if in_todo_section or in_carried_section then
          local task_match = line:match '^(%s*%- %[[^xX_]%] .+)'
          if task_match then
            -- Remove any existing source-date reference
            local clean_task = task_match:gsub('%s*%[from %d%d%d%d%-%d%d%-%d%d%]%(.-%)%s*$', '')
            clean_task = clean_task:gsub('%s*%[from %d%d%d%d%-%d%d%-%d%d%]%s*$', '')
            -- Remove wiki-link style source references
            clean_task = clean_task:gsub('%s*%[%[worknotes/%d+/%d+/%d+|from %d%d%d%d%-%d%d%-%d%d%]%]%s*$', '')

            -- Add source date as a wiki link reference
            local y, m, d = source_date:match '(%d%d%d%d)%-(%d%d)%-(%d%d)'
            local link = '[[worknotes/' .. y .. '/' .. m .. '/' .. d .. '|from ' .. source_date .. ']]'
            local task_with_ref = clean_task .. ' ' .. link
            table.insert(tasks, task_with_ref)
          end
        end
      end

      file:close()
      return tasks
    end

    ---------------------------------------------------------------------------
    -- Helper: insert carried tasks into "Carried Over" section of current buffer
    ---------------------------------------------------------------------------
    local function insert_carried_tasks(tasks)
      if #tasks == 0 then
        return false
      end

      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local insert_line = nil

      for i, line in ipairs(lines) do
        if line:match '^## Carried Over' then
          -- Find the line after "Tasks from previous day:" or insert after section header
          for j = i + 1, #lines do
            if lines[j]:match '^%s*Tasks from previous' then
              insert_line = j + 1
              break
            elseif lines[j]:match '^## ' then
              -- Next section started, insert before it
              insert_line = j
              break
            end
          end
          if not insert_line then
            insert_line = i + 1
          end
          break
        end
      end

      if insert_line then
        vim.api.nvim_buf_set_lines(0, insert_line - 1, insert_line - 1, false, tasks)
        return true
      end
      return false
    end

    ---------------------------------------------------------------------------
    -- Command: MdWorknote — Create or open today's worknote
    ---------------------------------------------------------------------------
    vim.api.nvim_create_user_command('MdWorknote', function()
      local year = os.date '%Y'
      local month = os.date '%m'
      local day = os.date '%d'
      local dir = vim.fn.expand('~/notes-md/worknotes/' .. year .. '/' .. month)
      local filepath = dir .. '/' .. day .. '.md'

      -- Create directory if it doesn't exist
      vim.fn.mkdir(dir, 'p')

      -- If file already exists, just open it
      if vim.fn.filereadable(filepath) == 1 then
        vim.cmd('edit ' .. filepath)
        vim.notify('Opened existing worknote: ' .. filepath, vim.log.levels.INFO)
        return
      end

      -- Load template and create new file
      local content = load_template '~/notes-md/templates/worknote.md'
      if content then
        vim.cmd('edit ' .. filepath)
        local lines = vim.split(content, '\n')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

        -- Auto-carry incomplete tasks from previous worknote
        local prev_filepath, prev_date = find_previous_worknote(1)
        if prev_filepath then
          local tasks = extract_incomplete_tasks(prev_filepath, prev_date)
          if #tasks > 0 then
            insert_carried_tasks(tasks)
            vim.notify('Carried over ' .. #tasks .. ' task(s) from ' .. prev_date, vim.log.levels.INFO)
          end
        end

        vim.cmd 'write'
        vim.notify('Created new worknote: ' .. filepath, vim.log.levels.INFO)
      end
    end, { desc = 'Create or open daily worknote (markdown)' })

    ---------------------------------------------------------------------------
    -- Command: MdJournal — Create or open today's journal
    ---------------------------------------------------------------------------
    vim.api.nvim_create_user_command('MdJournal', function()
      local year = os.date '%Y'
      local month = os.date '%m'
      local day = os.date '%d'
      local dir = vim.fn.expand('~/notes-md/journal/' .. year .. '/' .. month)
      local filepath = dir .. '/' .. day .. '.md'

      vim.fn.mkdir(dir, 'p')

      if vim.fn.filereadable(filepath) == 1 then
        vim.cmd('edit ' .. filepath)
        vim.notify('Opened existing journal: ' .. filepath, vim.log.levels.INFO)
        return
      end

      local content = load_template '~/notes-md/templates/journal.md'
      if content then
        vim.cmd('edit ' .. filepath)
        local lines = vim.split(content, '\n')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.cmd 'write'
        vim.notify('Created new journal: ' .. filepath, vim.log.levels.INFO)
      end
    end, { desc = 'Create or open daily journal (markdown)' })

    ---------------------------------------------------------------------------
    -- Command: MdCarryTasks — Manually carry tasks from previous worknote
    ---------------------------------------------------------------------------
    vim.api.nvim_create_user_command('MdCarryTasks', function()
      local prev_filepath, prev_date = find_previous_worknote(1)
      if not prev_filepath then
        vim.notify('No previous worknote found (looked back 30 days)', vim.log.levels.WARN)
        return
      end

      local tasks = extract_incomplete_tasks(prev_filepath, prev_date)
      if #tasks == 0 then
        vim.notify('No incomplete tasks found in ' .. prev_date, vim.log.levels.INFO)
        return
      end

      if insert_carried_tasks(tasks) then
        vim.notify('Carried over ' .. #tasks .. ' task(s) from ' .. prev_date, vim.log.levels.INFO)
      else
        -- No "Carried Over" section found, insert at cursor
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_buf_set_lines(0, cursor[1], cursor[1], false, tasks)
        vim.notify('Inserted ' .. #tasks .. ' task(s) at cursor from ' .. prev_date, vim.log.levels.INFO)
      end
    end, { desc = 'Pull incomplete tasks from previous worknote' })

    ---------------------------------------------------------------------------
    -- Helper: insert meetings into "Meetings" section of current buffer
    ---------------------------------------------------------------------------
    local function insert_meetings(meetings_lines)
      if #meetings_lines == 0 then
        return false
      end

      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local insert_line = nil

      for i, line in ipairs(lines) do
        if line:match '^## Meetings' then
          -- Find existing meeting sub-heading or next section
          for j = i + 1, #lines do
            if lines[j]:match '^### ' then
              -- Found existing meeting sub-heading, replace all meetings
              insert_line = j
              -- Find end of all meetings (next top-level section)
              local end_line = j
              for k = j + 1, #lines do
                if lines[k]:match '^## ' then
                  end_line = k - 1
                  break
                end
                end_line = k
              end
              -- Remove all existing meeting lines
              vim.api.nvim_buf_set_lines(0, j - 1, end_line, false, {})
              break
            elseif lines[j]:match '^## ' then
              insert_line = j
              break
            end
          end
          if not insert_line then
            insert_line = i + 1
          end
          break
        end
      end

      if insert_line then
        vim.api.nvim_buf_set_lines(0, insert_line - 1, insert_line - 1, false, meetings_lines)
        return true
      end
      return false
    end

    ---------------------------------------------------------------------------
    -- Command: MdMeetings — Fetch and insert meetings from Outlook via WorkIQ
    ---------------------------------------------------------------------------
    vim.api.nvim_create_user_command('MdMeetings', function(cmd_opts)
      local date = cmd_opts.args ~= '' and cmd_opts.args or os.date '%Y-%m-%d'
      local script_path = vim.fn.expand '~/notes/.scripts/fetch_meetings_workiq.sh'

      if vim.fn.filereadable(script_path) ~= 1 then
        vim.notify('Meetings script not found: ' .. script_path, vim.log.levels.ERROR)
        return
      end

      vim.notify('Fetching meetings for ' .. date .. ' (this takes ~60-90s)...', vim.log.levels.INFO)

      local timeout_ms = 240000 -- 4 minute timeout
      local job_done = false

      local job_id = vim.fn.jobstart({ script_path, date }, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
          if data and #data > 0 and data[1] ~= '' then
            vim.schedule(function()
              -- Filter out empty lines at the end
              local meetings = {}
              for _, line in ipairs(data) do
                if line ~= '' or #meetings > 0 then
                  table.insert(meetings, line)
                end
              end
              -- Remove trailing empty strings
              while #meetings > 0 and meetings[#meetings] == '' do
                table.remove(meetings)
              end

              if insert_meetings(meetings) then
                vim.notify('Inserted meetings for ' .. date, vim.log.levels.INFO)
              else
                -- No Meetings section found, insert at cursor
                local cursor = vim.api.nvim_win_get_cursor(0)
                vim.api.nvim_buf_set_lines(0, cursor[1], cursor[1], false, meetings)
                vim.notify('Inserted meetings at cursor for ' .. date, vim.log.levels.INFO)
              end
            end)
          end
        end,
        on_stderr = function(_, data)
          if data and #data > 0 and data[1] ~= '' then
            vim.schedule(function()
              local msg = table.concat(data, '\n')
              if msg:match 'Error' or msg:match 'error' then
                vim.notify('Meetings fetch error: ' .. msg, vim.log.levels.ERROR)
              end
            end)
          end
        end,
        on_exit = function(_, exit_code)
          job_done = true
          if exit_code ~= 0 then
            vim.schedule(function()
              vim.notify('Meetings fetch exited with code ' .. exit_code, vim.log.levels.WARN)
            end)
          end
        end,
      })

      -- Timeout: kill the job if it takes too long
      if job_id > 0 then
        vim.defer_fn(function()
          if not job_done then
            vim.fn.jobstop(job_id)
            vim.notify('Meetings fetch timed out after ' .. (timeout_ms / 1000) .. 's', vim.log.levels.ERROR)
          end
        end, timeout_ms)
      end
    end, {
      nargs = '?',
      desc = 'Fetch meetings from Outlook via WorkIQ for today or specified date',
      complete = function()
        return { os.date '%Y-%m-%d' }
      end,
    })

    ---------------------------------------------------------------------------
    -- Helper: get list of project files
    ---------------------------------------------------------------------------
    local function get_projects()
      local projects_dir = vim.fn.expand '~/notes-md/projects'
      local projects = {}
      local handle = io.popen('ls -1 "' .. projects_dir .. '"/*.md 2>/dev/null')
      if handle then
        for file in handle:lines() do
          local name = file:match '([^/]+)%.md$'
          if name and name ~= 'template' then
            table.insert(projects, name)
          end
        end
        handle:close()
      end
      return projects
    end

    ---------------------------------------------------------------------------
    -- Command: MdProject — Create or open a project note
    ---------------------------------------------------------------------------
    vim.api.nvim_create_user_command('MdProject', function(cmd_opts)
      local project_name = cmd_opts.args

      -- If no project name provided, show picker
      if project_name == '' then
        local projects = get_projects()

        if #projects == 0 then
          vim.ui.input({ prompt = 'New project name: ' }, function(input)
            if input and input ~= '' then
              vim.cmd('MdProject ' .. input)
            end
          end)
        else
          table.insert(projects, 1, '[+ New Project]')
          vim.ui.select(projects, { prompt = 'Select project:' }, function(choice)
            if choice == '[+ New Project]' then
              vim.ui.input({ prompt = 'New project name: ' }, function(input)
                if input and input ~= '' then
                  vim.cmd('MdProject ' .. input)
                end
              end)
            elseif choice then
              vim.cmd('MdProject ' .. choice)
            end
          end)
        end
        return
      end

      -- Sanitize project name for filename
      local filename = project_name:gsub('%s+', '-'):lower()
      local filepath = vim.fn.expand('~/notes-md/projects/' .. filename .. '.md')

      if vim.fn.filereadable(filepath) == 1 then
        vim.cmd('edit ' .. filepath)
        vim.notify('Opened project: ' .. project_name, vim.log.levels.INFO)
        return
      end

      -- Load template and create new file
      local content = load_template('~/notes-md/templates/project.md', { project_name = project_name })
      if content then
        vim.cmd('edit ' .. filepath)
        local lines = vim.split(content, '\n')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.cmd 'write'
        vim.notify('Created new project: ' .. project_name, vim.log.levels.INFO)
      end
    end, {
      nargs = '?',
      desc = 'Create or open a project note (markdown)',
      complete = function()
        return get_projects()
      end,
    })

    ---------------------------------------------------------------------------
    -- Command: MdLinkProject — Link a project to the current worknote
    ---------------------------------------------------------------------------
    vim.api.nvim_create_user_command('MdLinkProject', function()
      local projects = get_projects()

      if #projects == 0 then
        vim.notify('No projects found. Create one with :MdProject', vim.log.levels.WARN)
        return
      end

      vim.ui.select(projects, { prompt = 'Link project to worknote:' }, function(choice)
        if not choice then
          return
        end

        -- Read project file to get display name from frontmatter title
        local project_file = vim.fn.expand('~/notes-md/projects/' .. choice .. '.md')
        local display_name = choice
        local file = io.open(project_file, 'r')
        if file then
          local in_frontmatter = false
          for line in file:lines() do
            if line:match '^---' then
              if in_frontmatter then
                break -- end of frontmatter
              end
              in_frontmatter = true
            elseif in_frontmatter then
              local title = line:match '^title:%s*"?(.-)"?%s*$'
              if title then
                display_name = title
                break
              end
            end
          end
          file:close()
        end

        -- Create project section to insert
        local project_section = {
          '',
          '### [[projects/' .. choice .. '|' .. display_name .. ']]',
          '',
          '#### Progress',
          '',
          '- ',
          '',
          '#### Blockers',
          '',
          '- ',
          '',
          '#### Next Steps',
          '',
          '- ',
          '',
        }

        -- Find Projects section (## Projects) and insert before next ## section
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local insert_line = nil

        for i, line in ipairs(lines) do
          if line:match '^## Projects' then
            for j = i + 1, #lines do
              if lines[j]:match '^## ' and not lines[j]:match '^## Projects' then
                insert_line = j
                break
              end
            end
            if not insert_line then
              insert_line = #lines + 1
            end
            break
          end
        end

        if insert_line then
          vim.api.nvim_buf_set_lines(0, insert_line - 1, insert_line - 1, false, project_section)
          vim.notify('Linked project: ' .. display_name, vim.log.levels.INFO)
        else
          -- No Projects section, create one before Meetings / Questions / Notes
          local create_line = nil
          for i, line in ipairs(lines) do
            if line:match '^## Meetings' or line:match '^## Notes' or line:match '^## Questions' then
              create_line = i
              break
            end
          end

          if not create_line then
            create_line = #lines + 1
          end

          local projects_section = {
            '',
            '## Projects',
            '',
            'Active projects for today:',
          }
          for _, proj_line in ipairs(project_section) do
            table.insert(projects_section, proj_line)
          end

          vim.api.nvim_buf_set_lines(0, create_line - 1, create_line - 1, false, projects_section)
          vim.notify('Created Projects section and linked: ' .. display_name, vim.log.levels.INFO)
        end
      end)
    end, { desc = 'Link a project to current worknote (markdown)' })

    ---------------------------------------------------------------------------
    -- Keymaps (global <leader>n* keymaps are registered via lazy.nvim `keys`
    -- spec above, so they work before any markdown file is opened)
    ---------------------------------------------------------------------------

    ---------------------------------------------------------------------------
    -- Task / checkbox keymaps (mirrors Neorg <leader>t* workflow)
    ---------------------------------------------------------------------------
    -- These are set per-buffer for obsidian-managed markdown files.
    -- States: [ ] undone, [-] pending, [~] in-progress, [!] important,
    --         [?] ambiguous, [>] on-hold/deferred, [_] cancelled, [x] done
    vim.api.nvim_create_autocmd('BufEnter', {
      pattern = '*.md',
      callback = function(ev)
        vim.defer_fn(function()
          if not vim.b[ev.buf].obsidian_buffer then
            return
          end

          local actions = require 'obsidian.actions'

          -- Direct-set keymaps (like Neorg's individual state keymaps)
          vim.keymap.set('n', '<leader>td', function()
            actions.set_checkbox 'x'
          end, { buffer = ev.buf, desc = '[T]ask [D]one' })

          vim.keymap.set('n', '<leader>tu', function()
            actions.set_checkbox ' '
          end, { buffer = ev.buf, desc = '[T]ask [U]ndone' })

          vim.keymap.set('n', '<leader>tp', function()
            actions.set_checkbox '-'
          end, { buffer = ev.buf, desc = '[T]ask [P]ending' })

          vim.keymap.set('n', '<leader>ti', function()
            actions.set_checkbox '!'
          end, { buffer = ev.buf, desc = '[T]ask [I]mportant' })

          vim.keymap.set('n', '<leader>tq', function()
            actions.set_checkbox '?'
          end, { buffer = ev.buf, desc = '[T]ask Uncertain [?]' })

          vim.keymap.set('n', '<leader>to', function()
            actions.set_checkbox '>'
          end, { buffer = ev.buf, desc = '[T]ask [O]n Hold / Deferred' })

          vim.keymap.set('n', '<leader>tc', function()
            actions.set_checkbox '_'
          end, { buffer = ev.buf, desc = '[T]ask [C]ancelled' })

          vim.keymap.set('n', '<leader>tw', function()
            actions.set_checkbox '~'
          end, { buffer = ev.buf, desc = '[T]ask In-progress / [W]orking' })

          -- Cycle through all states
          vim.keymap.set('n', '<leader>tt', function()
            actions.toggle_checkbox()
          end, { buffer = ev.buf, desc = '[T]ask Cycle [T]oggle' })
        end, 0)
      end,
    })

    ---------------------------------------------------------------------------
    -- gf / K overrides — follow [[wiki links]] in vault markdown files
    ---------------------------------------------------------------------------
    -- obsidian.nvim already registers <CR> as smart_action (follow links, toggle
    -- checkboxes, etc.) for vault buffers. These add gf and K as alternatives.
    -- We use BufEnter instead of FileType to ensure obsidian_buffer flag is set.
    vim.api.nvim_create_autocmd('BufEnter', {
      pattern = '*.md',
      callback = function(ev)
        -- Only apply in obsidian-managed buffers (set by obsidian.nvim on BufEnter)
        vim.defer_fn(function()
          if not vim.b[ev.buf].obsidian_buffer then
            return
          end

          local api = require 'obsidian.api'

          -- gf: follow wiki link under cursor, fall back to built-in gf
          vim.keymap.set('n', 'gf', function()
            if api.cursor_link() then
              vim.cmd 'Obsidian follow_link'
            else
              vim.cmd 'normal! gf'
            end
          end, { buffer = ev.buf, desc = 'Follow [[link]] or default gf' })

          -- K: follow link under cursor, fall back to LSP hover / keywordprg
          vim.keymap.set('n', 'K', function()
            if api.cursor_link() then
              vim.cmd 'Obsidian follow_link'
            else
              vim.lsp.buf.hover()
            end
          end, { buffer = ev.buf, desc = 'Hover preview or default K' })
        end, 0)
      end,
    })
  end,
}
