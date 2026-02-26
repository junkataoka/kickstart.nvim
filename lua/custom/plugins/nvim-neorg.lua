return {
  'nvim-neorg/neorg',
  lazy = false,
  version = '*',
  config = function()
    require('neorg').setup {
      load = {
        ['core.defaults'] = {},
        ['core.concealer'] = {
          config = {
            icon_preset = 'diamond',
            icons = {
              code_block = {
                conceal = true,
              },
            },
          },
        },
        ['core.dirman'] = {
          config = {
            workspaces = {
              notes = '~/notes',
            },
            default_workspace = 'notes',
            index = 'index.norg',
          },
        },
      },
    }

    -- Set concealing options for norg files
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'norg',
      callback = function()
        vim.opt_local.conceallevel = 2
        vim.opt_local.concealcursor = ''
      end,
    })

    -- Helper function to inject metadata into template content
    local function inject_metadata(content, extra)
      extra = extra or {}
      local date = os.date '%Y-%m-%d'
      local datetime = os.date '%Y-%m-%dT%H:%M:%S+0900'
      local year = os.date '%Y'
      local month = os.date '%m'
      local day = os.date '%d'

      content = content:gsub('{DATE}', date)
      content = content:gsub('{DATETIME}', datetime)
      content = content:gsub('{YEAR}', year)
      content = content:gsub('{MONTH}', month)
      content = content:gsub('{DAY}', day)

      -- Inject extra placeholders
      for key, value in pairs(extra) do
        content = content:gsub('{' .. key .. '}', value)
      end

      return content
    end

    -- Load template and inject metadata
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

    -- Find the most recent previous worknote (up to 30 days back)
    local function find_previous_worknote(days_back)
      days_back = days_back or 1
      local max_lookback = 30

      for i = days_back, max_lookback do
        local timestamp = os.time() - (i * 86400)
        local year = os.date('%Y', timestamp)
        local month = os.date('%m', timestamp)
        local day = os.date('%d', timestamp)
        local filepath = vim.fn.expand('~/notes/worknotes/' .. year .. '/' .. month .. '/' .. day .. '.norg')

        if vim.fn.filereadable(filepath) == 1 then
          return filepath, os.date('%Y-%m-%d', timestamp)
        end
      end
      return nil, nil
    end

    -- Extract incomplete tasks from a worknote file
    local function extract_incomplete_tasks(filepath, source_date)
      local file = io.open(filepath, 'r')
      if not file then
        return {}
      end

      local tasks = {}
      local in_todo_section = false
      local in_carried_section = false

      for line in file:lines() do
        -- Detect Todo section
        if line:match '^%* Todo' then
          in_todo_section = true
          in_carried_section = false
        elseif line:match '^%* Carried Over' then
          in_carried_section = true
          in_todo_section = false
        elseif line:match '^%* ' then
          in_todo_section = false
          in_carried_section = false
        end

        -- Extract incomplete tasks: ( ), (-), (?), (!), (=)
        -- Excludes: (x) done, (_) cancelled
        if in_todo_section or in_carried_section then
          local task_match = line:match '^(%s*%- %([%s%-%?%!%=]%) .+)'
          if task_match then
            -- Remove any existing date reference (old tilde format or new link format)
            local clean_task = task_match:gsub('%s*~%(from %d%d%d%d%-%d%d%-%d%d%)~', '')
            clean_task = clean_task:gsub('%s*{:%$/worknotes/%d+/%d+/%d+:}%[from %d%d%d%d%-%d%d%-%d%d%]', '')
            -- Add source date reference as Neorg link
            local year, month, day = source_date:match '(%d%d%d%d)%-(%d%d)%-(%d%d)'
            local link = '{:$/worknotes/' .. year .. '/' .. month .. '/' .. day .. ':}[from ' .. source_date .. ']'
            local task_with_ref = clean_task .. ' ' .. link
            table.insert(tasks, task_with_ref)
          end
        end
      end

      file:close()
      return tasks
    end

    -- Insert carried tasks into buffer at "Carried Over" section
    local function insert_carried_tasks(tasks)
      if #tasks == 0 then
        return false
      end

      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local insert_line = nil

      for i, line in ipairs(lines) do
        if line:match '^%* Carried Over' then
          -- Find the line after "Tasks from previous day:" or insert after section header
          for j = i + 1, #lines do
            if lines[j]:match '^%s*Tasks from previous' then
              insert_line = j + 1
              break
            elseif lines[j]:match '^%* ' then
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

    -- Create new daily worknote with template
    vim.api.nvim_create_user_command('NeorgWorknote', function()
      local year = os.date '%Y'
      local month = os.date '%m'
      local day = os.date '%d'
      local dir = vim.fn.expand('~/notes/worknotes/' .. year .. '/' .. month)
      local filepath = dir .. '/' .. day .. '.norg'

      -- Create directory if it doesn't exist
      vim.fn.mkdir(dir, 'p')

      -- Check if file already exists
      if vim.fn.filereadable(filepath) == 1 then
        vim.cmd('edit ' .. filepath)
        vim.notify('Opened existing worknote: ' .. filepath, vim.log.levels.INFO)
        return
      end

      -- Load template and create new file
      local content = load_template '~/notes/worknotes/template.norg'
      if content then
        vim.cmd('edit ' .. filepath)
        local lines = vim.split(content, '\n')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

        -- Find and carry over incomplete tasks from previous worknote
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
    end, { desc = 'Create or open daily worknote with template' })

    -- Manually carry tasks from previous worknote
    vim.api.nvim_create_user_command('NeorgCarryTasks', function()
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
        -- If no "Carried Over" section, insert at cursor
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_buf_set_lines(0, cursor[1], cursor[1], false, tasks)
        vim.notify('Inserted ' .. #tasks .. ' task(s) at cursor from ' .. prev_date, vim.log.levels.INFO)
      end
    end, { desc = 'Pull incomplete tasks from previous worknote' })

    -- Create new daily journal with template
    vim.api.nvim_create_user_command('NeorgJournal', function()
      local year = os.date '%Y'
      local month = os.date '%m'
      local day = os.date '%d'
      local dir = vim.fn.expand('~/notes/journal/' .. year .. '/' .. month)
      local filepath = dir .. '/' .. day .. '.norg'

      -- Create directory if it doesn't exist
      vim.fn.mkdir(dir, 'p')

      -- Check if file already exists
      if vim.fn.filereadable(filepath) == 1 then
        vim.cmd('edit ' .. filepath)
        vim.notify('Opened existing journal: ' .. filepath, vim.log.levels.INFO)
        return
      end

      -- Load template and create new file
      local content = load_template '~/notes/journal/template.norg'
      if content then
        vim.cmd('edit ' .. filepath)
        local lines = vim.split(content, '\n')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.cmd 'write'
        vim.notify('Created new journal: ' .. filepath, vim.log.levels.INFO)
      end
    end, { desc = 'Create or open daily journal with template' })

    -- Generic template loader command
    vim.api.nvim_create_user_command('NeorgTemplate', function(opts)
      local template_name = opts.args
      local template_path = '~/notes/' .. template_name .. '/template.norg'
      local content = load_template(template_path)
      if content then
        local lines = vim.split(content, '\n')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.notify('Loaded template: ' .. template_name, vim.log.levels.INFO)
      end
    end, {
      nargs = 1,
      desc = 'Load a Neorg template with metadata injection',
      complete = function()
        -- Return available template directories
        return { 'worknotes', 'journal' }
      end,
    })

    -- Fetch and insert meetings from Outlook
    local function insert_meetings(meetings_lines)
      if #meetings_lines == 0 then
        return false
      end

      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local insert_line = nil

      for i, line in ipairs(lines) do
        if line:match '^%* Meetings' then
          -- Find existing meeting placeholder or next section
          for j = i + 1, #lines do
            if lines[j]:match '^%*%* Meeting:' then
              -- Replace the placeholder
              insert_line = j
              -- Find end of placeholder (next section or empty ** header)
              local end_line = j
              for k = j + 1, #lines do
                if lines[k]:match '^%* ' or lines[k]:match '^%*%* ' then
                  end_line = k - 1
                  break
                end
                end_line = k
              end
              -- Remove placeholder lines
              vim.api.nvim_buf_set_lines(0, j - 1, end_line, false, {})
              break
            elseif lines[j]:match '^%* ' then
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

    -- Fetch meetings from Outlook for Mac via AppleScript
    vim.api.nvim_create_user_command('NeorgMeetings', function(opts)
      local date = opts.args ~= '' and opts.args or os.date '%Y-%m-%d'
      local script_path = vim.fn.expand '~/notes/.scripts/fetch_meetings.sh'

      if vim.fn.filereadable(script_path) ~= 1 then
        vim.notify('Meetings script not found: ' .. script_path, vim.log.levels.ERROR)
        return
      end

      vim.notify('Fetching meetings for ' .. date .. '...', vim.log.levels.INFO)

      -- Run the AppleScript-based shell script asynchronously
      vim.fn.jobstart({ script_path, date }, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
          if data and #data > 0 and data[1] ~= '' then
            vim.schedule(function()
              -- Filter out empty lines at the end
              local meetings_lines = {}
              for _, line in ipairs(data) do
                if line ~= '' or #meetings_lines > 0 then
                  table.insert(meetings_lines, line)
                end
              end
              -- Remove trailing empty strings
              while #meetings_lines > 0 and meetings_lines[#meetings_lines] == '' do
                table.remove(meetings_lines)
              end

              if insert_meetings(meetings_lines) then
                vim.notify('Inserted meetings for ' .. date, vim.log.levels.INFO)
              else
                -- No Meetings section found, insert at cursor
                local cursor = vim.api.nvim_win_get_cursor(0)
                vim.api.nvim_buf_set_lines(0, cursor[1], cursor[1], false, meetings_lines)
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
      })
    end, {
      nargs = '?',
      desc = 'Fetch meetings from Outlook for today or specified date',
      complete = function()
        return { os.date '%Y-%m-%d' }
      end,
    })

    -- Keymaps for quick access
    vim.keymap.set('n', '<leader>nw', '<cmd>NeorgWorknote<CR>', { desc = '[N]eorg [W]orknote' })
    vim.keymap.set('n', '<leader>nj', '<cmd>NeorgJournal<CR>', { desc = '[N]eorg [J]ournal' })
    vim.keymap.set('n', '<leader>nc', '<cmd>NeorgCarryTasks<CR>', { desc = '[N]eorg [C]arry tasks' })
    vim.keymap.set('n', '<leader>nm', '<cmd>NeorgMeetings<CR>', { desc = '[N]eorg [M]eetings' })
    vim.keymap.set('n', '<leader>np', '<cmd>NeorgProject<CR>', { desc = '[N]eorg [P]roject' })

    -- Create or open a project note
    vim.api.nvim_create_user_command('NeorgProject', function(opts)
      local project_name = opts.args

      -- If no project name provided, show picker with existing projects
      if project_name == '' then
        local projects_dir = vim.fn.expand '~/notes/projects'
        local projects = {}

        -- Get list of existing project files
        local handle = io.popen('ls -1 "' .. projects_dir .. '"/*.norg 2>/dev/null')
        if handle then
          for file in handle:lines() do
            local name = file:match '([^/]+)%.norg$'
            if name and name ~= 'template' then
              table.insert(projects, name)
            end
          end
          handle:close()
        end

        if #projects == 0 then
          -- No projects exist, prompt for new name
          vim.ui.input({ prompt = 'New project name: ' }, function(input)
            if input and input ~= '' then
              vim.cmd('NeorgProject ' .. input)
            end
          end)
        else
          -- Show picker with existing projects + option to create new
          table.insert(projects, 1, '[+ New Project]')
          vim.ui.select(projects, { prompt = 'Select project:' }, function(choice)
            if choice == '[+ New Project]' then
              vim.ui.input({ prompt = 'New project name: ' }, function(input)
                if input and input ~= '' then
                  vim.cmd('NeorgProject ' .. input)
                end
              end)
            elseif choice then
              vim.cmd('NeorgProject ' .. choice)
            end
          end)
        end
        return
      end

      -- Sanitize project name for filename (replace spaces with hyphens, lowercase)
      local filename = project_name:gsub('%s+', '-'):lower()
      local filepath = vim.fn.expand('~/notes/projects/' .. filename .. '.norg')

      -- Check if file already exists
      if vim.fn.filereadable(filepath) == 1 then
        vim.cmd('edit ' .. filepath)
        vim.notify('Opened project: ' .. project_name, vim.log.levels.INFO)
        return
      end

      -- Load template and create new file
      local content = load_template('~/notes/projects/template.norg', { PROJECT_NAME = project_name })
      if content then
        vim.cmd('edit ' .. filepath)
        local lines = vim.split(content, '\n')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.cmd 'write'
        vim.notify('Created new project: ' .. project_name, vim.log.levels.INFO)
      end
    end, {
      nargs = '?',
      desc = 'Create or open a project note',
      complete = function()
        -- Return list of existing projects for completion
        local projects_dir = vim.fn.expand '~/notes/projects'
        local projects = {}
        local handle = io.popen('ls -1 "' .. projects_dir .. '"/*.norg 2>/dev/null')
        if handle then
          for file in handle:lines() do
            local name = file:match '([^/]+)%.norg$'
            if name and name ~= 'template' then
              table.insert(projects, name)
            end
          end
          handle:close()
        end
        return projects
      end,
    })

    -- Helper to get list of projects
    local function get_projects()
      local projects_dir = vim.fn.expand '~/notes/projects'
      local projects = {}
      local handle = io.popen('ls -1 "' .. projects_dir .. '"/*.norg 2>/dev/null')
      if handle then
        for file in handle:lines() do
          local name = file:match '([^/]+)%.norg$'
          if name and name ~= 'template' then
            table.insert(projects, name)
          end
        end
        handle:close()
      end
      return projects
    end

    -- Add a project link to current worknote
    vim.api.nvim_create_user_command('NeorgLinkProject', function()
      local projects = get_projects()

      if #projects == 0 then
        vim.notify('No projects found. Create one with :NeorgProject', vim.log.levels.WARN)
        return
      end

      vim.ui.select(projects, { prompt = 'Link project to worknote:' }, function(choice)
        if not choice then
          return
        end

        -- Get display name from project file title
        local project_file = vim.fn.expand('~/notes/projects/' .. choice .. '.norg')
        local display_name = choice
        local file = io.open(project_file, 'r')
        if file then
          for line in file:lines() do
            local title = line:match '^title:%s*(.+)$'
            if title then
              display_name = title
              break
            end
          end
          file:close()
        end

        -- Create project section to insert
        local project_section = {
          '',
          '** {:$/projects/' .. choice .. ':}[' .. display_name .. ']',
          '*** Progress',
          '    - ',
          '',
          '*** Blockers',
          '    - ',
          '',
          '*** Next Steps',
          '    - ',
          '',
        }

        -- Find Projects section and insert
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local insert_line = nil

        for i, line in ipairs(lines) do
          if line:match '^%* Projects' then
            -- Find where to insert (after "Active projects" line or before next section)
            for j = i + 1, #lines do
              if lines[j]:match '^%* ' and not lines[j]:match '^%* Projects' then
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
          -- No Projects section found, create one
          -- Find a good place to insert (before Meetings, Notes, or Questions section)
          local create_line = nil
          for i, line in ipairs(lines) do
            if line:match '^%* Meetings' or line:match '^%* Notes' or line:match '^%* Questions' then
              create_line = i
              break
            end
          end

          if not create_line then
            create_line = #lines + 1
          end

          -- Create Projects section with the project link
          local projects_section = {
            '',
            '* Projects',
            '  Active projects for today:',
          }
          for _, proj_line in ipairs(project_section) do
            table.insert(projects_section, proj_line)
          end

          vim.api.nvim_buf_set_lines(0, create_line - 1, create_line - 1, false, projects_section)
          vim.notify('Created Projects section and linked: ' .. display_name, vim.log.levels.INFO)
        end
      end)
    end, { desc = 'Link a project to current worknote' })

    -- Sync daily project updates to the main project file
    vim.api.nvim_create_user_command('NeorgSyncProject', function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local current_date = os.date '%Y-%m-%d'

      -- Find all project sections and their content
      local projects_to_sync = {}
      local current_project = nil
      local current_content = {}
      local in_project_section = false

      for i, line in ipairs(lines) do
        -- Match project link: ** {:$/projects/name:}[Display Name]
        local project_name = line:match '^%*%* {:%$?/projects/([^:]+):}'
        if project_name then
          -- Save previous project if exists
          if current_project and #current_content > 0 then
            projects_to_sync[current_project] = current_content
          end
          current_project = project_name
          current_content = {}
          in_project_section = true
        elseif in_project_section then
          -- Check if we've left the project section (new ** or * heading)
          if line:match '^%*%* ' or line:match '^%* ' then
            if current_project and #current_content > 0 then
              projects_to_sync[current_project] = current_content
            end
            current_project = nil
            current_content = {}
            in_project_section = false
          else
            table.insert(current_content, line)
          end
        end
      end

      -- Don't forget last project
      if current_project and #current_content > 0 then
        projects_to_sync[current_project] = current_content
      end

      if vim.tbl_isempty(projects_to_sync) then
        vim.notify('No project updates found to sync', vim.log.levels.INFO)
        return
      end

      -- Sync each project
      local synced_count = 0
      for project_name, content in pairs(projects_to_sync) do
        local project_file = vim.fn.expand('~/notes/projects/' .. project_name .. '.norg')

        if vim.fn.filereadable(project_file) == 1 then
          -- Read project file
          local project_lines = {}
          local file = io.open(project_file, 'r')
          if file then
            for line in file:lines() do
              table.insert(project_lines, line)
            end
            file:close()
          end

          -- Find or create Log section
          local log_section_idx = nil
          for i, line in ipairs(project_lines) do
            if line:match '^%* Log' then
              log_section_idx = i
              break
            end
          end

          -- Build log entry
          local log_entry = {
            '',
            '** ' .. current_date,
          }
          for _, line in ipairs(content) do
            table.insert(log_entry, line)
          end

          if log_section_idx then
            -- Insert after Log heading
            for i, entry_line in ipairs(log_entry) do
              table.insert(project_lines, log_section_idx + i, entry_line)
            end
          else
            -- Add Log section at the end
            table.insert(project_lines, '')
            table.insert(project_lines, '* Log')
            for _, entry_line in ipairs(log_entry) do
              table.insert(project_lines, entry_line)
            end
          end

          -- Write back to file
          file = io.open(project_file, 'w')
          if file then
            file:write(table.concat(project_lines, '\n'))
            file:close()
            synced_count = synced_count + 1
          end
        end
      end

      vim.notify('Synced updates to ' .. synced_count .. ' project(s)', vim.log.levels.INFO)
    end, { desc = 'Sync project updates from worknote to project files' })

    -- Add keymaps
    vim.keymap.set('n', '<leader>nl', '<cmd>NeorgLinkProject<CR>', { desc = '[N]eorg [L]ink project' })
    vim.keymap.set('n', '<leader>ns', '<cmd>NeorgSyncProject<CR>', { desc = '[N]eorg [S]ync projects' })
  end,
}
