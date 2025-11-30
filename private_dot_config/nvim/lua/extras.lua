local extras = {
  { import = "lazyvim.plugins.extras.lang.markdown" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
  { import = "lazyvim.plugins.extras.lang.toml" },
}

local function is_js_project(path)
  local indicators = {
    "package.json",
    "tsconfig.json",
    "jsconfig.json",
    "deno.json",
    "deno.jsonc",
    ".eslintrc.json",
    ".eslintrc.js",
  }
  for _, indicator in ipairs(indicators) do
    if (vim.uv or vim.loop).fs_stat(path .. "/" .. indicator) then
      return true
    end
  end
  return false
end

-- Check current directory, /workspaces, or git root for JS/TS indicators
local cwd = vim.fn.getcwd()
local root = vim.fs.find(".git", { path = cwd, upward = true })[1]
local git_root = root and vim.fn.fnamemodify(root, ":h") or nil

if is_js_project(cwd) or is_js_project("/workspaces") or (git_root and is_js_project(git_root)) then
  table.insert(extras, { import = "lazyvim.plugins.extras.lang.typescript" })
end

return extras
