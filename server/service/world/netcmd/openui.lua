--import module
local global = require "global"
local extend = require "base.extend"


function C2GSOpenScheduleUI(oPlayer,mData)
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:IsClose("schedule") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    oPlayer.m_oScheduleCtrl:GS2CSchedule()
end

function C2GSScheduleReward(oPlayer,mData)
    local oWorldMgr = global.oWorldMgr
    if oWorldMgr:IsClose("schedule") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local rewardidx = mData["rewardidx"]
    oPlayer.m_oScheduleCtrl:GetReward(rewardidx)
end

function C2GSClickSchedule(oPlayer,mData)
    local sid = mData["sid"]
    oPlayer.m_oScheduleCtrl:ClickSchedule(oPlayer,sid)
end

function C2GSOpenInterface(oPlayer, mData)
    local oInterfaceMgr = global.oInterfaceMgr
    oInterfaceMgr:ClientOpen(oPlayer, mData.type)
end



function C2GSCloseInterface(oPlayer, mData)
    local oInterfaceMgr = global.oInterfaceMgr
    oInterfaceMgr:ClientClose(oPlayer, mData.type)
end

function C2GSEditBattlCommand(oPlayer,mData)
    local idx = mData["idx"]
    local cmd = mData["cmd"]
    local mBattle = oPlayer.m_oBaseCtrl:GetData("BattleCommand")
    if not mBattle[idx] then
        return
    end
    mBattle[idx] = cmd
    oPlayer.m_oBaseCtrl:SetData("BattleCommand",mBattle)
    oPlayer:PropChange("bcmd")
end

