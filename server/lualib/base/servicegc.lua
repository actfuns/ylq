local skynet = require "skynet"

local M = {}
local GC_MODE = 1
local GC_INTERVAL =  30000
local GC_UNIT_SIZE = 1000
local GC_UNIT_TIME = 5000

--GC_MODE
--1 默认自动gc
--2 关闭自动gc 每隔GC_INTERVAL 自动全量gc
--3 关闭自动gc 每隔GC_UNIT_TIME  自动增量gc 每次回收 GC_UNIT_SIZE KB

function M.SetGCConfig(iMode,iTime,iSize)
    assert(table_in_list({1,2,3},iMode), "error gcmode"..iMode)
    iTime = tonumber(iTime)
    iSize = tonumber(iSize)

    if iMode == 2 then
        GC_INTERVAL = iTime or GC_INTERVAL
    elseif iMode == 3 then
        GC_UNIT_TIME = iTime or GC_UNIT_TIME
        GC_UNIT_SIZE = iSize or GC_UNIT_SIZE
    end

    M.ChangeGCMode(iMode)
end

function M.TipGCInfo()
    local sTip = " gcmode: " .. GC_MODE
    if GC_MODE == 2 then
        sTip = sTip .. " time " .. GC_INTERVAL
    elseif GC_MODE == 3 then
        sTip = sTip .. " time " .. GC_UNIT_TIME .. " size ".. GC_UNIT_SIZE
    end
    return "ServiceName: "..MY_SERVICE_NAME .. sTip
end

function M.ChangeGCMode(iMode)
    assert(table_in_list({1,2,3},iMode), "error gcmode"..iMode)

    local iOldMode = GC_MODE
    GC_MODE = iMode
    if iOldMode == 1 and table_in_list({2,3},iMode) then
        collectgarbage("stop")
    elseif table_in_list({2,3},iOldMode) and iMode == 1 then
        collectgarbage("restart")
    end
end

function M.Init()
    if table_in_list({2,3},GC_MODE) then
        collectgarbage("stop")
    end
    local f
    f = function ()
        local iNext = 1000
        if GC_MODE ~= 1 then
            if GC_MODE == 2 then
                collectgarbage("collect")
                iNext = GC_INTERVAL
            elseif GC_MODE == 3 then
                collectgarbage("step",GC_UNIT_SIZE)
                iNext = GC_UNIT_TIME
            end
        end
        skynet.timeout(iNext, f)
    end
    skynet.timeout(1, f)
end

return M