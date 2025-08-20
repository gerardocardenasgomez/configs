-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("notervim").setup()
require("repl").setup()
vim.lsp.enable("pyright")
