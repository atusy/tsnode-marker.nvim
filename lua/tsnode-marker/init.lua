---@alias Tsnode userdata should actually be tsnode|under|userdata

---@class Opts_automark
---@field target? string[] | fun(buf: number, node: Tsnode): boolean
---@field hl_group string | fun(buf: number, node: Tsnode): string
---@field priority? number
---@field indent? "node" | "none" | fun(buf: number, node: Tsnode): number
---@field lang? string

local M = {}

local current_ns_key = false
local NAMESPACES = {
  [false] = vim.api.nvim_create_namespace("tsnode-marker-automark-ns-1"),
  [true] = vim.api.nvim_create_namespace("tsnode-marker-automark-ns-2"),
}

---@param buf number
---@param ns number
---@param start_row number
---@param end_row number
---@param opts Opts_automark
local function mark(buf, ns, start_row, end_row, opts)
  require("tsnode-marker.mark").mark_nodes_in_range(buf, {
    target = opts.target,
    hl_group = opts.hl_group,
    namespace = ns,
    start_row = start_row,
    end_row = end_row,
    lang = opts.lang
  })
end

---@param buf number
---@param namespace number
local function unmark(buf, namespace)
  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
end

---@param buf number
---@param start_row number
---@param end_row number
---@param opts Opts_automark
local function refresh(buf, start_row, end_row, opts)
  local prev = current_ns_key
  current_ns_key = not current_ns_key
  mark(buf, NAMESPACES[current_ns_key], start_row, end_row, opts)
  unmark(buf, NAMESPACES[prev])
end

---@param buf number
local function name_automark(buf)
  return "tsnode-marker-automark-augroup-" .. tostring(buf)
end

---@param buf number
local function clear_namespaces(buf)
  for _, ns in pairs(NAMESPACES) do
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
end

---@param buf number?
---unset automatic marking by removing autocmd and clearing namespaces
function M.unset_automark(buf)
  local buflist = buf == nil and vim.api.nvim_list_bufs() or { buf }
  for _, b in pairs(buflist) do
    local ok, _ = pcall(vim.api.nvim_del_augroup_by_name, name_automark(b))
    if ok then
      clear_namespaces(b)
    end
  end
end

---@param buf number
---@param opts Opts_automark
---set automatic marking on visible nodes in response to text changes,
---window scrolls and window resizes
function M.set_automark(buf, opts)
  local first_row = vim.fn.getpos("w0")[2] - 1
  local last_row = vim.fn.getpos("w$")[2] - 1
  clear_namespaces(buf)
  vim.schedule(
    -- make sure callback is evaluated after captures are available
    function()
      mark(buf, NAMESPACES[current_ns_key], first_row, last_row, opts)
    end
  )

  local augroup = vim.api.nvim_create_augroup(name_automark(buf), {})

  vim.api.nvim_create_autocmd({
    "TextChanged",
    "TextChangedI",
    "TextChangedP",
  }, {
    group = augroup,
    buffer = buf,
    callback = function()
      -- wait for parser update and avoid wrong highlights on o```<Esc>dd
      vim.schedule(function()
        first_row = vim.fn.getpos("w0")[2] - 1
        last_row = vim.fn.getpos("w$")[2] - 1
        refresh(buf, first_row, last_row, opts)
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "WinScrolled" }, {
    group = augroup,
    buffer = buf,
    callback = function()
      local prev_first, prev_last = first_row, last_row
      first_row = vim.fn.getpos("w0")[2] - 1
      last_row = vim.fn.getpos("w$")[2] - 1

      -- on pagewise scroll
      if (first_row > prev_last) or (last_row < prev_first) then
        refresh(buf, first_row, last_row, opts)
        return
      end

      -- on linewise scroll up or resize
      if first_row < prev_first then
        mark(buf, NAMESPACES[current_ns_key], first_row, prev_first - 1, opts)
      end

      -- on linewise scroll down or resize
      if last_row > prev_last then
        mark(buf, NAMESPACES[current_ns_key], prev_last + 1, last_row, opts)
      end
    end,
  })
end

return M
