--import module

local global = require "global"
local interactive = require "base.interactive"
local net = require "base.net"
local teamobj = import(service_path("team/teamobj"))
local lilianteamobj = import(service_path("task/lilianteamobj"))
local meminfo = import(service_path("team/meminfo"))
local teaminfo = import(service_path("team/teaminfo"))
local votebox = import(service_path("team/votebox"))
local gamedefines = import(lualib_path("public.gamedefines"))
local colorstring = require "public.colorstring"

function NewTeamMgr(...)
    return CTeamMgr:New(...)
end


CTeamMgr = {}
CTeamMgr.__index = CTeamMgr
inherit(CTeamMgr,logic_base_cls())

function CTeamMgr:New()
    local o = super(CTeamMgr).New(self)
    o.m_iTeamID = 1
    o.m_mTeamList = {}
    o.m_mInviteList = {}
    o.m_mPid2TeamID = {}
    o.m_fWarEndFunc = {}
    return o
end

function CTeamMgr:DispatchId()
    self.m_iTeamID = self.m_iTeamID + 1
    return self.m_iTeamID
end

function CTeamMgr:CreateTeam(pid, mTarget)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oSceneMgr = global.oSceneMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end
    if oPlayer:HasTeam() then
        oNotifyMgr:Notify(pid,"你已经有队伍了，无法创建")
        return
    end
    local mArgs = {
        model_info = oPlayer:GetModelInfo(),
        grade = oPlayer:GetGrade(),
        school = oPlayer:GetSchool(),
        name = oPlayer:GetName(),
        hp = oPlayer:GetHp(),
        maxhp = oPlayer:GetMaxHp(),
        school_branch = oPlayer:GetSchoolBranch(),
    }
    local iTeamID = self:DispatchId()
    local oTeam = teamobj.NewTeam(pid, iTeamID)
    mArgs["teamid"] = iTeamID
    oTeam:SetAutoMatchTarget(mTarget)
    local oMember = meminfo.NewMember(pid,mArgs)
    oTeam:AddMember(oMember)
    self.m_mTeamList[iTeamID] = oTeam
    self.m_mPid2TeamID[pid] = iTeamID

    oNotifyMgr:Notify(pid,"创建队伍成功")

    -- 注册到聊天频道
    local mRole = {
        pid = oPlayer:GetPid(),
    }
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = oPlayer:GetPid(),
        channel_list = {
            {gamedefines.BROADCAST_TYPE.TEAM_TYPE, iTeamID, true},
        },
        info = mRole,
    })

    interactive.Send(".broadcast", "channel", "SetupChannel", {
            pid = oPlayer:GetPid(),
            channel_list = {
                {gamedefines.BROADCAST_TYPE.TEAM_TYPE, 1, false},
            },
            info = mRole,
        })

    oSceneMgr:CreateSceneTeam(oPlayer)
end

function CTeamMgr:GetTeam(iTeamID)
    return self.m_mTeamList[iTeamID]
end

function CTeamMgr:RemoveTeam(iTeamID)
    if not self.m_mTeamList[iTeamID] then
        return
    end
    local oTeam = self.m_mTeamList[iTeamID]
    self.m_mTeamList[iTeamID] = nil
    baseobj_delay_release(oTeam)
end

function CTeamMgr:GetInviteMgr(pid)
    local oInviteMgr = self.m_mInviteList[pid]
    if not oInviteMgr then
        oInviteMgr = teaminfo.NewInviteMgr(pid)
        self.m_mInviteList[pid] = oInviteMgr
    end
    return oInviteMgr
end

function CTeamMgr:ValidAddMember(iTeamID,pid)
    local oTeam = self:GetTeam(iTeamID)
    if not oTeam then
        return false
    end
    if oTeam:TeamSize() >= gamedefines.TEAM_MAX_SIZE then
        return false
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return false
    end
    if oPlayer:HasTeam() then
        return false
    end
    return true
end

function CTeamMgr:AddTeamMember(iTeamID,pid,bReEnter)
    local oWorldMgr = global.oWorldMgr
    local oSceneMgr = global.oSceneMgr
    if not self:ValidAddMember(iTeamID,pid) then
        return false
    end
    local oTeam = self:GetTeam(iTeamID)
    local iLeader = oTeam:Leader()
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(iLeader)
    local oSceneMgr = global.oSceneMgr
    local oScene = oLeader.m_oActiveCtrl:GetNowScene()
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    local oMemScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene and oScene:VaildEnter(oPlayer,oLeader) and not (oMemScene:IsVirtual() and oScene.m_iSceneId ~= oMemScene.m_iSceneId)then
        if not oPlayer then
            return false
        end
        local oNowScene = oLeader.m_oActiveCtrl:GetNowScene()
        local mNowPos = oLeader.m_oActiveCtrl:GetNowPos()
        if not oPlayer:GetNowWar() then
            oSceneMgr:TransToLeader(oPlayer,iLeader)
        end
        local oTeamMgr = global.oTeamMgr
        return oTeamMgr:TrueAddMember(iTeamID,pid,bReEnter)
    else
        if self:TrueAddMember(iTeamID,pid,bReEnter) then
            oTeam:ShortLeave(pid)
            return true
        else
            return false
        end
    end

end

function CTeamMgr:TrueAddMember(iTeamID,pid,bReEnter)
    local oTeam = self:GetTeam(iTeamID)
    if not oTeam then
        return false
    end
    if oTeam:TeamSize() >= gamedefines.TEAM_MAX_SIZE then
        return false
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return false
    end
    if oPlayer:HasTeam() then
        return false
    end
    local iLeader = oTeam:Leader()
    local mArgs = {
        model_info = oPlayer:GetModelInfo(),
        grade = oPlayer:GetGrade(),
        school = oPlayer:GetSchool(),
        name = oPlayer:GetName(),
        hp = oPlayer:GetHp(),
        maxhp = oPlayer:GetMaxHp(),
        school_branch = oPlayer:GetSchoolBranch(),
    }
    mArgs["teamid"] = oTeam.m_ID
    local oMember = meminfo.NewMember(pid,mArgs)
    oTeam:AddMember(oMember,bReEnter)
    if oTeam:AutoMatching() then
        self:OnEnterTeam(oTeam, oMember)
        if oTeam:AutoMatchEnough() then
            local oNotifyMgr = global.oNotifyMgr
            oTeam:SetUnAutoMatching()
            oNotifyMgr:Notify(oTeam:Leader(), "队伍人数已满，停止自动匹配")
            interactive.Send(".autoteam", "team", "CancleTeamAutoMatch", {targetid = oTeam:GetTargetID(), teamid = iTeamID})
        end
    end

    -- 注册到聊天频道
    local mRole = {
        pid = oPlayer:GetPid(),
    }
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = oPlayer:GetPid(),
        channel_list = {
            {gamedefines.BROADCAST_TYPE.TEAM_TYPE, iTeamID, true},
        },
        info = mRole,
    })

    interactive.Send(".broadcast", "channel", "SetupChannel", {
            pid = oPlayer:GetPid(),
            channel_list = {
                {gamedefines.BROADCAST_TYPE.TEAM_TYPE, 1, false},
            },
            info = mRole,
        })

    return true
end

function CTeamMgr:ValidApplyTeam(oPlayer,target)
    local oWorldMgr = global.oWorldMgr
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local pid = oPlayer.m_iPid
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(target)
    if not oTarget then
        oNotifyMgr:Notify(pid,"玩家已经离线")
        return
    end
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        oNotifyMgr:Notify(pid,"你已经有队伍了")
        return false
    end
    local iTeamID =  oTarget.m_oActiveCtrl:GetInfo("TeamID")
    if not iTeamID then
        oNotifyMgr:Notify(pid,"该玩家没有队伍")
        return false
    end
    local oTeam = oTeamMgr:GetTeam(iTeamID)
    if not oTeam then
        oNotifyMgr:Notify(pid,"该队伍已经解散")
        return false
    end
    if oTeam:TeamSize() >= gamedefines.TEAM_MAX_SIZE then
        oNotifyMgr:Notify(pid,"该队伍人数已满")
        return false
    end
    local oApplyMgr = oTeam:GetApplyMgr()
    if not oApplyMgr:ValidApply() then
        oNotifyMgr:Notify(pid,"该队伍申请列表已满")
        return false
    end
    return true
end

function CTeamMgr:ApplyTeam(oPlayer,target)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if not self:ValidApplyTeam(oPlayer,target) then
        return
    end
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(target)
    if not oTarget then
        return
    end
    local oTeam = oTarget:HasTeam()
    if not oTeam then
        return
    end
    local pid = oPlayer.m_iPid
    local oApplyMgr = oTeam:GetApplyMgr()
    local mArgs = {
        model_info = oPlayer:GetModelInfo(),
        grade = oPlayer:GetGrade(),
        school = oPlayer:GetSchool(),
        name = oPlayer:GetName(),
        school_branch = oPlayer:GetSchoolBranch(),
    }
    oApplyMgr:AddApply(pid,mArgs)
    oNotifyMgr:Notify(pid,string.format("已申请加入%s的队伍，请耐心等待",oTarget:GetName()))
end

function CTeamMgr:SendTeamApplyInfo(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    local oApplyMgr = oTeam:GetApplyMgr()
    oApplyMgr:SendApplyInfo(oPlayer.m_iPid)
end

function CTeamMgr:ApplyTeamPass(oPlayer,target)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer.m_iPid
    local oTeam = oPlayer:HasTeam()
    local iTeamID = oPlayer:TeamID()
    if not iTeamID then
        return
    end
    if not oTeam then
        return
    end
    if not (pid == oTeam:Leader()) then
        oNotifyMgr:Notify(pid,"队长才有该权限哦")
        return
    end
    if oTeam:TeamSize() >= gamedefines.TEAM_MAX_SIZE then
        oNotifyMgr:Notify(pid,"队伍人数已满")
        return
    end
    local oApplyMgr = oTeam:GetApplyMgr()
    local oApply = oApplyMgr:HasApply(target)
    if not oApply then
        oNotifyMgr:Notify(pid,"申请已失效")
        return
    end
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(target)
    if not oTarget then
        oNotifyMgr:Notify(pid,"玩家已经离线")
        oApplyMgr:RemoveApply(target,pid)
        return
    end
    local oTargetTeam = oTarget:HasTeam()
    if oTargetTeam then
        oNotifyMgr:Notify(pid,"该玩家已加入其它队伍")
        oApplyMgr:RemoveApply(target,pid)
        return
    end

    oApplyMgr:RemoveApply(target,pid)
    local sText = colorstring.FormatColorString("欢迎#role加入队伍", {role = oTarget:GetName()})
    self:AddTeamMember(iTeamID,target)
    local oInviteMgr = self:GetInviteMgr(target)
    oInviteMgr:RemoveInvite(iTeamID, target)
    oNotifyMgr:Notify(target,colorstring.FormatColorString("你已加入#role的队伍", {role = oPlayer:GetName()}))
    self:TeamNotify(oTeam,sText,{[target]=true})
end

function CTeamMgr:TeamNotify(oTeam,sText,mArgs,mExclude)
    local oNotifyMgr = global.oNotifyMgr
    local iTeamID = oTeam:TeamID()
    local lMessage = {"GS2CNotify"}
    local mRoleInfo = {}
    oNotifyMgr:BroadCastTeamNotify(iTeamID,lMessage,sText,mArgs,mRoleInfo,mExclude)
end

function CTeamMgr:HasTeam(pid)
    local iTeamID = self.m_mPid2TeamID[pid]
    if not iTeamID then
        return false
    end
    local oTeam = self:GetTeam(iTeamID)
    if not oTeam then
        return false
    end
    local oMem = oTeam:GetMember(pid)
    if not oMem then
        return false
    end
    return oTeam
end

function CTeamMgr:OnLogin(oPlayer,bReEnter)
    local pid = oPlayer:GetPid()
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        oTeam:OnLogin(oPlayer,bReEnter)
    else
        local oTeam = self:HasTeam(pid)
        if not oTeam then
            oPlayer.m_oActiveCtrl:SetInfo("TeamID",nil)
            local iTargetID = oPlayer.m_oActiveCtrl:GetInfo("auto_targetid")
            local pid = oPlayer:GetPid()
            if iTargetID then
                interactive.Send(".autoteam", "team", "CanclePlayerAutoMatch", {targetid = iTargetID, pid = pid})
                oPlayer:SetAutoMatching(nil)
            end
        else
            oTeam:OnLogin(oPlayer,bReEnter)
        end
    end
    local pid = oPlayer:GetPid()
    local oInviteMgr = self:GetInviteMgr(oPlayer.m_iPid)
    if oInviteMgr then
        oInviteMgr:SendInviteInfo(pid,true)
    end
end

function CTeamMgr:OnLogout(oPlayer)
    local iPid = oPlayer:GetPid()
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        local iTeamID = oTeam.m_ID
        local bOldLeader = oTeam:IsLeader(iPid)
        oTeam:OnLogout(oPlayer)
        if bOldLeader then
            self:AdjustTrapmineLeader(oPlayer, oTeam)
        end
        if self.m_mTeamList[iTeamID] and oTeam:AutoMatching() then
            local iTargetID = oTeam:GetTargetID()
            interactive.Send(".autoteam","team", "OnLeaveTeam", {targetid = iTargetID, teamid = oTeam:TeamID(), pid = oPlayer:GetPid()})
        end
    else
        local iTargetID = oPlayer.m_oActiveCtrl:GetInfo("auto_targetid")
        if iTargetID then
            interactive.Send(".autoteam","team","OnDisconnected",{targetid = iTargetID, pid = oPlayer:GetPid()})
        end
    end
end

function CTeamMgr:AdjustTrapmineLeader(oPlayer, oTeam)
    if oTeam:MemberSize() > 1 and oPlayer:IsTrapmining() then
        local oHuodong = global.oHuodongMgr:GetHuodong("trapmine")
        oHuodong:AdjustTeamLeader(oTeam)
    end
end

function CTeamMgr:StopTeamTrapmine(oPlayer, oTeam)
    if oPlayer:IsTrapmining() then
        local oHuodong = global.oHuodongMgr:GetHuodong("trapmine")
        local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
        oHuodong:StopTrapmine(oPlayer, oScene:MapId())
    end
end

function CTeamMgr:OnDisconnected(oPlayer)
end

function CTeamMgr:OnUpGrade(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        oTeam:OnUpGrade(oPlayer)
    end
end

function CTeamMgr:GetAutoTeamData()
    local res = require "base.res"
    return res["daobiao"]["autoteam"]
end

function CTeamMgr:OnEnterTeam(oTeam,oMem)
    local pid = oMem:MemberID()
    local iTeamID = oTeam:TeamID()
    local iTargetID = oTeam:GetTargetID()
    local mData = oMem:PackAutoTeamInfo()
    interactive.Send(".autoteam","team","OnEnterTeam",{targetid = iTargetID, teamid = iTeamID,pid = pid,mem_info = mData})
end

function CTeamMgr:LeaveTeam(oTeam, oPlayer)
    local oChatMgr = global.oChatMgr
    if oPlayer:IsTrapmining() then
        self:StopTeamTrapmine(oPlayer)
    end
    local iPid = oPlayer:GetPid()
    local sMsg = "#role离开了队伍"
    local mArgs = {
        role = oPlayer:GetName()
    }
    oChatMgr:HandleBroadCastTeamChat(oPlayer,{"GS2CChat"},sMsg,mArgs)
    oTeam:Leave(iPid)
    self:OnLeaveTeam(oTeam:TeamID(),iPid)
end

function CTeamMgr:OnLeaveTeam(iTeamID, pid)
    local oTeam = self:GetTeam(iTeamID)
    if oTeam and oTeam:AutoMatching() then
        local iTargetID = oTeam:GetTargetID()
        interactive.Send(".autoteam","team","OnLeaveTeam",{targetid = iTargetID, teamid = iTeamID, pid = pid})
    end
end

function CTeamMgr:UpdatePlayer(oPlayer,mData)
    local pid = oPlayer.m_iPid
    local iTeamID = oPlayer:TeamID()
    local oTeam = oPlayer:HasTeam()
    local mArgs = {
        name = oPlayer:GetName(),
        grade = oPlayer:GetGrade(),
        school = oPlayer:GetSchool(),
        model_info = oPlayer:GetModelInfo(),
    }
    if oTeam then
        if oTeam:AutoMatching() then
            local iTargetID = oTeam:GetTargetID()
            interactive.Send(".autoteam","team","UpdateTeamMember",{targetid = iTargetID, teamid = iTeamID,pid = pid,mem_info=mArgs})
        end
    else
        --升级后正在匹配中的玩家
    end
    if mData.UpGrade then
        self:OnUpGrade(oPlayer)
    end
end

function CTeamMgr:GetTargetTeamListNetInfo(pid, iTargetID)
    local lTeam = self.m_mTeamList
    local mData = {}
    if next(lTeam) then
        for iTeamID, oTeam in pairs(lTeam) do
            local iTarget = oTeam:GetTargetID()
            local mTeamInfo = oTeam:PackTeamInfo()
            mTeamInfo.applying = 0
            local oApplyMgr = oTeam:GetApplyMgr()
            if oApplyMgr:HasApply(pid) then
                mTeamInfo.applying = 1
            end
            if iTargetID == 0 then
                table.insert(mData, mTeamInfo)
            else
                local res = require "base.res"
                local mTarget = res["daobiao"]["autoteam"][iTarget]
                if iTarget and (iTarget == iTargetID or mTarget.parentId == iTargetID) then
                    table.insert(mData, mTeamInfo)
                end
            end
        end
    end
    local mNet = {}
    mNet["teaminfo"] = mData
    mNet["auto_target"] = iTargetID
    return mNet
end

function CTeamMgr:AddPid2TeamID(pid,iTeamID)
    self.m_mPid2TeamID[pid] = iTeamID
end

function CTeamMgr:ClearPid2TeamID(pid)
    self.m_mPid2TeamID[pid] = nil
end

function CTeamMgr:GetTeamID(iPid)
    return self.m_mPid2TeamID[iPid]
end

function CTeamMgr:ApplyLeaderStartVote(oPlayer, oTeam)
    local res = require "base.res"
    local mRoleColor = res["daobiao"]["othercolor"]["role"]
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local oWorldMgr = global.oWorldMgr
    local pid = oPlayer:GetPid()
    local sTopic = oPlayer:GetName() .. "申请成为队长"
    local func = function (oVoteBox, oPlayer, oTeam, bResult)
        local res = require "base.res"
        local mRoleColor = res["daobiao"]["othercolor"]["role"]
        local sName = oPlayer:GetName()
        if bResult then
            oTeam:SetLeader(pid)
            oNotifyMgr:Notify(pid, "你已成为队长")
            local sText = string.format("%s已成为队长", mRoleColor.color)
            sText = string.format(sText, sName )
            self:TeamNotify(oTeam,sText,{[pid] = true})
            local sMsg = string.format("%s申请队长成功", mRoleColor.color)
            sMsg = string.format(sMsg, sName)
            oChatMgr:HandleTeamChat(oPlayer, sMsg, true)
        else
            oVoteBox:CloseComfirmUI()
            oTeam.m_oVoteBox = nil
            local sMsg = string.format("%s申请队长失败", mRoleColor.color)
            sMsg = string.format(sMsg, sName)
            oChatMgr:HandleTeamChat(oPlayer, sMsg, true)
        end
    end
    local mVoteBox = votebox.NewVoteBox(sTopic, oPlayer, oTeam, func, true, -1)
    mVoteBox.HandleAgree = function (oVoteBox, iTargetPid)
        local oChatMgr = global.oChatMgr
        local oWorldMgr = global.oWorldMgr
        local oNotifyMgr = global.oNotifyMgr
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTargetPid)
        if oTarget then
            local sMsg = string.format("%s同意了%s的申请队长请求", mRoleColor.color, mRoleColor.color)
            sMsg = string.format(sMsg, oTarget:GetName(), oPlayer:GetName() )
            oChatMgr:HandleTeamChat(oPlayer, sMsg, true)
            sMsg = string.format("%s同意了你的申请队长请求", mRoleColor.color)
            sMsg = string.format(sMsg, oTarget:GetName())
            oNotifyMgr:Notify(oPlayer:GetPid(), sMsg)
        end
    end
    mVoteBox.HandleRefuse = function (oVoteBox, iTargetPid)
        local oChatMgr = global.oChatMgr
        local oWorldMgr = global.oWorldMgr
        local oNotifyMgr = global.oNotifyMgr
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTargetPid)
        if oTarget then
            local sMsg = string.format("%s拒绝了%s的申请队长请求", mRoleColor.color, mRoleColor.color)
            sMsg = string.format(sMsg, oTarget:GetName(), oPlayer:GetName() )
            oChatMgr:HandleTeamChat(oPlayer, sMsg, true)
            sMsg = string.format("%s拒绝了你的申请队长请求", mRoleColor.color)
            sMsg = string.format(sMsg, oTarget:GetName())
            oNotifyMgr:Notify(oPlayer:GetPid(), sMsg)
        end
    end
    mVoteBox.CustomConfirmData = function(sTopic)
        local mData = {}
        mData["sContent"] = sTopic
        mData["sConfirm"] = "同意"
        mData["sCancle"] = "拒绝"
        mData["time"] = 30
        mData["defualt"] = 1
        return mData
    end
    mVoteBox:Start()
end

function CTeamMgr:PassInvite(iTeamID,iInviteeID)
    local pid = iInviteeID
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr

    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        oNotifyMgr:Notify(pid,"你已经在队伍中，不能通过邀请")
        return
    end
    local oWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oWar then
        oNotifyMgr:Notify(pid,"你正在战斗中，请稍后再操作")
        return
    end
    local oTeam = oTeamMgr:GetTeam(iTeamID)
    if not oTeam then
        oNotifyMgr:Notify(pid,"队伍已经解散")
        return
    end
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(oTeam.m_iLeader)
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene.m_InvitePass and not oScene.m_InvitePass(oPlayer,oLeader) then
        return
    end
    oScene = oLeader.m_oActiveCtrl:GetNowScene()
    if oScene.m_InvitePass and not oScene.m_InvitePass(oPlayer,oLeader) then
        return
    end

    if oTeamMgr:IsTeamOnWar(oTeam) then
        local iLeader = oTeam:Leader()
        local oLeader = oWorldMgr:GetOnlinePlayerByPid(iLeader)
        local oWar = oLeader:GetNowWar()
        if oWar and oWar:GetData("war_film_id") then
            oNotifyMgr:Notify(pid,"对方正在看录像")
            return
        end
    end
    if oTeam:TeamSize() >= gamedefines.TEAM_MAX_SIZE then
        oNotifyMgr:Notify(pid,"该队伍人数已满")
        return
    end
    local sText = colorstring.FormatColorString("#role加入到你的队伍中", {role = oPlayer:GetName()})
    oTeamMgr:TeamNotify(oTeam,sText,{[pid]=pid})
    oTeamMgr:AddTeamMember(iTeamID,pid)
    


    if oLeader then
        local sText = colorstring.FormatColorString("你已加入#role的队伍", {role = oLeader:GetName()})
        oNotifyMgr:Notify(pid,sText)
    end
end

function CTeamMgr:RefuseInvite(iTeamID,iInviteeID,mInvitorList,sMessage)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oInviteeTarget  = oWorldMgr:GetOnlinePlayerByPid(iInviteeID)
    local sText = ""
    sText = string.format("%s委婉地拒绝了你的邀请",oInviteeTarget:GetName())
    if sMessage and sMessage ~= "" then
        sText = sText.."，并表示：".."\n[ff7200]"..sMessage
    end
    for _,value in pairs(mInvitorList) do
        oNotifyMgr:Notify(value,sText)
    end
end

function CTeamMgr:AddWarEndFunc(iPid,fFunc,mArgs)
    self.m_fWarEndFunc[iPid] = {fFunc,mArgs}
end

function CTeamMgr:WarFightEnd(iPid,sTempName,iResult,mEscapeList)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local oTeam = oPlayer:HasTeam()
        if oTeam then
            oTeam:WarFightEnd()
        end
        if self.m_fWarEndFunc[iPid] then
            local fFunc,mArgs = table.unpack(self.m_fWarEndFunc[iPid])
            mArgs = mArgs or {}
            fFunc(table.unpack(mArgs))
            self.m_fWarEndFunc[iPid] = nil
        end
    end
end

function CTeamMgr:OnMemPartnerInfoChange(iPid,mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        local iParPos = mArgs["pos"]
        mArgs  = net.Mask("base.SimplePartner", mArgs)
        local memlist = oTeam:OnlineMember()
        oTeam:BroadCast(memlist,"GS2CMemPartnerInfoChange",{["pid"] = iPid,["partner_info"] = mArgs})
    end
end

function CTeamMgr:AddLilianPlayer(iPid)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local bFindTeam = false
    for _,oTeam in pairs(self.m_mTeamList) do
        --TODO:测试用，回头要改回4人
        if oTeam.m_Type == gamedefines.TEAM_CREATE_TYPE.LILIAN and oTeam:OnlineMemberSize() < 4 then
            local mArgs = {
                model_info = oPlayer:GetModelInfo(),
                grade = oPlayer:GetGrade(),
                school = oPlayer:GetSchool(),
                name = oPlayer:GetName(),
                hp = oPlayer:GetHp(),
                maxhp = oPlayer:GetMaxHp(),
                school_branch = oPlayer:GetSchoolBranch(),
            }
            mArgs["teamid"] = oTeam.m_ID
            local oMember = meminfo.NewMember(iPid,mArgs)
            oTeam:AddMember(oMember)
            if self:IsTeamOnWar(oTeam) then
                oNotifyMgr:Notify(iPid,"已加入修行队列，下轮将并肩作战")
            end
            bFindTeam = true
            break
        end
    end
    if not bFindTeam then
        self:CreateLlilianTeam(iPid)
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("lilian")
        oHuodong:RefreshMonster(oPlayer)
        local oTask = oPlayer.m_oTaskCtrl:GetLilianTask()
        oTask:AutoFindLilianPath()
    end
end

function CTeamMgr:CreateLlilianTeam(iPid)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oSceneMgr = global.oSceneMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    if oPlayer:HasTeam() then
        oNotifyMgr:Notify(iPid,"你已经有队伍了，无法创建")
        return
    end
    local mArgs = {
        model_info = oPlayer:GetModelInfo(),
        grade = oPlayer:GetGrade(),
        school = oPlayer:GetSchool(),
        name = oPlayer:GetName(),
        hp = oPlayer:GetHp(),
        maxhp = oPlayer:GetMaxHp(),
        school_branch = oPlayer:GetSchoolBranch(),
    }
    local iTeamID = self:DispatchId()
    local oTeam = lilianteamobj.NewTeam(iPid, iTeamID)
    mArgs["teamid"] = iTeamID
    local oMember = meminfo.NewMember(iPid,mArgs)
    oTeam:AddMember(oMember)
    self.m_mTeamList[iTeamID] = oTeam
    self.m_mPid2TeamID[iPid] = iTeamID

    oSceneMgr:CreateSceneTeam(oPlayer)
end

function CTeamMgr:ReOrganizeLilianTeam(oTeam)
    local bMatchNewTeam = false
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    for key,oTeamTmp in pairs(self.m_mTeamList) do
        if oTeamTmp.m_Type == gamedefines.TEAM_CREATE_TYPE.LILIAN and (oTeamTmp:OnlineMemberSize() + oTeam:OnlineMemberSize()) < 5 and oTeamTmp.m_ID ~= oTeam.m_ID then
            local mMem = {}
            local mTmp = oTeam:OnlineMember()
            for pid,_ in pairs(mTmp) do
                local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
                local mArgs = {
                    model_info = oPlayer:GetModelInfo(),
                    grade = oPlayer:GetGrade(),
                    school = oPlayer:GetSchool(),
                    name = oPlayer:GetName(),
                    hp = oPlayer:GetHp(),
                    maxhp = oPlayer:GetMaxHp(),
                    school_branch = oPlayer:GetSchoolBranch(),
                }
                mArgs["teamid"] = oTeam.m_ID
                local oMember = meminfo.NewMember(pid,mArgs)
                table.insert(mMem,oMember)
            end
            local bObserver = self:IsTeamOnWar(oTeamTmp)
            for _,oMember in pairs(mMem) do
                oTeam:Leave(oMember.m_ID,"重新匹配到新的修行小队")
                oTeamTmp:AddMember(oMember)
                if bObserver then
                    oNotifyMgr:Notify(oMember.m_ID,"已加入修行队列，下轮将并肩作战")
                end
                self.m_mPid2TeamID[oMember.m_ID] = oTeamTmp:TeamID()
            end
            bMatchNewTeam = true
        end
    end
    if not bMatchNewTeam then
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("lilian")
        local oLeader = oWorldMgr:GetOnlinePlayerByPid(oTeam:Leader())
        oHuodong:RefreshMonster(oLeader)
        if #oTeam.m_lMember > 1 then
            for i = 2,#oTeam.m_lMember do
                oTeam:SynClientNpc(oTeam.m_lMember[i].m_ID)
            end
        end
        oTeam:ContinueLilian()
    end
end

function CTeamMgr:IsTeamOnWar(oTeam)
    if not oTeam then
        return false
    end
    local oWorldMgr = global.oWorldMgr
    local iLeader = oTeam:Leader()
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(iLeader)
    if not oLeader then
        return false
    end
    local oWar = oLeader:GetNowWar()
    if not oWar then
        return false
    end
    return true
end

function CTeamMgr:InviteFriendList(oPlayer)
    local oFriend = oPlayer:GetFriend()
    local mFriends = oFriend:GetFriends()
    local mNet = {}
    local oWorldMgr = global.oWorldMgr
    for sPid,_ in pairs(mFriends) do
        local oFri = oWorldMgr:GetOnlinePlayerByPid(tonumber(sPid))
        if not oFri or oFri:HasTeam() then
            table.insert(mNet,{pid=tonumber(sPid),can_invite = 0})
        else
            table.insert(mNet,{pid=tonumber(sPid),can_invite = 1})
        end
    end
    oPlayer:Send("GS2CInviteFriendList",{friend_list=mNet})
end

function CTeamMgr:CheckLeaderDull(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if not oTeam or not oTeam:IsLeader(oPlayer.m_iPid) then
        return
    end
    if oPlayer:IsDull(90) then
        oTeam:LeaderSleep(oPlayer,1)
    end
end


---在线测试接口
function CTeamMgr:CheckPlayerTeamInfo(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iPlayerTeamID = oPlayer:TeamID()
    local iTeamMgrTeamID = self.m_mPid2TeamID[iPid]
    print("Playerobj-TeamID:",iPlayerTeamID)
    print("TeamMgr-TeamID:",iTeamMgrTeamID)
    local oPlayerTeam = self:GetTeam(iPlayerTeamID)
    local oTeamMgrTeam = self:GetTeam(iTeamMgrTeamID)
    local mMem1 = oPlayerTeam:GetTeamMember()
    local mMem2 = oTeamMgrTeam:GetTeamMember()
    print("Playerobj-TeamMem",mMem1)
    print("TeamMgr-TeamMem",mMem2)
end