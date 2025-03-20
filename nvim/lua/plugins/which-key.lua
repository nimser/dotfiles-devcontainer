return {
  "folke/which-key.nvim",
  opts_extend = { "spec" },
  opts = {
    spec = {
      {
        mode = { "n", "v" },
        {
          { "<localleader>y", group = "+Copy..." },
          { "<localleader>e", group = "+Edit favorite files" },
          { "<localleader>f", group = "+Find files in specific locations" },
          { "<localleader>fe", group = "+Browse specific locations" },
          { "<localleader>g", group = "+Grep in specific locations" },
        },
      },
    },
  },
}
