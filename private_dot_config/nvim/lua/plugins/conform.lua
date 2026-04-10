return {
  "stevearc/conform.nvim",
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      nix = { "alejandra" },
      markdown = { "dprint" },
      ["markdown.mdx"] = { "dprint" },
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
  },
}
