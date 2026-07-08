return {
  "stevearc/conform.nvim",
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      fish = { "fish_indent" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      json = { "dprint" },
      jsonc = { "dprint" },
      markdown = { "dprint" },
      ["markdown.mdx"] = { "dprint" },
      toml = { "dprint" },
      yaml = { "dprint" },
      yml = { "dprint" },
      dockerfile = { "dprint" },
      nix = { "alejandra" },
    },
    default_format_opts = {
      lsp_format = "fallback",
      -- dprint JIT-compiles its WASM plugins on first use (~6s cold for the full
      -- global-config set), then caches them (~0.15s warm). The default 1000ms
      -- timeout aborts that first compile before the cache is written, so every
      -- save keeps timing out. A generous timeout absorbs the one-time cold compile.
      timeout_ms = 10000,
    },
    formatters = {
      shfmt = {
        prepend_args = { "-i", "2", "-ci", "-bn" },
      },
      dprint = {
        require_cwd = false,
        prepend_args = function(self, ctx)
          local local_config = vim.fs.find({ "dprint.json", ".dprint.json", "dprint.jsonc", ".dprint.jsonc" }, { path = ctx.dirname, upward = true })[1]
          if local_config then
            return {}
          else
            return { "--config", vim.fn.expand("~/.config/dprint/.dprint.jsonc") }
          end
        end,
      },
      oxfmt = {
        require_cwd = false,
        prepend_args = function(self, ctx)
          local local_config = vim.fs.find({ ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" }, { path = ctx.dirname, upward = true })[1]
          if local_config then
            return {}
          else
            return { "--config", vim.fn.expand("~/.config/oxc/.oxfmtrc.jsonc") }
          end
        end,
      },
    },
  },
}
