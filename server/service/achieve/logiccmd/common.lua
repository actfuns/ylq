local global = require "global"

function OnLogin(mRecord, mData)
    local oAchieveMgr = global.oAchieveMgr
    local iPid = mData.pid
    oAchieveMgr:OnLogin(iPid, mData)
end

function OnLogout(mRecord, mData)
    local oAchieveMgr = global.oAchieveMgr
    local iPid = mData.pid
    oAchieveMgr:OnLogout(iPid)
end

function Disconnected(mRecord, mData)
    local oAchieveMgr = global.oAchieveMgr
    local iPid = mData.pid
    oAchieveMgr:Disconnected(iPid)
end

function PushAchieve(mRecord, mData)
    local sKey = mData.key
    local oAchieveMgr = global.oAchieveMgr
    oAchieveMgr:Push(sKey,mData)
end

function ClearAchieveDegree(mRecord, mData)
    local oAchieveMgr = global.oAchieveMgr
    local iPid = mData.pid
    local sKey = mData.key
    oAchieveMgr:ClearAchieveDegree(iPid,sKey)
end

function CloseGS(mRecord, mData)
    global.oAchieveMgr:CloseGS()
end

function SyncServerDay(mRecord, mData)
    global.oAchieveMgr:UpdateOpenDay(mData.open_day)
end

function NewDay(mRecord, mData)
    global.oAchieveMgr:NewDay(mData)
end

function FixSevDay(mRecord, mData)
    local iPid = mData.pid
    local oAchieveMgr = global.oAchieveMgr
    local oPlayer = oAchieveMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oSevenDayCtrl:CheckFix(iPid, mData.cmd, mData.data)
    end
end

function UpdateAchievekey(mRecord,mData)
    local oAchieveMgr = global.oAchieveMgr
    oAchieveMgr:UpdateAchieveKey()
end

function Forward(mRecord, mData)
    local iPid = mData.pid
    local sCmd = mData.cmd
    local oAchieveMgr = global.oAchieveMgr
    local oPlayer = oAchieveMgr:GetPlayer(iPid)
    if oPlayer then
        local func = ForwardNetcmds[sCmd]
        assert(func, string.format("Forward function:%s not exist!", sCmd))
        func(oPlayer, mData.data)
    end
end

ForwardNetcmds = {}

function ForwardNetcmds.C2GSAchieveMain(oPlayer, mData)
    oPlayer:OpenAchieveMainUI()
end

function ForwardNetcmds.C2GSAchieveDirection(oPlayer, mData)
    oPlayer:OpenAchieveDirectionUI(mData.id,mData.belong)
end

function ForwardNetcmds.C2GSAchieveReward(oPlayer, mData)
    oPlayer:RewardAchItem(mData.id)
end

function ForwardNetcmds.C2GSAchievePointReward(oPlayer, mData)
    oPlayer:RewardPointItem(mData.id)
end

function ForwardNetcmds.C2GSOpenPicture(oPlayer,mData)
    oPlayer:OpenPictureMainUI()
end

function ForwardNetcmds.C2GSPictureReward(oPlayer,mData)
    oPlayer:RewardPicItem(mData.id)
end

function ForwardNetcmds.C2GSCloseMainUI(oPlayer, mData)
    oPlayer:MarkCloseUI()
end

function ForwardNetcmds.C2GSOpenSevenDayMain(oPlayer, mData)
    local iDay = mData.day
    if not iDay then
        iDay = math.min(7, global.oAchieveMgr:GetServerDay() + 1)
    end
    oPlayer:OpenSevdayMainUI()
    oPlayer:OpenSevDayUI(mData.day or 1)
end

function ForwardNetcmds.C2GSOpenSevenDay(oPlayer, mData)
    oPlayer:OpenSevDayUI(mData.day or 1)
end

function ForwardNetcmds.C2GSSevenDayReward(oPlayer, mData)
    oPlayer:RewardSevItem(mData.id)
end

function ForwardNetcmds.C2GSSevenDayPointReward(oPlayer, mData)
    oPlayer:RewardSevPointItem(mData.id)
end

function ForwardNetcmds.C2GSGetAchieveTaskReward(oPlayer,mData)
    oPlayer:GetAchieveTaskReward(mData.taskid)
end