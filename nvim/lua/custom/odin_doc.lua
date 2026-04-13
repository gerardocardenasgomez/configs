-- ~/.config/nvim/lua/odin_doc.lua

local M = {}

local output_win = nil
local output_buf = nil

local function get_odin_root()
  return vim.fn.system('odin root'):gsub('%s+$', '')
end

local function resolve_package(alias, bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for _, line in ipairs(lines) do
    -- matches: import "core:net" OR import net "core:net"
    local pkg = line:match('import%s+' .. alias .. '%s+"([^"]+)"') or (alias == nil and line:match 'import%s+"([^"]+)"')
    if not pkg then
      -- also match bare: import "core:net" where alias == package leaf
      local bare = line:match 'import%s+"(core:[^"]+)"'
      if bare then
        local leaf = bare:match 'core:(.+)$'
        if leaf == alias then
          pkg = bare
        end
      end
    end
    if pkg then
      return pkg
    end
  end
  return nil
end

local function pkg_to_path(pkg)
  local root = get_odin_root()
  -- core:net -> /odin_root/core/net
  return pkg:gsub(':', '/'):gsub('^', root .. '/')
end

local function close_output_window()
  if output_win and vim.api.nvim_win_is_valid(output_win) then
    vim.api.nvim_win_close(output_win, true)
    output_win = nil
  end
end

local function create_float()
  close_output_window()
  local buf = vim.api.nvim_create_buf(false, true)
  output_buf = buf

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.5)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = 'rounded',
  })
  output_win = win

  -- q to close
  vim.keymap.set('n', 'q', close_output_window, { buffer = buf, silent = true })
  return buf, win
end

local function show_doc()
  local word = vim.fn.expand '<cword>'
  -- try to grab the package prefix from the full WORD (e.g. "net.listen_tcp")
  local full = vim.fn.expand '<cWORD>'
  local alias = full:match '^([%w_]+)%.'

  if not alias then
    vim.notify('No package prefix found (expected: pkg.Symbol)', vim.log.levels.WARN)
    return
  end

  local pkg = resolve_package(alias, vim.api.nvim_get_current_buf())
  if not pkg then
    vim.notify('Could not resolve import for: ' .. alias, vim.log.levels.WARN)
    return
  end

  local path = pkg_to_path(pkg)
  local cmd = string.format('odin doc %s 2>&1', path)

  local buf, _ = create_float()

  vim.fn.jobstart({ 'sh', '-c', cmd }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
        -- jump to the symbol in the doc
        vim.fn.search(word, 'w')
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
      end
    end,
  })
end

M.show_doc = show_doc
M.close = close_output_window

return M
