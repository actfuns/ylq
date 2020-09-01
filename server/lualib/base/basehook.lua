
local skynet = require "skynet"

local base_func
local logic_func

local M = {}

function M.set_base(f)
    local old = base_func
    base_func = f
    return old
end

function M.set_logic(f)
    local old = logic_func
    logic_func = f
    return old
end

function M.hook()
    if logic_func then
        safe_call(logic_func)
    end
    if base_func then
        safe_call(base_func)
    end
end

return M
