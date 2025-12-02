-- disable signature_help for noice.nvim
return {
  "folke/noice.nvim",
  optional = true,
  opts = {
    lsp = {
      signature = {
        enabled = false,
      },
    },
  },
}
