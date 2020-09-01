
local skynet = require "skynet"

local M = {}

local iCurrMem = 0
local sLineName = ""
local bOpen = false

local function RecordFunc(sEvent, iLineNo)
    local iMemInc = collectgarbage("count") - iCurrMem
    if (iMemInc <= 1e-6) then
        iCurrMem = collectgarbage("count")
        return
    end
    skynet.send(".mem_monitor", "lua", "Record", iMemInc, sLineName)
    sLineName = string.format("{%s}%s_%s", MY_SERVICE_NAME, debug.getinfo(2, 'S').source, iLineNo)
    iCurrMem = collectgarbage("count")
end

function M.Start()
    if bOpen then
        M.Stop()
    end
    iCurrMem = collectgarbage("count")
    bOpen = true
    debug.sethook(RecordFunc, "l")
end

function M.Stop()
    if not bOpen then
        return
    end
    debug.sethook()
    iCurrMem = 0
    bOpen = false
end

return M
