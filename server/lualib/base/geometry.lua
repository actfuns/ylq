
local M = {}

function M.Cover(f)
    return math.floor(f*1000)
end

function M.Recover(i)
    return i/1000
end

return M
