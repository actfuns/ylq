
local skynet = require "skynet"

local M = {}

local mRecord = {}
local bOpen = false

function M.Record(key,iMem)
    local interactive = require "base.interactive"
    local c2 = collectgarbage("count")
    local i1 = iMem*1024
    local i2 =  c2*1024
    if i2-i1 > 1000  then
        local sKey = ConvertTblToStr(key)
        sKey = string.format("{%s}_%s",MY_SERVICE_NAME,sKey)
        if not mRecord[sKey] then
            mRecord[sKey] = {}
        end
        local iSum = mRecord.sum or 0
        mRecord.sum = iSum + 1
        local mKeyRecord = mRecord[sKey]
        local iCnt = mKeyRecord.count or 0
        mKeyRecord.count = iCnt + 1
        local iTime = mKeyRecord.time or 0
        mKeyRecord.time = iTime + i2-i1
        mRecord[sKey] = mKeyRecord
        if mRecord.sum >= 200 then
            mRecord.sum = nil
            interactive.Send(".mem_rt_monitor", "common", "AddRtMonitor",mRecord)
            mRecord = {}
        end
    end
end

function M.Start()
    if bOpen then
        M.Stop()
    end
    bOpen = true
end

function M.Stop()
    if not bOpen then
        return
    end
    bOpen = false
end

function M.IsOpen()
    if bOpen then
        return true
    end
    return false
end

return M