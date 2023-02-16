local M = {}

---@param line string
---@param tabstop number
---@return number
local function measure_indent(line, tabstop)
  local n = 0
  for l in string.gmatch(line, ".") do
    if l == " " then
      n = n + 1
    elseif l == "\t" then
      n = math.floor(n / tabstop + 1) * tabstop
    else
      return n
    end
  end
  return n
end

---@param lines string[]
---@param tabstop number
---@return number
function M.measure_common_indent(lines, tabstop)
  local counts = {}
  for _, l in pairs(lines) do
    if l ~= "" then
      table.insert(counts, measure_indent(l, tabstop))
    end
  end
  return #counts == 0 and 0 or math.min(unpack(counts))
end

return M
