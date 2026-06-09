return {
  'coder/claudecode.nvim',
  config = function()
    require('claudecode').setup()
    vim.keymap.set('n', '<leader>cc', ':ClaudeCode<CR>', {})
    vim.keymap.set('v', '<leader>cs', ':ClaudeCodeSend<CR>', {})
  end,
}
