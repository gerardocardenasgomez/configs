-- repl.lua - Our beloved smart REPL child

local M = {}

-- Store REPL buffers per file path
local repl_buffers = {}

-- Helper function to get REPL command based on filetype
local function get_repl_command(filetype)
  local commands = {
    lua = "lua",
    python = "python3",
    typescript = "deno",
    javascript = "node",
  }

  return commands[filetype] or "bash" -- fallback to bash
end

-- Helper function to create floating window
local function create_floating_window(buf)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.6) -- Bit shorter than notes window

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " REPL ",
    title_pos = "center",
  }

  return vim.api.nvim_open_win(buf, true, opts)
end

-- Get or create REPL buffer for current file
local function get_or_create_repl_buffer(filepath, command)
  -- Check if we already have a valid buffer for this file
  if repl_buffers[filepath] and vim.api.nvim_buf_is_valid(repl_buffers[filepath]) then
    return repl_buffers[filepath]
  end

  -- Create new terminal buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Start the terminal in the buffer (old reliable way)
  vim.api.nvim_buf_call(buf, function()
    vim.fn.termopen(command)
  end)

  -- Store it for this file
  repl_buffers[filepath] = buf

  return buf
end

-- Toggle REPL for current file
function M.toggle_repl()
  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file == "" then
    print("No file open!")
    return
  end

  local filetype = vim.bo.filetype
  local command = get_repl_command(filetype)

  -- Get or create REPL buffer for this specific file
  local repl_buf = get_or_create_repl_buffer(current_file, command)

  -- Check if REPL is already visible in a window
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == repl_buf then
      -- REPL is visible, close it
      vim.api.nvim_win_close(win, false)
      return
    end
  end

  -- REPL not visible, open it in floating window
  local win = create_floating_window(repl_buf)

  -- Enter insert mode in terminal
  vim.cmd("startinsert")
end

-- Send visual selection to REPL (FIXED VERSION!)
function M.send_to_repl()
  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file == "" then
    print("No file open!")
    return
  end

  -- Capture visual selection WHILE still in visual mode (our proven method!)
  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })

  -- Exit visual mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  if #lines == 0 then
    print("No selection!")
    return
  end

  -- Get or create REPL buffer (auto-create if needed!)
  local filetype = vim.bo.filetype
  local command = get_repl_command(filetype)
  local repl_buf = get_or_create_repl_buffer(current_file, command)

  -- Make sure REPL window is visible
  local repl_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == repl_buf then
      repl_win = win
      break
    end
  end

  -- If REPL not visible, open it!
  if not repl_win then
    repl_win = create_floating_window(repl_buf)
  end

  -- Send each line to the terminal
  for _, line in ipairs(lines) do
    vim.api.nvim_chan_send(vim.bo[repl_buf].channel, line .. "\n")
  end

  vim.cmd("startinsert")
  -- Optional: focus back to your code file instead of staying in REPL
  -- vim.cmd('wincmd p')  -- uncomment if you want to return focus to code
end

-- Setup keymaps
function M.setup()
  -- Toggle REPL for current file
  vim.keymap.set("n", "<leader>tt", M.toggle_repl, { desc = "Toggle REPL for current file" })

  -- Send visual selection to REPL
  vim.keymap.set("v", "<leader>tr", M.send_to_repl, { desc = "Send selection to REPL" })

  vim.keymap.set("t", "<C-t>", function()
    -- Exit terminal mode and close the floating window
    vim.cmd("stopinsert")
    vim.cmd("close")
  end, { desc = "Close REPL and return to file" })
end

return M
