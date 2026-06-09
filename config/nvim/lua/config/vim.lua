vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Window left' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Window down' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Window up' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Window right' })

vim.keymap.set('t', '<C-h>', '<C-\\><C-n><C-w>h', { desc = 'Window left' })
vim.keymap.set('t', '<C-j>', '<C-\\><C-n><C-w>j', { desc = 'Window down' })
vim.keymap.set('t', '<C-k>', '<C-\\><C-n><C-w>k', { desc = 'Window up' })
vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-w>l', { desc = 'Window right' })

-- Matugen colorscheme + live reload when palette file changes
vim.cmd.colorscheme("matugen")

local palette_path = vim.fn.stdpath("config") .. "/lua/matugen_palette.lua"
local watcher = (vim.uv or vim.loop).new_fs_event()
if watcher then
  local reload_timer = nil
  watcher:start(palette_path, {}, function()
    vim.schedule(function()
      if reload_timer then vim.fn.timer_stop(reload_timer) end
      reload_timer = vim.defer_fn(function()
        reload_timer = nil
        package.loaded["matugen_palette"] = nil
        vim.cmd.colorscheme("matugen")
      end, 100)
    end)
  end)
end
