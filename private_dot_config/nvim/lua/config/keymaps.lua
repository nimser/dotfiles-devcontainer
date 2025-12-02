-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- CONSTANTS
local ZETTELKASTEN_PATH = vim.fn.expand("~/Sync/00 Zettelkasten/")
local JOURNAL_PATH = ZETTELKASTEN_PATH .. "Journal/"
local JOURNAL_TEMPLATE_PATH = ZETTELKASTEN_PATH .. "ZZ_Resources/Templates/Daily note template.md"

-- HELPERS
local map = function(mode, lhs, rhs, opts)
  local options = { noremap = true } -- set mappings to non-recursive by default
  if opts then options = vim.tbl_extend("force", options, opts) end
  vim.keymap.set(mode, lhs, rhs, options)
end
local edit_day_journal = function(opts)
  local is_next_day = opts and opts.next_day or false
  local timestamp
  if is_next_day then
    timestamp = os.time() + (24 * 60 * 60)
  else
    timestamp = os.time()
  end
  local date_str = os.date("%B %d, %Y (%A)", timestamp)
  local filename_to_open = JOURNAL_PATH .. date_str .. ".md"
  local escaped_filename = vim.fn.fnameescape(filename_to_open)
  -- If it's a new file, we'll need to load the template content in it
  local file_exists = (vim.fn.filereadable(filename_to_open) == 1)
  vim.schedule(function()
    vim.cmd("tabe " .. escaped_filename)
    if not file_exists then
      local template_lines = vim.fn.readfile(JOURNAL_TEMPLATE_PATH)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, template_lines)
      vim.cmd("silent! w")
    end
  end)
end
local edit_vim_memo = function()
  vim.cmd("tabe " .. vim.fn.fnameescape(ZETTELKASTEN_PATH .. 'Zettelkasten/vim-memo.md'))
end


-- Command line abbreviations
local cnoreabbrev = vim.cmd.cnoreabbrev

-- For reference (NOTE: "nore" in e.g. noremap means "not recursive")
--                                                     *map-table*
--  Mode (Lua arg)| Norm | Ins | Cmd | Vis | Sel | Opr | Term | Lang | ~
-- Command        +------+-----+-----+-----+-----+-----+------+------+ ~
-- [nore]map  ""  | yes  |  -  |  -  | yes | yes | yes |  -   |  -   |
-- n[nore]map "n" | yes  |  -  |  -  |  -  |  -  |  -  |  -   |  -   |
-- [nore]map! "!" |  -   | yes | yes |  -  |  -  |  -  |  -   |  -   |
-- i[nore]map "i" |  -   | yes |  -  |  -  |  -  |  -  |  -   |  -   |
-- c[nore]map "c" |  -   |  -  | yes |  -  |  -  |  -  |  -   |  -   |
-- v[nore]map "v" |  -   |  -  |  -  | yes | yes |  -  |  -   |  -   |
-- x[nore]map "x" |  -   |  -  |  -  | yes |  -  |  -  |  -   |  -   |
-- s[nore]map "s" |  -   |  -  |  -  |  -  | yes |  -  |  -   |  -   |
-- o[nore]map "o" |  -   |  -  |  -  |  -  |  -  | yes |  -   |  -   |
-- t[nore]map "t" |  -   |  -  |  -  |  -  |  -  |  -  | yes  |  -   |
-- l[nore]map "l" |  -   | yes | yes |  -  |  -  |  -  |  -   | yes  |

-- Disable unwanted LazyVim behaviour
-- restore Neovim 0.11 signature_help
vim.keymap.del({ "i", "s", "n" }, "<C-s>")
map({ "i", "s" }, "<C-s>", function() vim.lsp.buf.signature_help() end, { desc = "Signature Help" })
map('n', '<C-s>', '<Plug>(nvim.lsp.ctrl-s)')

-- Add empty lines before and after cursor line
map("n", "<S-CR>", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>")
map("n", "<CR>", "<Cmd>call append(line('.'),     repeat([''], v:count1))<CR>")
-----> Command mappings and abbrevs <------
cnoreabbrev("W", "w")
-----> Multi-mode mappings <------
map("", "gf", "<c-w>gF") -- open the file under cursor in a new tab (considering line number in link)
map("", "gF", "<c-w>gf") -- open the file under cursor in a new tab (ignoring line numbers)
-----> Normal mappings <------
map("n", "<leader>w", ":update<cr>")
map("n", "<c-w>t", ":tabe<cr>")
-- next / prev tab
map("n", "gb", "gT")
map("n", "gw", "gt")
-- favorite files shortcuts
map("n", "<localleader>ei", ":tabe ~/.local/share/chezmoi/private_dot_config/i3/config<cr>", { desc = "Edit i3 config" })
map("n", "<localleader>et", function() edit_day_journal() end, { desc = "Edit today's daily note" })
map("n", "<localleader>en", function() edit_day_journal({ next_day = true }) end, { desc = "Edit next day's note" })
map("n", "<localleader>em", function() edit_vim_memo() end, { desc = "Edit vim memo" })
map("n", "<localleader>ew", ":tabe ~/Sync/Freelance/workflow-improvement.md<cr>", { desc = "Edit workflow improvements" })
map("n", "<localleader>ek", ":tabe ~/qmk_firmware/keyboards/centromere/keymaps/nimser/keymap.c<cr>",
  { desc = "Edit keyboard keymap file" })
-- print/copy current file path
map("n", "<localleader>p", function() print(vim.fn.expand("%:p")) end, { desc = "Print file path" })
map("n", "<localleader>yp", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end, { desc = "Copy file path" })
-- Scroll up down with cursor staying inplace
map({ 'n', 'i' }, "<C-Up>", "<C-y>", { desc = "Scroll window up " })
map({ 'n', 'i' }, "<C-Down>", "<C-e>", { desc = "Scroll windown down" })
-- Move Lines
map("n", "<A-Down>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-Up>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-Down>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-Up>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-Down>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-Up>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })
-- Move to window using the <ctrl> hjkl keys
-- TODO: don't use neovim to manage windows (switch to e.g. tmux)
map("n", "<C-Left>", "<C-w>h", { desc = "Go to Left Window", remap = true })
--map("n", "<C-Down>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
--map("n", "<C-Up>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-Right>", "<C-w>l", { desc = "Go to Right Window", remap = true })
--
--Resize window using <S> + arrow keys
map("n", "<S-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<S-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<S-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<S-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })
