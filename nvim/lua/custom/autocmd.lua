local output_win = nil

local function get_exec_cmd(filetype)
	if filetype == "typescript" then
		return "npx tsc --noEmit %s && bun %s"
	elseif filetype == "python" then
		return "python3 %s"
	elseif filetype == "go" then
		return "go run %s"
	elseif filetype == "lua" then
		return "lua %s"
	end
end

local function close_output_window()
	if output_win and vim.api.nvim_win_is_valid(output_win) then
		vim.api.nvim_win_close(output_win, false)
		output_win = nil
	end
end

local function get_buf_by_name(bname)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_name(buf):match(bname) then
			return buf
		end
	end

	return nil
end

local function get_or_create_output_buffer()
	local result = get_buf_by_name("tsc_autocmd")

	if result then
		return result
	end

	return vim.api.nvim_create_buf(false, true)
end

local function create_floating_window()
	local buf = get_or_create_output_buffer()
	vim.api.nvim_buf_set_name(buf, "tsc_autocmd")
	vim.api.nvim_buf_call(buf, function()
		vim.cmd("edit " .. "tsc_autocmd")
	end)

	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.3)

	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = vim.o.lines - math.floor((vim.o.lines * 0.3) - 2),
		style = "minimal",
		border = "rounded",
	}

	local win = vim.api.nvim_open_win(buf, false, opts)
	output_win = win
	return buf, win
end

local function run_ts_file()
	local filepath = vim.api.nvim_buf_get_name(0)
	local bufnr, _ = create_floating_window()
	local filetype = vim.bo.filetype
	local cmd = get_exec_cmd(filetype)

	vim.fn.jobstart({ "sh", "-c", string.format(cmd, filepath, filepath) }, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, data)
			end
		end,
		on_stderr = function(_, data)
			if data then
				vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
			end
		end,
	})
end

vim.keymap.set("n", "<leader>xx", run_ts_file, { desc = "Execute Current File (Python, Typescript, Lua, Go)" })
vim.keymap.set("n", "<leader>XX", close_output_window)
