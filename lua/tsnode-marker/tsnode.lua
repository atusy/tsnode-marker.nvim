local M = {}

---@param buf number
---@param node Tsnode
---@return boolean
local function is_root(buf, node)
  if node:parent() ~= nil then
    return false
  end
  local start_row, start_col, end_row, end_col = node:range()
  if start_row == 0 and start_col == 0 and end_col == 0 then
    return end_row == vim.api.nvim_buf_line_count(buf)
  end
  return false
end

local function get_node(buf, start_row, end_row, opts)
  if vim.treesitter.get_node then
    return vim.treesitter.get_node({
      bufnr = buf,
      pos = {start_row, end_row},
      ignore_injections = opts.ignore_injections,
    })
  end
  -- get_node_at_pos is removed in 0.10
  local ok, node = pcall(vim.treesitter.get_node_at_pos, buf, start_row, end_row, opts)
  return ok and node or nil
end

---@param buf number
---@param start_row number
---@param end_row number
---@param opts table 
---@return Tsnode?
---get a first node in the range
function M.get_first_in_range(buf, start_row, end_row, opts)
  local node
  for row = start_row, end_row do
    node = get_node(buf, row, 0, opts) --[[@as Tsnode?]]
    if node and not is_root(buf, node) then
      return node
    end
  end
end

---@param node Tsnode
---@return Tsnode[]
---lists parent nodes and itself
---i.e. { node, node:parent(), node:parent():parent(), ... }
function M.list_parents(node)
  local list = {}
  local parent = node
  while parent ~= nil do
    table.insert(list, parent)
    parent = parent:parent()
  end
  return list
end

return M
