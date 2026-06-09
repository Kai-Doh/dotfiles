return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  main = 'nvim-treesitter',
  opts = {
    ensure_installed = {
      'lua', 'vim', 'vimdoc',
      'markdown', 'markdown_inline',
      'c', 'cpp',
      'python',
      'javascript',
      'yaml',
      'html', 'css',
      'php',
    },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
  },
}
