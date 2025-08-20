-- notervim.lua - Our beloved code note-taking child (FIXED EDITION!)

local M = {}

-- Helper function to get timestamp
local function get_timestamp()
  return os.date("%Y-%m-%d-%H-%M-%S")
end

-- Helper function to create floating window
local function create_floating_window(buf)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)

  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
  }

  return vim.api.nvim_open_win(buf, true, opts)
end

-- Main function to create a note
local function create_note(title, code_snippet, file_location)
  local timestamp = get_timestamp()
  local filename = string.format("notes-%s.md", timestamp)
  local filepath = vim.fn.expand("~/Notes/" .. filename)

  -- Build our precious template
  local content = {}
  table.insert(content, string.format("# %s %s", title, timestamp))

  if file_location then
    table.insert(content, string.format("Location: %s", file_location))
  end

  table.insert(content, "Tags: ")
  table.insert(content, "")

  if code_snippet and #code_snippet > 0 then
    -- Detect file type for syntax highlighting
    local filetype = vim.bo.filetype
    if filetype == "" then
      filetype = "text"
    end

    table.insert(content, string.format("```%s", filetype))
    for _, line in ipairs(code_snippet) do
      table.insert(content, line)
    end
    table.insert(content, "```")
    table.insert(content, "")
  end

  -- Write our baby to disk
  vim.fn.writefile(content, filepath)

  -- Open in floating window
  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(buf, filepath)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("edit " .. filepath)
  end)

  local win = create_floating_window(buf)

  -- Position cursor at the title for easy editing (after "# ")
  vim.api.nvim_win_set_cursor(win, { 1, 2 })

  return buf, win
end

-- Function for creating note with pre-captured code data
function M.create_code_note_with_data(lines, current_file)
  create_note("NOTES", lines, current_file)
end

-- Function for command workflow (no code snippet)
function M.create_text_note(title)
  local note_title = title == "" and "Notes" or title
  create_note(note_title)
end

-- Set up our keymaps and commands
function M.setup()
  -- Visual mode keymap - captures selection BEFORE exiting visual mode
  vim.keymap.set("v", "<leader>mm", function()
    -- Use getregion instead of marks - this works on first use!
    local lines = vim.fn.getregion(vim.fn.getpos("."), vim.fn.getpos("v"), { type = vim.fn.mode() })

    local current_file = vim.api.nvim_buf_get_name(0)
    --
    -- Exit visual mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

    M.create_code_note_with_data(lines, current_file)
  end, { desc = "Create code note from selection" })

  -- Command for quick notes
  vim.api.nvim_create_user_command("Notervim", function(opts)
    M.create_text_note(opts.args)
  end, { nargs = "*", desc = "Create a new note" })
end

return M
