-- Reader, summarizer and code explainers backed by the local `parloquent` voice client.
--
-- `parloquent narrate` rewrites the given text into spoken narration and
-- `parloquent summarize` condenses it; both stream the result through cloud TTS.
-- The code explainers reuse `explain` and `summarize` and prefix the code with
-- an instruction, so the client itself needs no code-specific mode.
-- Starting the client again stops an active reader, so pressing a
-- key a second time stops the speech without any state in the editor.

local M = {}

---@class parloquent.Action
---@field mode "narrate" | "summarize" | "explain" Client subcommand that receives the text.
---@field name string Name used in editor messages.
---@field instruction? string Prefixed to the text together with its source, for code explainers.

---@type parloquent.Action
local NARRATE = { mode = "narrate", name = "narrate" }

---@type parloquent.Action
local SUMMARIZE = { mode = "summarize", name = "summarize" }

---@type parloquent.Action
local EXPLAIN = {
  mode = "explain",
  name = "explain",
  instruction = "Explain the following code to a developer who reads it for the first time: "
    .. "start with its purpose, then walk through the key steps and why they matter. "
    .. "Keep it short enough to hear in under a minute, and do not read syntax or symbols out one by one.",
}

---@type parloquent.Action
local ONE_SENTENCE = {
  mode = "summarize",
  name = "one-sentence explain",
  instruction = "Say what the following code does in exactly one plain sentence, "
    .. "with no introduction and no follow-up.",
}

-- Tree-sitter node types that hold a whole unit of code. Calls, invocations
-- and type expressions contain these words as well but are not units.
local UNITS = { "function", "method", "class", "impl", "trait", "interface", "struct", "enum" }
local NOT_UNITS = { "call", "invocation", "type", "signature" }

---@param haystack string
---@param needles string[]
---@return boolean
local function contains_any(haystack, needles)
  for _, needle in ipairs(needles) do
    if haystack:find(needle, 1, true) then
      return true
    end
  end
  return false
end

---The lines `first` to `last` (1-based, inclusive) of the current buffer.
---@param first integer
---@param last integer
---@return string
local function lines_text(first, last)
  return table.concat(vim.api.nvim_buf_get_lines(0, first - 1, last, false), "\n")
end

---@return integer first
---@return integer last
local function buffer_range()
  return 1, vim.api.nvim_buf_line_count(0)
end

---The lines of the visual selection that is still active while the mapping
---runs. The `'<` and `'>` marks are only set once visual mode is left, so the
---selection is read from the visual anchor and the cursor instead.
---@return integer first
---@return integer last
local function selection_range()
  local anchor = vim.fn.getpos("v")[2]
  local cursor = vim.fn.getpos(".")[2]
  return math.min(anchor, cursor), math.max(anchor, cursor)
end

---The innermost function, method, class or similar unit around the cursor.
---Buffers without a tree-sitter parser have none.
---@return integer? first
---@return integer? last
local function unit_range()
  local ok, node = pcall(function()
    local parser = vim.treesitter.get_parser(0, nil, { error = false })
    if parser == nil then
      return nil
    end
    -- The tree is parsed lazily, so a buffer that tree-sitter has not
    -- highlighted yet has no nodes until it is parsed here.
    parser:parse()
    return vim.treesitter.get_node()
  end)
  while ok and node do
    local kind = node:type()
    if contains_any(kind, UNITS) and not contains_any(kind, NOT_UNITS) then
      local first, _, last, last_column = node:range()
      -- A node that ends at column 0 stops on the previous line.
      if last_column == 0 and last > first then
        last = last - 1
      end
      return first + 1, last + 1
    end
    node = node:parent()
  end
end

---Names the code and its origin for the model. Only the file name is sent, not
---its path.
---@param instruction string
---@param text string
---@param first integer
---@param last integer
---@return string
local function frame(instruction, text, first, last)
  local parts = { instruction }
  -- The desktop profile passes the spoken language along, so the explanation
  -- is delivered in the language of the configured voice.
  local language = vim.g.parloquent_language
  if language and language ~= "" and language ~= "auto" then
    table.insert(parts, ("Answer in the language with the ISO 639-1 code %s."):format(language))
  end
  local name = vim.fn.expand("%:t")
  table.insert(
    parts,
    ("Source: %s (%s), lines %d-%d."):format(
      name ~= "" and name or "unnamed buffer",
      vim.bo.filetype ~= "" and vim.bo.filetype or "plain text",
      first,
      last
    )
  )
  return table.concat(parts, " ") .. "\n\n" .. text
end

---@param action parloquent.Action
---@param scope "buffer" | "selection" | "unit"
---@param first integer
---@param last integer
local function speak(action, scope, first, last)
  local text = lines_text(first, last)
  if text:find("%S") == nil then
    vim.notify(("parloquent %s: the %s has no text"):format(action.name, scope), vim.log.levels.WARN)
    return
  end
  if action.instruction then
    text = frame(action.instruction, text, first, last)
  end

  local command = vim.g.parloquent_command or "parloquent"
  if vim.fn.executable(command) == 0 then
    vim.notify(
      ("parloquent %s: %q is not executable; the desktop voice stack provides it"):format(action.name, command),
      vim.log.levels.ERROR
    )
    return
  end

  -- Detach the client: the speech continues when the editor quits, and the
  -- client reports provider failures on stderr without blocking the editor.
  local ok, failure = pcall(vim.system, { command, action.mode, "--stdin" }, {
    stdin = text,
    text = true,
    detach = true,
  }, function(out)
    if out.code ~= 0 then
      vim.schedule(function()
        vim.notify(("parloquent %s failed: %s"):format(action.name, vim.trim(out.stderr or "")), vim.log.levels.ERROR)
      end)
    end
  end)
  if not ok then
    vim.notify(("parloquent %s: %s"):format(action.name, failure), vim.log.levels.ERROR)
    return
  end

  vim.notify(("parloquent %s: speaking the %s (press again to stop)"):format(action.name, scope), vim.log.levels.INFO)
end

---Code explainers work on the unit around the cursor, since a whole file is
---rarely what needs explaining, and fall back to the buffer.
---@param action parloquent.Action
local function speak_unit(action)
  local first, last = unit_range()
  if first and last then
    speak(action, "unit", first, last)
  else
    speak(action, "buffer", buffer_range())
  end
end

function M.narrate()
  speak(NARRATE, "buffer", buffer_range())
end

function M.narrate_selection()
  speak(NARRATE, "selection", selection_range())
end

function M.summarize()
  speak(SUMMARIZE, "buffer", buffer_range())
end

function M.summarize_selection()
  speak(SUMMARIZE, "selection", selection_range())
end

function M.explain()
  speak_unit(EXPLAIN)
end

function M.explain_selection()
  speak(EXPLAIN, "selection", selection_range())
end

function M.one_sentence()
  speak_unit(ONE_SENTENCE)
end

function M.one_sentence_selection()
  speak(ONE_SENTENCE, "selection", selection_range())
end

return M
