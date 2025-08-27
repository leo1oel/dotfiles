-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- see :help provider-python to set up a virtualenv using pyenv
vim.g.python3_host_prog = vim.fn.expand("$HOME/.pyenv/versions/py3nvim/bin/python")

-- The last time I used perl was in the last century.
vim.g.loaded_perl_provider = 0

-- Default editor behaviour
vim.opt.tabstop = 4 
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

