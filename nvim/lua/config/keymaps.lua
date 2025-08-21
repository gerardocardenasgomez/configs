-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = LazyVim.safe_keymap_set
local telescope = require("telescope.builtin")

local function open_files_with_cword()
  local word_under_cursor = vim.fn.expand("<cword>")
  print(word_under_cursor)
  telescope.find_files({
    default_selection_index = 1,
    find_command = { "fd", word_under_cursor },
  })
end

map("n", "<leader>jj", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>jf", "<cmd>bprev<CR>", { desc = "Previous buffer" })
map("n", "<leader>jk", "<cmd>bdel<CR>", { desc = "Delete buffer" })

map(
  "n",
  "<leader>gf",
  open_files_with_cword,
  { desc = "Go to file under cursor (Telescope)", noremap = true, silent = false }
)
map("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "Find Files (Telescope)" })
