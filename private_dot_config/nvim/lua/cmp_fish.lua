-- This lua script uses fish's `complete` command and maps its output for in-editor completion
-- contrib: 🤖gemini-pro-3 (most of it, few edits)

local source = {}

source.new = function()
  return setmetatable({}, { __index = source })
end

source.get_trigger_characters = function()
  return { " ", "/", "-", ".", "!" }
end

source.complete = function(self, request, callback)
  local line = request.context.cursor_line
  local col = request.context.cursor.col

  -- Find the start of the shell command after the last '!'
  local cmd_start = 1
  local current_pos = 1
  while true do
    local bang_pos = line:find("!", current_pos, true)
    if bang_pos then
      cmd_start = bang_pos + 1
      current_pos = bang_pos + 1
    else
      break
    end
  end

  if cmd_start == 1 and line:sub(1, 1) ~= "!" then
    return callback({ items = {}, isIncomplete = false })
  end

  if cmd_start > col then
    return callback({ items = {}, isIncomplete = false })
  end

  local shell_cmd_part = line:sub(cmd_start, col)

  if shell_cmd_part == "" then
    return callback({ items = {}, isIncomplete = false })
  end

  local cmd = string.format("fish -c \"complete -C '%s '\"", shell_cmd_part)
  local output = vim.fn.system(cmd)

  local items = {}
  if vim.v.shell_error == 0 then
    for s in output:gmatch("[^\r\n]+") do
      local parts = vim.split(s, "\t")
      local label = parts[1]
      local desc = parts[2]
      if label then
        table.insert(items, {
          label = label,
          filterText = label,
          insertText = label,
          documentation = { kind = "markdown", value = desc or "" },
          kind = 12,
        })
      end
    end
  end

  callback({ items = items, isIncomplete = false })
end

return source
