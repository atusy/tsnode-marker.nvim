---@class Opts_mark: Opts_automark
---@field namespace number
---@field start_row? number
---@field end_row? number

local M = {}

---@param line string
---@param indent number
---@param tabstop number
---@return number
---finds start column for extmark on a line
local function find_start_col(line, indent, tabstop)
  local start_col = 0
  local start_pos = 0
  for s in string.gmatch(line, ".") do
    if start_pos >= indent then
      break
    end
    if s == " " then
      start_col = start_col + 1
      start_pos = start_pos + 1
    elseif s == "\t" then
      start_col = start_col + 1
      start_pos = math.floor(start_pos / tabstop + 1) * tabstop
    else
      return start_col
    end
  end
  return start_col
end

---@param buf number
---@param node Tsnode
---@param lines string[]
---@param tabstop number
---@param opts Opts_mark
---measures indent of a node respecting opts.indent
local function measure_node_indent(buf, node, lines, tabstop, opts)
  local o = opts.indent
  if o == nil or o == "node" then
    return require("tsnode-marker.indent").measure_common_indent(lines, tabstop)
  end
  if type(o) == "function" then
    return o(buf, node)
  end
  return 0
end

---@param buf number
---@param node userdata
---@param opts Opts_mark
---sets highlight group on a node respecting its indent
---and sets virtual text to fix apparent outdenting on blanklines
function M.mark_node(buf, node, opts)
  local range = { node:range() }
  local lines = vim.api.nvim_buf_get_lines(buf, range[1], range[3] + 1, false)
  local tabstop = vim.api.nvim_buf_get_option(buf, "tabstop")
  local indent = measure_node_indent(buf, node, lines, tabstop, opts)

  for i, line in pairs(lines) do
    local start_col = find_start_col(line, indent, tabstop)
    if i == 1 then
      start_col = range[2] > start_col and range[2] or start_col
    end
    local start_row = range[1] - 1 + i
    local end_row = start_row + 1
    local end_col = 0
    if i == #lines and range[4] < #line then
      end_col = range[4]
      end_row = start_row
    end
    vim.api.nvim_buf_set_extmark(buf, opts.namespace, start_row, start_col, {
      end_row = end_row,
      end_col = end_col,
      hl_eol = true,
      priority = opts.priority or 1,
      hl_group = type(opts.hl_group == "string") and opts.hl_group or opts.hl_group(buf, node),
    })
    if line == "" and indent > 0 then
      vim.api.nvim_buf_set_extmark(buf, opts.namespace, start_row, 0, {
        virt_text = { { string.rep(" ", indent), "Normal" } },
        virt_text_pos = "overlay",
        virt_text_win_col = 0,
        virt_text_hide = true,
        priority = (opts.priority and opts.priority + 1 or 1),
      })
    end
  end
end

---@param buf number
---@param node Tsnode
---@return string[]
---list captures from the first position of a node
---
---NOTE: should actually be a part of tsnode, however, it sits here unexported
---      because this function is used by an experimental feature.
local function get_captures(buf, node)
  local row, col, _, _ = node:range()
  local captures = vim.treesitter.get_captures_at_pos(buf, row, col + 1)
  local ret = {}
  for _, c in pairs(captures) do
    table.insert(ret, c.capture)
  end
  return ret
end

---@param buf number
---@param node Tsnode
---@param opts Opts_mark
---@return boolean
---tests if node is a target to be marked
local function is_target(buf, node, opts)
  local _target = opts.target
  if _target == nil then
    return vim.tbl_contains(get_captures(buf, node), "tsnodemarker")
  end
  local _type = type(_target)
  if _type == "function" then
    return _target(buf, node)
  end
  if _type == "table" then
    return vim.tbl_contains(_target, node:type())
  end
  return false
end

---@param buf number
---@param node Tsnode
---@param opts Opts_mark
---@return nil
---recursively marks children of a node if it satisfies opts.target and
---if children overlaps with the range opts.start_row to opts.end_row
local function mark_children(buf, node, opts)
  for k in node:iter_children() do
    if is_target(buf, k, opts) then
      M.mark_node(buf, k, opts)
    else
      local sr, _, er, _ = k:range()
      if (opts.start_row <= sr and sr <= opts.end_row) or (opts.start_row <= er and er <= opts.end_row) then
        mark_children(buf, k, opts)
      end
    end
  end
end

---@param buf number
---@param node Tsnode
---@param opts Opts_mark
---@return nil
---marks next siblings of a node if it satisifies opts.target
---if the siblings overlaps with the range opts.start_row to opts.end_row
local function mark_next_sibling(buf, node, opts)
  local n = node
  while true do
    n = n:next_sibling()
    if n == nil then
      return
    end
    local range = { n:range() }
    if range[1] <= opts.end_row then
      if is_target(buf, n, opts) then
        M.mark_node(buf, n, opts)
      else
        mark_children(buf, n, opts)
      end
    end
  end
end

---@param buf number
---@param opts Opts_mark
---@return nil
---marks nodes if they satisfy opts.target and 
---if they overlaps with the range opts.start_row to opts.end_row
---
---in order to avoid meaningless overlaying,
---marks applies in descending order from the root of a tree
function M.mark_nodes_in_range(buf, opts)
  if not opts.start_row or not opts.end_row then
    opts = vim.deepcopy(opts)
    opts.start_row = opts.start_row or 0
    opts.end_row = opts.end_row or (vim.fn.getpos("$") - 1)
  end
  local tsnode = require("tsnode-marker.tsnode")
  local first_node = tsnode.get_first_in_range(buf, opts.start_row, opts.end_row)

  if first_node == nil then
    return
  end

  local ancestors = tsnode.list_parents(first_node)
  for i = #ancestors, 1, -1 do
    local n = ancestors[i]
    if is_target(buf, n, opts) then
      M.mark_node(buf, n, opts)
    elseif i == 1 then
      mark_children(buf, n, opts)
    end
    mark_next_sibling(buf, n, opts)
  end
end

return M
