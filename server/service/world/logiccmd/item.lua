--import module
local global = require "global"
local skynet = require "skynet"

local loaditem = import(service_path("item.loaditem"))

function ChangeWeapon(mRecord,mData)
    local iPid = mData.pid
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local iWeapon = mData.weapon
        oPlayer:ChangeWeapon(iWeapon)
    end
end

function SyncRemoteItemData(mRecord,mData)
    local iPid = mData.pid
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oItemCtrl:SyncRemoteData(mData.shape)
    end
end

function UseBaotu(mRecord,mData)
    local iPid = mData.pid
    local mArgs = mData.args or {}

    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    global.oAchieveMgr:PushAchieve(iPid,"挖宝次数",{value=1})
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30008,1)
    local iT = oPlayer.m_oActiveCtrl:GetTreasureTotalTimes()
    local mReward = mArgs.reward_info or {}
    oPlayer:Send("GS2CTreasureNormalResult",{idx=mReward["value"],type = mReward["type"]})
    local sReason = "挖宝"
    local oHuodongMgr = global.oHuodongMgr
    local oBuddy = oHuodongMgr:GetHuodong("treasure")
    oBuddy:GiveNormalReward(oPlayer,mReward,mArgs)
    oPlayer.m_oActiveCtrl:SetTreasureTotalTimes(iT+1)
    local iW = oPlayer.m_oActiveCtrl:GetTreasureWeekTimes()
    oPlayer.m_oActiveCtrl:SetTreasureWeekTimes(iW+1)
end

function SendItemMail(mRecord,mData)
    local mItem = mData.item
    local iPid = mData.pid
    local iShape = mItem["sid"]
    local oItem = loaditem.LoadItem(iShape,mItem)
    local iMailId = 1
    local oMailMgr = global.oMailMgr
    local mMailData, sName = oMailMgr:GetMailInfo(iMailId)
    oMailMgr:SendMail(0, sName, iPid, mMailData, {}, {oItem})
end