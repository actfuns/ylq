--import module
local global = require "global"
local skynet = require "skynet"

function OnLogin(mRecord,mData)
    local iPid = mData["pid"]
    global.oGamePushMgr:OnLogin(iPid,mData)
end

function NewHour(mRecord,mData)
    local iWeekDay = mData.weekday
    local iHour = mData.hour
    global.oGamePushMgr:NewHour(iWeekDay,iHour)
end

function Push(mRecord,mData)
    local iPid = mData.pid
    local sTitle = mData.title
    local sText = mData.text
    global.oGamePushMgr:Push(iPid,sTitle,sText)
end

function PushById(mRecord,mData)
    local iPid = mData.pid
    local id = mData.id
    global.oGamePushMgr:PushById(iPid,id)
end