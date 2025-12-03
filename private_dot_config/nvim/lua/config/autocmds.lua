-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Set relativenumber but preserve absolute numbers in insert mode
vim.cmd([[
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END
]])

-- Auto-trigger signature help when typing pauses in Insert mode
-- TODO: replace with blink signature_help
-- vim.api.nvim_create_autocmd("LspAttach", {
--   callback = function(args)
--     local client = vim.lsp.get_client_by_id(args.data.client_id)
--     if client and client:supports_method("textDocument/signatureHelp") then
--       vim.api.nvim_create_autocmd("CursorHoldI", {
--         buffer = args.buf,
--         callback = function()
--           vim.lsp.buf.signature_help({ silent = true, focusable = false })
--         end,
--       })
--     end
--   end,
-- })

-- Disable diagnostics for markdown and text files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "plaintext" },
  callback = function()
    vim.diagnostic.enable(false, { bufnr = 0 })
  end,
})
