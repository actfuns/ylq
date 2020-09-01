
local skynet = require "skynet"
local measure = require "measure"
local mem_rt_monitor = require "base.mem_rt_monitor"

local M = {}

local bOpenMonitor = false

--考虑效率,使用该接口的函数最多返回3个值
function M.mo_call(key, func, ...)
    if not M.is_open_monitor() then
        local a, b, c = func(...)
        return a, b, c
    else
        local itt = measure.timestamp_us()
        local c1
        if mem_rt_monitor.IsOpen() then
            c1 = collectgarbage("count")
        end
        local a, b, c = func(...)
        skynet.send(".rt_monitor", "lua", "Record", measure.timestamp_us() - itt, key, MY_SERVICE_NAME)
        if mem_rt_monitor.IsOpen() and c1 then
            mem_rt_monitor.Record(key,c1)
        end
        return a, b, c
    end
end

function M.change_monitor(bFlag)
    bOpenMonitor = bFlag
end

function M.is_open_monitor()
    return bOpenMonitor
end

return M
