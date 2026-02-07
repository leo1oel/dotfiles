return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle left reveal<cr>", desc = "Explorer" },
    },
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      vim.cmd([[
        augroup dotfiles_auto_explorer
          autocmd!
          autocmd VimEnter * if argc() > 0 && isdirectory(argv(0)) | Neotree show left reveal | endif
        augroup END
      ]])
    end,
    opts = {
      close_if_last_window = false,
      filesystem = {
        hijack_netrw_behavior = "open_default",
        follow_current_file = { enabled = true },
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        window = {
          position = "left",
          width = 34,
          mappings = {
            ["/"] = "fuzzy_finder",
            ["f"] = "filter_on_submit",
            ["<c-x>"] = "clear_filter",
          },
        },
      },
    },
  },
}
