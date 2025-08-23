-- notervim.lua - The beloved note taking nvim app

local M = {}

local function get_timestamp()
  return os.date '%Y-%m-%d-%H-%M-%S'
end

local function create_floating_window(buf)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = 'rounded',
  }

  return vim.api.nvim_open_win(buf, true, opts)
end

local function create_note(title, code_snippet, file_location)
  local timestamp = get_timestamp()
  local filename = string.format('notes-%s.md', timestamp)
  local filepath = vim.fn.expand('~/Notes/' .. filename)

  -- template
  local content = {}
  table.insert(content, string.format('# %s %s', title, timestamp))

  if file_location then
    table.insert(content, string.format('Location: %s', file_location))
  end

  table.insert(content, 'Tags: ')
  table.insert(content, '')

  if code_snippet and #code_snippet > 0 then
    local filetype = vim.bo.filetype
    if filetype == '' then
      filetype = 'text'
    end

    table.insert(content, string.format('```%s', filetype))
    for _, line in ipairs(code_snippet) do
      table.insert(content, line)
    end
    table.insert(content, '```')
    table.insert(content, '')
  end

  vim.fn.writefile(content, filepath)

  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(buf, filepath)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('edit ' .. filepath)
  end)

  local win = create_floating_window(buf)

  -- set cursor at a good spot
  vim.api.nvim_win_set_cursor(win, { 1, 2 })

  return buf, win
end

function M.create_code_note_with_data(lines, current_file)
  create_note('NOTES', lines, current_file)
end

function M.create_text_note(title)
  local note_title = title == '' and 'Notes' or title
  create_note(note_title)
end

function M.setup()
  vim.keymap.set('v', '<leader>mm', function()
    local lines = vim.fn.getregion(vim.fn.getpos '.', vim.fn.getpos 'v', { type = vim.fn.mode() })

    local current_file = vim.api.nvim_buf_get_name(0)

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', false)

    M.create_code_note_with_data(lines, current_file)
  end, { desc = 'Create code note from selection' })

  vim.api.nvim_create_user_command('Notervim', function(opts)
    M.create_text_note(opts.args)
  end, { nargs = '*', desc = 'Create a new note' })
end

return M
