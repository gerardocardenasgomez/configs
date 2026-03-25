-- lua/customtabs/indentation.lua

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

vim.api.nvim_create_autocmd('FileType', {
  pattern = {
    'python',
    'rst',
    'yaml',
    'yml',
    'json',
    'markdown',
    'md',
  },
  callback = function()
    vim.opt.shiftwidth = 4
    vim.opt.tabstop = 4
    vim.opt.softtabstop = 4
  end,
  desc = 'Set 4-space indentation for common file types',
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = {
    'javascript',
    'typescript',
    'javascriptreact',
    'typescriptreact',
    'jsonc',
    'lua',
    'html',
    'css',
    'scss',
    'less',
    'vue',
    'svelte',
    'java',
    'c',
    'cpp',
    'go',
    'rust',
    'toml',
    'php',
    'ruby',
    'hcl',
    'sh',
  },
  callback = function()
    vim.opt.shiftwidth = 2
    vim.opt.tabstop = 2
    vim.opt.softtabstop = 2
  end,
  desc = 'Set 2-space indentation for web/general programming languages',
})
