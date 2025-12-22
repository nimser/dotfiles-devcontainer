return {
  -- add gruvbox
  -- { "sainnhe/gruvbox-material" },
  -- { "ellisonleao/gruvbox.nvim" }, -- too vivid but good features
  { "f4z3r/gruvbox-material.nvim" },
  { "ellisonleao/gruvbox.nvim" },
  { "catppuccin/nvim" },
  { "folke/tokyonight.nvim" },
  { "neanias/everforest-nvim" },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-moon",
    },
  },
}
