-- repl.lua - The beloved smart REPL child

local M = {}

-- Store REPL buffers per file path
local repl_buffers = {}

local function get_repl_command(filetype)
  local commands = {
    lua = 'lua',
    python = 'python3',
    typescript = 'deno',
    javascript = 'node',
  }

  return commands[filetype] or 'bash' -- fall back to bash idk why
end

local function create_floating_window(buf)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.6)

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' REPL ',
    title_pos = 'center',
  }

  return vim.api.nvim_open_win(buf, true, opts)
end

local function get_or_create_repl_buffer(filepath, command)
  -- Check if we already have a valid buffer for this file
  if repl_buffers[filepath] and vim.api.nvim_buf_is_valid(repl_buffers[filepath]) then
    return repl_buffers[filepath]
  end

  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_call(buf, function()
    vim.fn.termopen(command)
  end)

  repl_buffers[filepath] = buf

  return buf
end

function M.toggle_repl()
  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file == '' then
    print 'No file open!'
    return
  end

  local filetype = vim.bo.filetype
  local command = get_repl_command(filetype)

  local repl_buf = get_or_create_repl_buffer(current_file, command)

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == repl_buf then
      -- REPL is visible, close it
      vim.api.nvim_win_close(win, false)
      return
    end
  end

  -- REPL not visible, open it in floating window
  local win = create_floating_window(repl_buf)

  vim.cmd 'startinsert'
end

function M.send_to_repl()
  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file == '' then
    print 'No file open!'
    return
  end

  local lines = vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = vim.fn.mode() })

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', false)

  if #lines == 0 then
    print 'No selection!'
    return
  end

  local filetype = vim.bo.filetype
  local command = get_repl_command(filetype)
  local repl_buf = get_or_create_repl_buffer(current_file, command)

  local repl_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == repl_buf then
      repl_win = win
      break
    end
  end

  if not repl_win then
    repl_win = create_floating_window(repl_buf)
  end

  for _, line in ipairs(lines) do
    vim.api.nvim_chan_send(vim.bo[repl_buf].channel, line .. '\n')
  end

  vim.cmd 'startinsert'
end

-- Setup keymaps
function M.setup()
  vim.keymap.set('n', '<leader>tt', M.toggle_repl, { desc = 'Toggle REPL for current file' })

  vim.keymap.set('v', '<leader>tr', M.send_to_repl, { desc = 'Send selection to REPL' })

  vim.keymap.set('t', '<C-t>', function()
    vim.cmd 'stopinsert'
    vim.cmd 'close'
  end, { desc = 'Close REPL and return to file' })
end

return M
