return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  cmd = { 'LspInfo', 'LspInstall', 'LspUninstall', 'Mason' },
  dependencies = {
    { 'williamboman/mason.nvim', opts = {} },
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    { 'j-hui/fidget.nvim', opts = {} },
    'hrsh7th/cmp-nvim-lsp',
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode, opts)
          mode = mode or 'n'
          opts = vim.tbl_extend('force', { buffer = event.buf, desc = 'LSP: ' .. desc }, opts or {})
          vim.keymap.set(mode, keys, func, opts)
        end

        local pick = function(name)
          return function()
            Snacks.picker[name]()
          end
        end

        map('gd', pick 'lsp_definitions', '[G]oto [D]efinition')
        map('gD', pick 'lsp_declarations', '[G]oto [D]eclaration')
        -- nowait: avoid timeoutlen delay from Neovim's default grr/gri/gra maps
        map('gr', pick 'lsp_references', '[G]oto [R]eferences', 'n', { nowait = true })
        map('gI', pick 'lsp_implementations', '[G]oto [I]mplementation')
        map('gy', pick 'lsp_type_definitions', '[G]oto T[y]pe Definition')
        map('<leader>D', pick 'lsp_type_definitions', 'Type [D]efinition')
        map('gai', pick 'lsp_incoming_calls', 'C[a]lls [I]ncoming (callers)')
        map('gao', pick 'lsp_outgoing_calls', 'C[a]lls [O]utgoing (callees)')
        map('<leader>ds', pick 'lsp_symbols', '[D]ocument [S]ymbols')
        map('<leader>ws', pick 'lsp_workspace_symbols', '[W]orkspace [S]ymbols')
        map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        map('<leader>la', vim.lsp.buf.code_action, '[L]SP Code [A]ction', { 'n', 'x' })
        map('<leader>e', vim.diagnostic.open_float, 'Open [E]rror')

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    if vim.g.have_nerd_font then
      local signs = { ERROR = '', WARN = '', INFO = '', HINT = '' }
      local diagnostic_signs = {}
      for type, icon in pairs(signs) do
        diagnostic_signs[vim.diagnostic.severity[type]] = icon
      end
      vim.diagnostic.config {
        signs = { text = diagnostic_signs },
        virtual_text = { current_line = true },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          scope = 'line',
          border = 'rounded',
          source = true,
          header = '',
          prefix = '',
        },
      }
    end

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
          },
        },
      },
      pyright = {
        root_markers = {
          { 'pyrightconfig.json', 'pyproject.toml', 'setup.py', 'setup.cfg' },
          { '.git' },
          { 'requirements.txt', 'Pipfile' },
        },
      },
      jsonls = {},
    }

    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua',
      'ruff',
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    vim.lsp.config('*', { capabilities = capabilities })
    for server_name, server in pairs(servers) do
      vim.lsp.config(server_name, server)
    end

    require('mason-lspconfig').setup()
  end,
}
