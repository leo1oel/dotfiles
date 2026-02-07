return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "ty",
        "ruff",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ty = {},
        ruff = {},
      },
    },
  },
}
