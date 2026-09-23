return {
  'lervag/vimtex',
  ft = { 'tex', 'plaintex', 'latex' },
  init = function()
    -- Use Skim as PDF viewer on macOS
    vim.g.vimtex_view_method = 'skim'
    vim.g.vimtex_view_general_viewer = 'open'
    vim.g.vimtex_view_general_options = 'skim'
    vim.g.vimtext_view_skim_activate = 1
    vim.g.vimtex_view_skim_sync = 1

    -- Use latexmk for compilation
    vim.g.vimtex_compiler_method = 'latexmk'

    -- Enable conceal for better readability (e.g. \alpha -> α)
    vim.opt.conceallevel = 2
  end,
}
