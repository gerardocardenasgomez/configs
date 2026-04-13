-- ollama.lua
-- Shared Ollama client. Everything else in the ecosystem calls this.
-- Drop in ~/.config/nvim/lua/ollama.lua
--
-- Config: create ~/.nvim-ollama returning a table, e.g.:
--   return {
--     host  = "http://192.168.1.x:11434",
--     model = "codellama",
--   }
-- If file doesn't exist, falls back to localhost defaults silently.

local M = {}

-- ── config ────────────────────────────────────────────────────────────────────

local defaults = {
  host = 'http://localhost:11434',
  model = 'codellama',
}

local ok, user_config = pcall(dofile, vim.fn.expand '~/.nvim-ollama')
local config = ok and vim.tbl_deep_extend('force', defaults, user_config) or defaults

M.config = config -- expose so other modules can read model name etc if needed

-- ── internal state ────────────────────────────────────────────────────────────

local _busy = false -- simple busy flag, one call at a time for now

-- ── core call ─────────────────────────────────────────────────────────────────

--- Call Ollama asynchronously.
---
--- @param opts table
---   - prompt  string        the full prompt to send
---   - model   string|nil    override model (optional)
---   - on_done function(response: string)   called with result on success
---   - on_err  function(msg: string)|nil    called on failure (optional)
---
function M.call(opts)
  assert(opts.prompt, '[ollama] opts.prompt is required')
  assert(opts.on_done, '[ollama] opts.on_done is required')

  if _busy then
    vim.notify('[ollama] busy, try again in a moment', vim.log.levels.WARN)
    return
  end

  _busy = true

  local model = opts.model or config.model
  local url = config.host .. '/api/generate'
  local on_err = opts.on_err or function(msg)
    vim.notify('[ollama] error: ' .. msg, vim.log.levels.ERROR)
  end

  local payload = vim.fn.json_encode {
    model = model,
    prompt = opts.prompt,
    stream = false,
  }

  -- show a little spinner/status
  vim.notify('[ollama] thinking…', vim.log.levels.INFO)

  local chunks = {}

  vim.fn.jobstart({
    'curl',
    '-s',
    '-X',
    'POST',
    url,
    '-H',
    'Content-Type: application/json',
    '-d',
    payload,
  }, {
    stdout_buffered = true,

    on_stdout = function(_, data)
      for _, chunk in ipairs(data) do
        if chunk ~= '' then
          table.insert(chunks, chunk)
        end
      end
    end,

    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line ~= '' then
          vim.schedule(function()
            on_err('curl stderr: ' .. line)
          end)
        end
      end
    end,

    on_exit = function(_, code)
      _busy = false

      if code ~= 0 then
        vim.schedule(function()
          on_err('curl exited with code ' .. code)
        end)
        return
      end

      local raw = table.concat(chunks, '')

      if raw == '' then
        vim.schedule(function()
          on_err 'empty response from ollama — is it running?'
        end)
        return
      end

      local parse_ok, decoded = pcall(vim.fn.json_decode, raw)
      if not parse_ok or type(decoded) ~= 'table' then
        vim.schedule(function()
          on_err('could not parse response: ' .. raw)
        end)
        return
      end

      if decoded.error then
        vim.schedule(function()
          on_err('ollama said: ' .. decoded.error)
        end)
        return
      end

      if not decoded.response then
        vim.schedule(function()
          on_err('no response field in: ' .. raw)
        end)
        return
      end

      vim.schedule(function()
        opts.on_done(decoded.response)
      end)
    end,
  })
end

-- ── helpers other modules will want ──────────────────────────────────────────

--- Strip markdown code fences from a response.
--- Ollama sometimes wraps output in ```lang ... ``` even when told not to.
function M.strip_fences(text)
  return text
    :gsub('^```%w*\n', '') -- opening fence with optional lang
    :gsub('\n```$', '') -- closing fence
    :gsub('^```\n', '') -- opening fence without lang
    :gsub('```$', '') -- closing fence no newline
    :match '^%s*(.-)%s*$' -- trim whitespace
end

--- Split a response string into a list of lines (for nvim_buf_set_lines).
function M.to_lines(text)
  return vim.split(text, '\n', { plain = true })
end

--- Check if ollama is currently busy.
function M.is_busy()
  return _busy
end

return M
