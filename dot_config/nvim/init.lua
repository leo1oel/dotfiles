local base_path = vim.env.PATH

local function set_python_host()
  local cwd = vim.fn.getcwd()
  local venv = cwd .. "/.venv"

  vim.env.PATH = base_path
  vim.env.VIRTUAL_ENV = nil

  if vim.fn.isdirectory(venv) == 1 then
    vim.env.VIRTUAL_ENV = venv
    vim.env.PATH = venv .. "/bin:" .. base_path
    vim.g.python3_host_prog = venv .. "/bin/python"
    return
  end

  local pyenv_python = vim.fn.expand("$HOME/.pyenv/versions/py3nvim/bin/python")
  if vim.fn.executable(pyenv_python) == 1 then
    vim.g.python3_host_prog = pyenv_python
    return
  end

  if vim.fn.executable("python3") == 1 then
    vim.g.python3_host_prog = vim.fn.exepath("python3")
  end
end

set_python_host()
vim.api.nvim_create_autocmd("DirChanged", { callback = set_python_host })

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
