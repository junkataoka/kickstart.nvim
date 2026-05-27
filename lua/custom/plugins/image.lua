return {
  '3rd/image.nvim',
  ft = { 'markdown', 'vimwiki', 'norg', 'codecompanion' },
  dependencies = {
    'leafo/magick', -- Optional: for better image processing
  },
  config = function()
    -- Vault root for resolving image paths that are relative to the vault,
    -- not the current document (e.g. "attachments/foo.png" from a deeply nested note).
    local vault_root = vim.fn.expand '~/notes-md'

    require('image').setup {
      backend = 'kitty',
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = true,
          download_remote_images = true,
          only_render_image_at_cursor = true,
          only_render_image_at_cursor_mode = 'popup',
          filetypes = { 'markdown', 'vimwiki' },
          -- Resolve vault-relative paths (e.g. "attachments/img.png") from the vault root
          -- so images render correctly regardless of the note's subdirectory depth.
          -- Also decodes percent-encoded characters (%20 → space) since CommonMark
          -- requires spaces in link destinations to be encoded.
          resolve_image_path = function(document_path, image_path, fallback)
            -- Decode percent-encoded characters (e.g. %20 → space)
            local decoded = image_path:gsub('%%(%x%x)', function(hex)
              return string.char(tonumber(hex, 16))
            end)
            -- Absolute / home-relative paths — use as-is
            if decoded:sub(1, 1) == '/' or decoded:sub(1, 1) == '~' then
              return fallback(document_path, decoded)
            end
            -- If the file exists relative to the vault root, prefer that
            local vault_resolved = vault_root .. '/' .. decoded
            if vim.fn.filereadable(vault_resolved) == 1 then
              return vim.fn.fnamemodify(vault_resolved, ':p')
            end
            -- Otherwise fall back to document-relative resolution
            return fallback(document_path, decoded)
          end,
        },
        neorg = {
          enabled = false,
        },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = 80,
      max_height_window_percentage = 30,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
      editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
      tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
      hijack_file_patterns = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp' }, -- render image files as images when opened
    }
  end,
}
