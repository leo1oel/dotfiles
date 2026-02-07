return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle left reveal<cr>", desc = "Explorer" },
    },
    init = function()
      vim.cmd([[
        augroup dotfiles_auto_explorer
          autocmd!
          autocmd VimEnter * if argc() > 0 | Neotree show left reveal | endif
        augroup END
      ]])
    end,
    opts = {
      close_if_last_window = false,
      filesystem = {
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
