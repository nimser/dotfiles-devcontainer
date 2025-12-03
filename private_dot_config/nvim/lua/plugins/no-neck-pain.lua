return {
  "shortcuts/no-neck-pain.nvim",
  version = "*",
  event = "VeryLazy",
  keys = { { "<leader>r", "<cmd>NoNeckPain<cr>", desc = "Reader mode" } },
  config = function()
    local nnp_augroup = vim.api.nvim_create_augroup("NoNeckPainAutoEnable", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "text" },
      group = nnp_augroup,
      callback = function()
        -- Ensure _G.NoNeckPain.state exists before checking enabled status
        if _G.NoNeckPain and _G.NoNeckPain.state and not _G.NoNeckPain.state.enabled then
          vim.cmd("NoNeckPain")
        end
      end,
      desc = "Automatically enable NoNeckPain for markdown and text files.",
    })
  end,
}
