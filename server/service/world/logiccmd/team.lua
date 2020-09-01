--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local res = require "base.res"
local colorstring = require "public.colorstring"

function AutoMatchSuccess(mRecord, mData)
    local iTargetID = mData.targetid
    local pid = mData.pid
    local iTeamID = mData.teamid
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local oTeamMgr = global.oTeamMgr
    local oTeam = oTeamMgr:GetTeam(iTeamID)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    local bValidAddTeam,iErrCode = oPlayer:ValidAddTeam()
    if not bValidAddTeam or oPlayer:HasTeam() then
        return
    end
    if oTeam and oPlayer then
        local iTeamTargetID = oTeam:GetTargetID()
        local iPlayerTargetID = oPlayer.m_oActiveCtrl:GetInfo("auto_targetid")
        local mTarget = res["daobiao"]["autoteam"][iTeamTargetID]
        local bIsChild = false
        if mTarget.parentId ~= 0 and mTarget.parentId == iPlayerTargetID then
            bIsChild = true
        end
        if iTeamTargetID and iPlayerTargetID and (iPlayerTargetID == iTeamTargetID or bIsChild or iPlayerTargetID == 1) and (iTeamTargetID == iTargetID or bIsChild) then
            if oTeamMgr:AddTeamMember(iTeamID, pid) then
                interactive.Send(".autoteam", "team", "CanclePlayerAutoMatch", {targetid = iPlayerTargetID, pid = pid})
                oPlayer:Send("GS2CPlayerMatchSuccess",{})
                oPlayer:SetAutoMatching(nil,true)
                local sMsg = colorstring.FormatColorString("欢迎#role加入队伍", {role = oPlayer:GetName()})
                oTeamMgr:TeamNotify(oTeam, sMsg)
                oChatMgr:HandleTeamChat(oPlayer, sMsg,  true)
            end
        end
    end
end

function TeamAutoMatchTimeOut(mRecord, mData)
    local iTargetID = mData.targetid
    local iTeamID = mData.teamid
    local oTeamMgr = global.oTeamMgr
    local oTeam = oTeamMgr:GetTeam(iTeamID)
    if oTeam and oTeam:AutoMatching() then
        local iTeamTargetID = oTeam:GetTargetID()
        if iTeamTargetID and iTeamTargetID == iTargetID then
            oTeam:SetUnAutoMatching()
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(oTeam:Leader(), "匹配超时，已停止自动匹配")
        end
    end
end

function NotifyAutoMatchTeam(mRecord, mData)
    local iTargetID = mData.targetid
    local iTeamID = mData.teamid
    local oWorldMgr = global.oWorldMgr
    local oTeamMgr = global.oTeamMgr
    local oTeam = oTeamMgr:GetTeam(iTeamID)
    if oTeam then
        local iLeader = oTeam:Leader()
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iLeader)
        if oPlayer then
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(iLeader, "现在匹配人数较少，快去加入别人的队伍吧")
        end
    else
        interactive.Send(".autoteam", "team", "CancleTeamAutoMatch", {targetid = iTargetID, teamid = iTeamID})
    end
end

function NotifyAutoMatchMember(mRecord, mData)
    local iTargetID = mData.targetid
    local pid = mData.pid
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        local iPlayerTargetID = oPlayer.m_oActiveCtrl:GetInfo("auto_targetid")
        if (iPlayerTargetID and iPlayerTargetID == iTargetID)  or iTargetID == 1 then
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(pid, "现在匹配人数较少，快去加入别人的队伍吧")
        end
    end
end

function MemAutoMatchTimeOut(mRecord, mData)
    local iTargetID = mData.targetid
    local pid = mData.pid
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        local iPlayerTargetID = oPlayer.m_oActiveCtrl:GetInfo("auto_targetid")
        if (iPlayerTargetID and iPlayerTargetID == iTargetID)  or iTargetID == 1  then
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(pid, "匹配超时，已停止自动匹配")
            oPlayer:SetAutoMatching(nil)
        end
    end
end