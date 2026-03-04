return {
  'lervag/vimtex',
  lazy = false,
  init = function()
    -- Use Skim as PDF viewer on macOS
    vim.g.vimtex_view_method = 'skim'

    -- Use latexmk for compilation
    vim.g.vimtex_compiler_method = 'latexmk'

    -- Enable conceal for better readability (e.g. \alpha -> α)
    vim.opt.conceallevel = 2
  end,
}
