local active_process
local generation = 0
local audio_path = string.format(
  "/Users/junkataoka/projects/config/.nvim-tts-audio-%d.aiff",
  vim.fn.getpid()
)
local input_path = string.format(
  "/Users/junkataoka/projects/config/.nvim-tts-input-%d.txt",
  vim.fn.getpid()
)

local function cleanup_audio()
  vim.uv.fs_unlink(audio_path)
  vim.uv.fs_unlink(input_path)
end

local function stop()
  generation = generation + 1
  if active_process then
    active_process:kill(15)
    active_process = nil
  end
  cleanup_audio()
end

local function start_speech(text, token)
  if token ~= generation then
    return
  end

  if text:match("^%s*$") then
    vim.notify("Nothing to speak", vim.log.levels.WARN)
    return
  end

  local say_path = vim.fn.exepath("say")
  if say_path == "" then
    vim.notify("TTS failed: say executable not found", vim.log.levels.ERROR)
    return
  end
  local afplay_path = vim.fn.exepath("afplay")
  if afplay_path == "" then
    vim.notify("TTS failed: afplay executable not found", vim.log.levels.ERROR)
    return
  end

  local voice = vim.g.tts_voice or "Samantha"
  local args = { say_path, "-v", voice }
  local rate = vim.g.tts_rate or 320
  vim.list_extend(args, { "-r", tostring(rate), "-o", audio_path, "-f", input_path })

  local input_file, input_error = io.open(input_path, "w")
  if not input_file then
    vim.notify("TTS failed: " .. input_error, vim.log.levels.ERROR)
    return
  end
  input_file:write(text)
  input_file:close()

  local process
  process = vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if token ~= generation then
        cleanup_audio()
        return
      end

      if result.code ~= 0 then
        active_process = nil
        vim.notify("TTS failed: " .. result.stderr, vim.log.levels.ERROR)
        cleanup_audio()
        return
      end

      local playback
      playback = vim.system({ afplay_path, audio_path }, { text = true }, function(playback_result)
        if active_process == playback then
          active_process = nil
        end
        cleanup_audio()
        if playback_result.code ~= 0 and token == generation then
          vim.schedule(function()
            vim.notify("TTS playback failed: " .. playback_result.stderr, vim.log.levels.ERROR)
          end)
        end
      end)
      active_process = playback
    end)
  end)
  active_process = process
end

local function speak(text)
  stop()
  local token = generation
  local filetype = vim.bo.filetype
  local input_format

  if filetype == "markdown" then
    input_format = "markdown"
  elseif filetype == "tex" or filetype == "plaintex" then
    input_format = "latex"
  end

  if not input_format then
    start_speech(text, token)
    return
  end

  local pandoc_path = vim.fn.exepath("pandoc")
  if pandoc_path == "" then
    vim.notify("TTS failed: pandoc executable not found", vim.log.levels.ERROR)
    return
  end

  local process
  process = vim.system(
    { pandoc_path, "-f", input_format, "-t", "plain" },
    { stdin = text, text = true },
    function(result)
      vim.schedule(function()
        if token ~= generation then
          return
        end

        if active_process == process then
          active_process = nil
        end

        if result.code ~= 0 then
          vim.notify(result.stderr, vim.log.levels.ERROR)
          return
        end

        start_speech(result.stdout, token)
      end)
    end
  )
  active_process = process
end

local function lines(first, last)
  return table.concat(vim.api.nvim_buf_get_lines(0, first - 1, last, false), "\n")
end

local function paragraph_bounds()
  local line_count = vim.api.nvim_buf_line_count(0)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local first = cursor_line
  local last = cursor_line

  while first > 1 and not lines(first - 1, first - 1):match("^%s*$") do
    first = first - 1
  end

  while last < line_count and not lines(last + 1, last + 1):match("^%s*$") do
    last = last + 1
  end

  return first, last
end

vim.api.nvim_create_user_command("Speak", function(opts)
  speak(lines(opts.line1, opts.line2))
end, { range = true, force = true })

vim.api.nvim_create_user_command("SpeakParagraph", function()
  local first, last = paragraph_bounds()
  speak(lines(first, last))
end, { force = true })

vim.api.nvim_create_user_command("SpeakAll", function()
  speak(lines(1, vim.api.nvim_buf_line_count(0)))
end, { force = true })

vim.api.nvim_create_user_command("SpeakStop", stop, { force = true })

vim.keymap.set("v", "<leader>ts", ":Speak<CR>", { desc = "[T]ext [S]peak selection" })
vim.keymap.set("n", "<leader>ts", "<cmd>SpeakParagraph<CR>", { desc = "[T]ext [S]peak paragraph" })
vim.keymap.set("n", "<leader>ta", "<cmd>SpeakAll<CR>", { desc = "[T]ext speak [A]ll" })
vim.keymap.set("n", "<leader>tx", "<cmd>SpeakStop<CR>", { desc = "[T]ext stop speech" })
