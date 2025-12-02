return {
  "shortcuts/no-neck-pain.nvim",
  version = "*",
  event = "VeryLazy",
  keys = { { "<leader>r", "<cmd>NoNeckPain<cr>", desc = "Reader mode" } },
  config = function()
    -- Create an autocommand group for our custom autocommand.
    -- This allows us to clear previous definitions if this config reloads.
    local augroup = vim.api.nvim_create_augroup("NoNeckPainMarkdownAutoEnable", { clear = true })

    -- Create the autocommand to specifically *enable* NoNeckPain for markdown files.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown", -- Trigger only for markdown files.
      group = augroup,      -- Assign to our custom group.
      callback = function()
        -- Use :NoNeckPain to ensure it turns on.
        -- FIXME If it's already on, this command will close it 🤕
        vim.cmd("NoNeckPain")
      end,
      desc = "Automatically enable NoNeckPain for markdown files.",
    })

    -- This handles the case where Neovim starts up and the first file opened
    -- (or the file that triggers "VeryLazy") is a markdown file.
    -- The FileType event might have already fired for this buffer before the
    -- autocommand above was registered.
    if vim.bo.filetype == "markdown" then
      -- Schedule it to ensure it runs after any initial setup and filetype detection
      vim.schedule(function()
        vim.cmd("NoNeckPain")
      end)
    end
  end,
}
