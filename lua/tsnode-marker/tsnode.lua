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

---@param buf number
---@param start_row number
---@param end_row number
---@return Tsnode?
function M.get_first_in_range(buf, start_row, end_row)
  local node
  for row = start_row, end_row do
    node = vim.treesitter.get_node_at_pos(buf, row, 0, {}) --[[@as Tsnode?]]
    if node and not is_root(buf, node) then
      return node
    end
  end
end

---@param node Tsnode
---@return Tsnode[]
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
