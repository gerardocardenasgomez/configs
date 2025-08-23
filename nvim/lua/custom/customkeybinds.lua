local telescope = require 'telescope.builtin'

local function open_files_with_cword()
  local word_under_cursor = vim.fn.expand '<cword>'
  word_under_cursor = word_under_cursor:gsub('["\']', '')
  telescope.find_files {
    -- default_selection_index = 1,
    -- find_command = { 'fd', word_under_cursor },
    default_text = word_under_cursor,
  }
end

vim.keymap.set('n', '<leader>jj', '<cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>jf', '<cmd>bprev<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<leader>jk', '<cmd>bdel<CR>', { desc = 'Delete buffer' })

vim.keymap.set('n', '<leader>gf', open_files_with_cword, { desc = 'Go to file under cursor (Telescope)', noremap = true, silent = false })
vim.keymap.set('n', '<leader>ff', telescope.find_files, { desc = 'Find Files (Telescope)' })

vim.keymap.set('n', '<leader>sn', function()
  telescope.find_files { cwd = vim.fn.stdpath 'config' }
end)
