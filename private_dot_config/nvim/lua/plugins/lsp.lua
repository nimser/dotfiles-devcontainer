return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.diagnostics = opts.diagnostics or {}
      
      if type(opts.diagnostics.virtual_text) ~= "table" then
        opts.diagnostics.virtual_text = {}
      end
      if type(opts.diagnostics.float) ~= "table" then
        opts.diagnostics.float = {}
      end
      
      opts.diagnostics.virtual_text.source = "always"
      opts.diagnostics.float.source = "always"

      opts.servers = opts.servers or {}
      opts.servers.oxlint = opts.servers.oxlint or {}
      opts.servers.oxlint.on_new_config = function(new_config, new_root_dir)
        local local_config = vim.fs.find({ ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" }, { path = new_root_dir, upward = true })[1]
        
        if not local_config then
          new_config.cmd = new_config.cmd or { "oxc_language_server" }
          
          local has_config = false
          for _, arg in ipairs(new_config.cmd) do
            if arg:match("^--config") then
              has_config = true
              break
            end
          end
          
          if not has_config then
            table.insert(new_config.cmd, "--config=" .. vim.fn.expand("~/.config/oxc/.oxlintrc.jsonc"))
          end
        end
      end
    end,
  },
}