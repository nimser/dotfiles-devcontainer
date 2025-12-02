return {
  -- add gruvbox
  -- { "sainnhe/gruvbox-material" },
  -- { "ellisonleao/gruvbox.nvim" }, -- too vivid but good features
  { "catppuccin/nvim" },
  -- { "folke/tokyonight.nvim"},

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-macchiato",
    },
  },
}
