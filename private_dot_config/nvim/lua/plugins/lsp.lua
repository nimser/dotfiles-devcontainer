return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = {
          source = "always",
        },
        float = {
          source = "always",
        },
      },
    },
  },
}