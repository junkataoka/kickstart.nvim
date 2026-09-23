return {
  'saghen/blink.cmp',
  version = '1.*', -- release tags ship a prebuilt Rust fuzzy matcher
  event = { 'InsertEnter', 'CmdlineEnter' },
  dependencies = {
    {
      'L3MON4D3/LuaSnip',
      version = '2.*',
      build = (function()
        if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
          return
        end
        return 'make install_jsregexp'
      end)(),
    },
  },
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = 'none',
      ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-e>'] = { 'hide', 'fallback' }, -- falls through to copilot dismiss
      ['<C-y>'] = { 'select_and_accept', 'fallback' },
      ['<Tab>'] = { 'select_and_accept', 'fallback' },
      ['<C-n>'] = { 'select_next', 'fallback' },
      ['<C-p>'] = { 'select_prev', 'fallback' },
      ['<Down>'] = { 'select_next', 'fallback' },
      ['<Up>'] = { 'select_prev', 'fallback' },
      ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
      ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
      ['<C-l>'] = { 'snippet_forward', 'fallback' },
      ['<C-h>'] = { 'snippet_backward', 'fallback' },
    },
    appearance = { nerd_font_variant = 'mono' },
    completion = {
      list = { selection = { preselect = true, auto_insert = false } },
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      menu = {
        draw = {
          columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'source_name' } },
        },
      },
      ghost_text = { enabled = false }, -- copilot.lua owns inline ghost text
    },
    signature = { enabled = false }, -- noice renders signature help
    snippets = { preset = 'luasnip' },
    sources = {
      default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
      providers = {
        lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
      },
    },
    cmdline = {
      keymap = { preset = 'cmdline' },
      completion = { menu = { auto_show = true } },
    },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
  },
  opts_extend = { 'sources.default' },
}
