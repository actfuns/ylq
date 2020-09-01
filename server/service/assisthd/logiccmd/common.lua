--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function NewHour(mRecord,mData)
    local oAssistDHMgr = global.oAssistDHMgr
    local iWeekDay = mData.weekday
    local iHour = mData.hour
    oAssistDHMgr:NewHour(iWeekDay,iHour)
end

function CloseGS(mRecord, mData)
    global.oAssistDHMgr:CloseGS()
end




