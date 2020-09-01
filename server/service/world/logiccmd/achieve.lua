--import module
local global = require "global"
local skynet = require "skynet"

function Forward(mRecord, mData)
    local oAchieveMgr = global.oAchieveMgr
    local iPid = mData.pid
    local data = mData.data
    local cmd = mData.cmd
    local func = oAchieveMgr[cmd]
    if func then
        func(oAchieveMgr,iPid,data)
    end
end

function PushAchieve(mRecord,mData)
    local iPid = mData.pid
    local sKey = mData.key
    local data = mData.data
    global.oAchieveMgr:PushAchieve(iPid,sKey,data)
end

function SyncTotalAchPoint(mRecord,mData)
    local iPid = mData.pid or 0
    local iPoint = mData.point or 0
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:SetInfo("achpoint",iPoint)
    end
end