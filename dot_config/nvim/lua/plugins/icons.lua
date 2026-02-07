return {
  {
    "echasnovski/mini.icons",
    enabled = false,
  },
  {
    "nvim-tree/nvim-web-devicons",
    opts = {
      color_icons = true,
      default = true,
      strict = true,
      override_by_extension = {
        log = {
          icon = "\u{f0f6}",
          color = "#F6C177",
          name = "Log",
        },
        env = {
          icon = "\u{f462}",
          color = "#9CCFD8",
          name = "Env",
        },
        md = {
          icon = "\u{f48a}",
          color = "#89B4FA",
          name = "Markdown",
        },
      },
      override_by_filename = {
        [".env"] = {
          icon = "\u{f462}",
          color = "#9CCFD8",
          name = "DotEnv",
        },
        ["Dockerfile"] = {
          icon = "\u{f308}",
          color = "#89B4FA",
          name = "Dockerfile",
        },
      },
    },
  },
}
