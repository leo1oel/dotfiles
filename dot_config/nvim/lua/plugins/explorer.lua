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
      { "<leader>e", "<cmd>Neotree toggle left reveal filesystem<cr>", desc = "Explorer (Neo-tree)" },
    },
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    opts = {
      close_if_last_window = false,
      default_component_configs = {
        icon = {
          folder_closed = "\u{f07b}",
          folder_open = "\u{f07c}",
          folder_empty = "\u{f115}",
          default = "\u{f15b}",
        },
        git_status = {
          symbols = {
            added = "\u{f067}",
            modified = "\u{f044}",
            deleted = "✖",
            renamed = "󰁕",
            untracked = "\u{f128}",
            ignored = "\u{f05e}",
            unstaged = "\u{f06a}",
            staged = "\u{f00c}",
            conflict = "\u{f071}",
          },
        },
      },
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
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        enabled = false,
      },
    },
  },
}
