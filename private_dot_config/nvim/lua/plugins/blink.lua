return {
  {
    "saghen/blink.cmp",
    dependencies = {
      "saghen/blink.compat",
    },
    opts = function(_, opts)
      -- Ensure providers table exists
      opts.sources = opts.sources or {}
      opts.sources.providers = opts.sources.providers or {}
      -- Define the 'fish' provider
      opts.sources.providers.fish = {
        name = "fish",
        module = "blink.compat.source",
        score_offset = 100,
      }

      -- Enable cmdline and add 'fish' to sources
      opts.cmdline = opts.cmdline or {}
      opts.cmdline.enabled = true
      opts.cmdline.sources = function()
        return { "fish", "cmdline", "path" }
      end

      -- Register the source
      local has_cmp, cmp = pcall(require, "cmp")
      if has_cmp then
        cmp.register_source("fish", require("cmp_fish").new())
      end
    end,
  },
}
