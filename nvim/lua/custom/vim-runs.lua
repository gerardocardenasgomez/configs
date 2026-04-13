-- vim-runs.lua
-- Coding speedrun trainer. Pick a challenge, timer starts, code, stop, get roasted.
-- Drop in ~/.config/nvim/lua/custom/vim-runs.lua
--
-- Keybinds:
--   <leader>rs  →  start a run (telescope picker)
--   <leader>re  →  end a run   (stop timer, feed to ollama, save score)
--   <leader>rb  →  scoreboard  (floating window)

local M = {}
local ollama = require 'custom.ollama'

-- ── paths ─────────────────────────────────────────────────────────────────────

local CHALLENGES_DIR = vim.fn.expand '~/.config/nvim/lua/custom/challenges/'
local SCORES_FILE = CHALLENGES_DIR .. 'nvim-runs.json'

-- ── state ─────────────────────────────────────────────────────────────────────

local _run = nil -- active run state, nil when no run in progress
-- _run looks like:
-- {
--   challenge = "ring buffer · python",
--   prompt    = "implement a ring buffer with push, pop, is_full",
--   language  = "python",
--   start     = os.time(),
--   bufnr     = 42,
-- }

-- ── scores i/o ────────────────────────────────────────────────────────────────

local function load_scores()
  local f = io.open(SCORES_FILE, 'r')
  if not f then
    return {}
  end
  local raw = f:read '*a'
  f:close()
  if raw == '' then
    return {}
  end
  local ok, data = pcall(vim.fn.json_decode, raw)
  return ok and data or {}
end

local function save_scores(scores)
  vim.fn.mkdir(CHALLENGES_DIR, 'p')
  local f = io.open(SCORES_FILE, 'w')
  if not f then
    vim.notify('[vim-runs] could not write scores to ' .. SCORES_FILE, vim.log.levels.ERROR)
    return
  end
  f:write(vim.fn.json_encode(scores))
  f:close()
end

local function append_score(entry)
  local scores = load_scores()
  table.insert(scores, entry)
  save_scores(scores)
end

-- ── challenge loader ──────────────────────────────────────────────────────────

local function load_all_challenges()
  local challenges = {}
  local files = vim.fn.glob(CHALLENGES_DIR .. '*.lua', false, true)

  for _, filepath in ipairs(files) do
    local ok, lang_challenges = pcall(dofile, filepath)
    if ok and type(lang_challenges) == 'table' then
      for _, c in ipairs(lang_challenges) do
        table.insert(challenges, c)
      end
    end
  end

  return challenges
end

-- ── floating window (borrowed from notervim pattern) ─────────────────────────

local function create_floating_window(lines, title)
  local width = math.floor(vim.o.columns * 0.7)
  local height = math.min(#lines + 4, math.floor(vim.o.lines * 0.7))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'markdown'

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. (title or 'vim-runs') .. ' ',
    title_pos = 'center',
  })

  -- close with q or escape
  for _, key in ipairs { 'q', '<Esc>' } do
    vim.keymap.set('n', key, function()
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
  end

  return buf, win
end

-- ── format helpers ────────────────────────────────────────────────────────────

local function format_time(seconds)
  local m = math.floor(seconds / 60)
  local s = seconds % 60
  return string.format('%d:%02d', m, s)
end

local function format_date(timestamp)
  return os.date('%Y-%m-%d', timestamp)
end

-- ── start run ─────────────────────────────────────────────────────────────────

function M.start()
  if _run then
    vim.notify('[vim-runs] run already in progress! hit <leader>re to finish it', vim.log.levels.WARN)
    return
  end

  local challenges = load_all_challenges()
  if #challenges == 0 then
    vim.notify('[vim-runs] no challenges found in ' .. CHALLENGES_DIR, vim.log.levels.ERROR)
    return
  end

  local ok, telescope = pcall(require, 'telescope.pickers')
  if not ok then
    vim.notify('[vim-runs] telescope not found', vim.log.levels.ERROR)
    return
  end

  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local state = require 'telescope.actions.state'

  telescope
    .new({}, {
      prompt_title = '⏱  pick a challenge',
      finder = finders.new_table {
        results = challenges,
        entry_maker = function(c)
          return {
            value = c,
            display = c.name,
            ordinal = c.name,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = state.get_selected_entry()
          if not selection then
            return
          end

          local challenge = selection.value

          -- open a fresh scratch buffer
          local bufnr = vim.api.nvim_create_buf(true, false)
          vim.api.nvim_set_current_buf(bufnr)

          -- set filetype from challenge
          if challenge.language and challenge.language ~= '' then
            vim.bo[bufnr].filetype = challenge.language
          end

          -- drop the challenge description as a comment at the top
          local comment_char = challenge.comment or '#'
          local header = {
            comment_char .. ' vim-runs: ' .. challenge.name,
            comment_char .. ' ' .. challenge.prompt,
            comment_char .. ' timer started — go go go!!',
            '',
          }
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, header)

          -- cursor to end, insert mode, GO
          vim.api.nvim_win_set_cursor(0, { #header, 0 })
          vim.cmd 'startinsert'

          -- start the clock AFTER all setup
          _run = {
            challenge = challenge.name,
            prompt = challenge.prompt,
            language = challenge.language or '',
            start = os.time(),
            bufnr = bufnr,
          }

          vim.notify('[vim-runs] 🏁 GO! ' .. challenge.name, vim.log.levels.INFO)
        end)
        return true
      end,
    })
    :find()
end

-- ── end run ───────────────────────────────────────────────────────────────────

function M.finish()
  if not _run then
    vim.notify('[vim-runs] no run in progress', vim.log.levels.WARN)
    return
  end

  local elapsed = os.time() - _run.start
  local time_fmt = format_time(elapsed)
  local run = _run
  _run = nil -- clear state immediately

  vim.notify('[vim-runs] ⏱ ' .. time_fmt .. ' — asking ollama to judge you…', vim.log.levels.INFO)

  -- grab what they wrote
  local lines = vim.api.nvim_buf_get_lines(run.bufnr, 0, -1, false)
  local code = table.concat(lines, '\n')

  local prompt = string.format(
    'You are a code reviewer judging a timed coding challenge.\n'
      .. 'Challenge: %s\n'
      .. 'Language: %s\n'
      .. 'Time taken: %s\n\n'
      .. 'Here is the submitted code:\n%s\n\n'
      .. 'Give feedback in this exact format, no markdown fences:\n'
      .. 'VERDICT: one sentence, did they nail it or not\n'
      .. 'GOOD: one thing they did well\n'
      .. 'UGLY: one thing to fix or watch out for\n'
      .. 'SPICY: one harder follow-up challenge to try next time\n',
    run.challenge,
    run.language,
    time_fmt,
    code
  )

  ollama.call {
    prompt = prompt,
    on_done = function(response)
      local feedback = ollama.strip_fences(response)

      -- save to scoreboard
      append_score {
        challenge = run.challenge,
        language = run.language,
        time_secs = elapsed,
        time_fmt = time_fmt,
        date = format_date(run.start),
        feedback = feedback,
      }

      -- build result display
      local display = {
        '## ' .. run.challenge,
        '',
        '⏱  **' .. time_fmt .. '**',
        '',
        '### ollama says:',
        '',
      }
      for _, line in ipairs(vim.split(feedback, '\n', { plain = true })) do
        table.insert(display, line)
      end

      create_floating_window(display, '⏱ vim-runs result')
    end,
    on_err = function(msg)
      -- still save the time even if ollama fails
      append_score {
        challenge = run.challenge,
        language = run.language,
        time_secs = elapsed,
        time_fmt = time_fmt,
        date = format_date(run.start),
        feedback = 'ollama unavailable: ' .. msg,
      }
      vim.notify('[vim-runs] time saved (' .. time_fmt .. ') but ollama failed: ' .. msg, vim.log.levels.WARN)
    end,
  }
end

-- ── scoreboard ────────────────────────────────────────────────────────────────

function M.scoreboard()
  local scores = load_scores()

  if #scores == 0 then
    vim.notify('[vim-runs] no runs yet. get grinding!', vim.log.levels.INFO)
    return
  end

  -- find personal bests per challenge+language
  local bests = {}
  for _, s in ipairs(scores) do
    local key = s.challenge .. '|' .. s.language
    if not bests[key] or s.time_secs < bests[key] then
      bests[key] = s.time_secs
    end
  end

  local lines = {
    '# vim-runs scoreboard',
    '',
  }

  -- group by challenge
  local grouped = {}
  for _, s in ipairs(scores) do
    local key = s.challenge
    if not grouped[key] then
      grouped[key] = {}
    end
    table.insert(grouped[key], s)
  end

  for challenge, runs in pairs(grouped) do
    table.insert(lines, '## ' .. challenge)
    -- sort by time
    table.sort(runs, function(a, b)
      return a.time_secs < b.time_secs
    end)
    for _, r in ipairs(runs) do
      local pb_key = r.challenge .. '|' .. r.language
      local pb_tag = (bests[pb_key] == r.time_secs) and ' 🏆' or ''
      table.insert(lines, string.format('  %s · %s · %s%s', r.time_fmt, r.language, r.date, pb_tag))
    end
    table.insert(lines, '')
  end

  create_floating_window(lines, '🏆 scoreboard')
end

-- ── keymaps ───────────────────────────────────────────────────────────────────

vim.keymap.set('n', '<leader>rs', M.start, { desc = 'vim-runs: start a run' })
vim.keymap.set('n', '<leader>re', M.finish, { desc = 'vim-runs: end run + get feedback' })
vim.keymap.set('n', '<leader>rb', M.scoreboard, { desc = 'vim-runs: scoreboard' })

return M
