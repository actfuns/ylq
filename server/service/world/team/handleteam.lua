local global = require "global"
local interactive = require "base.interactive"
local colorstring = require "public.colorstring"

local frienddefines = import(service_path("offline/defines"))
local votebox = import(service_path("team.votebox"))

function AddTask(iPid,oTask)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        oNotifyMgr:Notify(iPid,"没有队伍，不能添加任务")
        return
    end
    if not oTeam:IsLeader(iPid) then
        return
    end
    if oTeam:GetTask(oTask.m_ID) then
        return
    end
    oTask:Config(iPid)
    oTask:Setup()
    oTask:SetTeamID(oTeam.m_ID)
    oTeam:AddTask(oTask)
end

function RemoveTask(iPid,iTask)
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    local oTask = oTeam:GetTask(iTask)
    if not oTask then
        return
    end
    oTeam:RemoveTask(iTask)
end

--申请队长 BEGIN
function RefreshApplyLeaderInfo(pid, oTeam, iActive)
    if oTeam:IsLeader(pid) then
        local memlist = oTeam:GetTeamMember()
        if #memlist > 0 then
            iActive = iActive or 1
            if iActive == 0 then
                _LeaderNotActive(pid, oTeam)
            end
            local mNet = {}
            mNet["active"] = iActive or 1
            local oWorldMgr = global.oWorldMgr
            for _, memid in ipairs(memlist) do
                local oPlayer = oWorldMgr:GetOnlinePlayerByPid(memid)
                if oPlayer and pid ~= memid then
                    oPlayer:Send("GS2CLeaderActiveStatus", mNet)
                end
            end
        end
    end
end

function _LeaderNotActive(pid, oTeam)
    local oCbMgr = global.oCbMgr
    local oWorldMgr = global.oWorldMgr
    local iTeamID = oTeam:TeamID()
    local mData = {}
    mData["sContent"] = "队长当前无反应，是否接管队长？"
    mData["sConfirm"] = "申请队长"
    mData["sCancle"] = "取消"
    mData["time"] = 30
    mData["default"] = 0
    mData = oCbMgr:PackConfirmData(nil, mData)
    local memlist = oTeam:GetTeamMember()
    local func = function (oPlayer, mData)
        local iAnswer = mData["answer"]
        if iAnswer == 1 then
            local oTeamMgr = global.oTeamMgr
            local oTeam = oTeamMgr:GetTeam(iTeamID)
            ApplyLeader(oPlayer:GetPid(), oTeam)
        end
    end
    oTeam.m_mSessionidx = {}
    for _, memid in pairs(memlist) do
        if memid ~= pid then
            local iSessionidx= oCbMgr:SetCallBack(memid,"GS2CConfirmUI",mData,nil ,func)
            oTeam.m_mSessionidx[memid] = iSessionidx
        end
    end
end

function ApplyLeader(pid, oTeam)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oUIMgr = global.oUIMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if oPlayer then
        if  oTeam:IsTeamMember(pid) then
            local iNow = get_time()
            local iApplyLeaderEnd = oPlayer.m_oActiveCtrl:GetInfo("apply_leader", 0)
            if iApplyLeaderEnd > iNow then
                oNotifyMgr:Notify(pid, "申请太频繁，请稍后再试")
                return 
            end
            local oLeader = oWorldMgr:GetOnlinePlayerByPid(oTeam:Leader())
            if oLeader and oLeader:GetActive() == 1 then
                oNotifyMgr:Notify(pid, "队长离开10分钟时，才能申请成为队长")
                return
            end
            local mVoteBox = oTeam.m_oVoteBox
            if mVoteBox and not mVoteBox.m_bEnd then
                local sMsg
                local mArgs
                local oTarget = mVoteBox:GetPlayer()
                if pid == oTarget:GetPid() then
                    sMsg = "你已发出申请，请等待"
                else
                    --sMsg = colorstring.FormatColorString("请等待#role申请队长结果", {role = oTarget:GetName()})
                    sMsg = "请等待#role申请队长结果"
                    mArgs = {
                        role = oTarget:GetName()
                    }
                end
                oNotifyMgr:BroadCastNotify(pid,{"GS2CNotify"},sMsg,mArgs)
                --oNotifyMgr:Notify(pid, sMsg)
            else
                local lSessionidx = oTeam.m_mSessionidx or {}
                lSessionidx[pid] = nil
                for memid, sessionidx in pairs(lSessionidx) do
                    local oMem = oWorldMgr:GetOnlinePlayerByPid(memid)
                    if oMem then
                        oUIMgr:GS2CCloseConfirmUI(oMem, sessionidx)
                    end
                end
                lSessionidx = nil
                oTeam.m_mSessionidx = nil
                _ApplyLeaderStartVote(oTeam, oPlayer)
                oPlayer.m_oActiveCtrl:SetInfo("apply_leader", iNow + 30)
            end
        else
            oNotifyMgr:Notify(pid, "你不在队伍中")
        end
    end
end

function _ApplyLeaderStartVote(oTeam, oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local pid = oPlayer:GetPid()
    local sName = oPlayer:GetName()
    local sTopic = sName .. "申请成为队长"
    local mVoteBox = votebox.NewVoteBox(sTopic, oPlayer, oTeam, _ApplyLeaderResult, true, -1)
    mVoteBox.HandleAgree = _HandleAgree
    mVoteBox.HandleRefuse = _HandleRefuse
    mVoteBox.CustomConfirmData = _CustomConfirmData
    oTeam.m_oVoteBox = mVoteBox
    mVoteBox:Start()
    --local sMsg = colorstring.FormatColorString("#role申请成为队长，全部成员同意则可申请成功", {role = sName})
    --oChatMgr:HandleTeamChat(oPlayer, sMsg, true)
    oNotifyMgr:Notify(pid, "你已发出申请，请等待")
    local sMsg = "#role申请成为队长，全部成员同意则可申请成功"
    local mArgs = {
        role = sName
    }
    oChatMgr:HandleBroadCastTeamChat(oPlayer,{"GS2CChat"},sMsg,mArgs)
end

function _ApplyLeaderResult(oPlayer, oTeam, bResult)
    if not oPlayer then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local oTeamMgr = global.oTeamMgr
    local pid = oPlayer:GetPid()
    local sName = oPlayer:GetName()
    if bResult then
        oTeam:SetLeader(pid)
        oNotifyMgr:Notify(pid, "你已成为队长")
        local sMsg = "#role已成为队长"
        local mArgs = {
            role = sName
        }
        oTeamMgr:TeamNotify(oTeam,sMsg,mArgs,{[pid] = true})
        --local sMsg = colorstring.FormatColorString("#role已成为队长", {role = sName})
        --oTeamMgr:TeamNotify(oTeam, sMsg,{[pid] = true})
        sMsg = "#role申请队长成功"
        mArgs = {
            role = sName
        }
        oChatMgr:HandleBroadCastTeamChat(oPlayer,{"GS2CChat"},sMsg,mArgs)
        --sMsg = colorstring.FormatColorString("#role申请队长成功", {role = sName})
        --oChatMgr:HandleTeamChat(oPlayer, sMsg, true)
    else
        --local sMsg = colorstring.FormatColorString("#role申请队长失败", {role = sName})
        --oChatMgr:HandleTeamChat(oPlayer, sMsg, true)
        local sMsg = "#role申请队长失败"
        local mArgs = {
            role = sName
        }
        oChatMgr:HandleBroadCastTeamChat(oPlayer,{"GS2CChat"},sMsg,mArgs)
    end
end

function _HandleAgree(oVoteBox, pid)
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(pid)
    local oPlayer = oVoteBox:GetPlayer()
    if oTarget and oPlayer then
        local sName, sTarget = oPlayer:GetName(), oTarget:GetName()
        local sMsg = "#role同意#role的申请队长请求"
        local mArgs = {
            role = {sTarget, sName},
        }
        oChatMgr:HandleBroadCastTeamChat(oPlayer,{"GS2CChat"},sMsg,mArgs)
        --local sMsg = colorstring.FormatColorString("#role同意#role的申请队长请求", {role = {sTarget, sName}})
        --oChatMgr:HandleTeamChat(oPlayer, sMsg, true)
        sMsg = "#role同意了你的申请队长请求"
        mArgs = {
            role = sTarget
        }
        oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),{"GS2CNotify"},sMsg,mArgs)
        --sMsg = colorstring.FormatColorString("#role同意了你的申请队长请求", {role = sTarget})
        --oNotifyMgr:Notify(oPlayer:GetPid(), sMsg)
    end
end

function _HandleRefuse(oVoteBox, pid)
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(pid)
    local oPlayer = oVoteBox:GetPlayer()
    if oTarget and oPlayer then
        local sName, sTarget = oPlayer:GetName(), oTarget:GetName()
        local sMsg = "#role拒绝了#role的申请队长请求"
        local mArgs = {
            role = {sTarget, sName}
        }
        oChatMgr:HandleBroadCastTeamChat(oPlayer,{"GS2CChat",},sMsg,mArgs)
        --local sMsg = colorstring.FormatColorString("#role拒绝了#role的申请队长请求", {role = {sTarget, sName}})
        --oChatMgr:HandleTeamChat(oPlayer, sMsg, true)
        sMsg = "#role拒绝了你的申请队长请求"
        mArgs = {
            role = sTarget
        }
        oNotifyMgr:BroadCastNotify(oPlayer:GetPid(),{"GS2CNotify"},sMsg,mArgs)
        --sMsg = colorstring.FormatColorString("#role拒绝了你的申请队长请求", {role = sTarget})
        --oNotifyMgr:Notify(oPlayer:GetPid(), sMsg)
    end
end

function _CustomConfirmData(sTopic)
        local mData = {}
        mData["sContent"] = sTopic
        mData["sConfirm"] = "同意"
        mData["sCancle"] = "拒绝"
        mData["time"] = 30
        mData["default"] = 1
        return mData
end

function KickoutTeam(oPlayer, iTarget)
    local bRet = false
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then 
        TrueKickout(oPlayer, iTarget)
        return bRet
    end
    local iPid = oPlayer.m_iPid
    local oCbMgr = global.oCbMgr
    local mData = {}
    mData["sContent"] = "你是否要请离"..oTarget:GetName()
    mData["sConfirm"] = "确认"
    mData["sCancle"] = "取消"
    mData["time"] = 30
    mData["default"] = 0
    mData = oCbMgr:PackConfirmData(target, mData)
    local func = function (oPlayer, mData)
        local iAnswer = mData["answer"]
        if iAnswer  ~= 1 then 
            return
        end
        local oTeam = oPlayer:HasTeam()
        local oWar = oPlayer.m_oActiveCtrl:GetNowWar()
        if oWar then
            local fCallback = function(mArgs)
                local oWorldMgr = global.oWorldMgr
                local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
                TrueKickout(oP, iTarget)
            end
            oTeam:AddWarEndFunc(fCallback)
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(oPlayer.m_iPid,"战斗结束后生效")
        else
            TrueKickout(oPlayer, iTarget)
        end
        bRet = true
    end
    oCbMgr:SetCallBack(oPlayer:GetPid(),"GS2CConfirmUI",mData,nil,func)
    return bRet
end

function  TrueKickout(oPlayer, iTarget)
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
    local oCbMgr = global.oCbMgr
    local pid = oPlayer.m_iPid
    local iTeamID = oPlayer:TeamID()
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    oTeam:Leave(iTarget)
    oTeamMgr:OnLeaveTeam(oPlayer:TeamID(), iTarget)
    oNotifyMgr:Notify(iTarget,string.format("你被请离了%s的队伍",oPlayer:GetName()))
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if oTarget then
        local sMsg = "#role被请离队伍"
        local mArgs = {
            role = oTarget:GetName()
        }
        oChatMgr:HandleBroadCastTeamChat(oPlayer,{"GS2CChat"},sMsg,mArgs)
        local iTargetAutoTargetInfo = oTarget.m_oActiveCtrl:GetInfo("auto_targetid")
        if iTargetAutoTargetInfo and iTargetAutoTargetInfo == 1 then
            _ContinueAutoMatch(oTarget,1)
        end
    end
end

function _ContinueAutoMatch(oPlayer,iTargetID)
    local mArgs = {
            target = iTargetID,
            model_info = oPlayer:GetModelInfo(),
            grade = oPlayer:GetGrade(),
            school = oPlayer:GetSchool(),
            name = oPlayer:GetName(),
        }
    oPlayer:SetAutoMatching(iTargetID)
    interactive.Send(".autoteam","team","PlayerStartAutoMatch",{targetid = iTargetID, pid=oPlayer.m_iPid, mem_info=mArgs})
end

function SetLeader(oPlayer, iTarget)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTarget)
    if not oTarget then 
        return
    end
    local iPid = oPlayer.m_iPid
    local iTargetAutoTargetInfo = oTarget.m_oActiveCtrl:GetInfo("auto_targetid")
    if iTargetAutoTargetInfo and iTargetAutoTargetInfo == 1 then
        oNotifyMgr:Notify(oPlayer.m_iPid,"不可将队长移交给爱心助力玩家")
        return
    end
    local oCbMgr = global.oCbMgr
    local mData = {}
    mData["sContent"] = "你确定要将队长移交给"..oTarget:GetName()
    mData["sConfirm"] = "确认"
    mData["sCancle"] = "取消"
    mData["time"] = 30
    mData["default"] = 0
    mData = oCbMgr:PackConfirmData(target, mData)
    local func = function(oPlayer, mData)
        local iAnswer = mData["answer"]
        if iAnswer ~= 1 then 
            return
        end
        local oTeam = oPlayer:HasTeam()
        local oWar = oPlayer.m_oActiveCtrl:GetNowWar()
        if oWar then
            local fCallback = function(mArgs)
                local oWorldMgr = global.oWorldMgr
                local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
                local oT = oWorldMgr:GetOnlinePlayerByPid(iTarget)
                TrueSetLeader(oP, oT)
            end
            oTeam:AddWarEndFunc(fCallback)
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(oPlayer.m_iPid,"战斗结束后生效")
        else
            local oTarget2 = global.oWorldMgr:GetOnlinePlayerByPid(iTarget)
            if oTarget2 then
                TrueSetLeader(oPlayer, oTarget2)
            end
        end
        
    end
    oCbMgr:SetCallBack(oPlayer:GetPid(),"GS2CConfirmUI",mData,nil,func)
end

function TrueSetLeader(oPlayer, oTarget)
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local oTeam = oPlayer:HasTeam()
    if not oTeam and not oTeam:IsLeader(oPlayer.m_iPid) then
        return
    end
    local iTarget = oTarget:GetPid()
    oTeam:SetLeader(iTarget) 
    oNotifyMgr:Notify(target,"已被任命为队长")
    local sMsg = string.format("#B%s#n将队长移交给了#B%s#n",oPlayer:GetName(),oTarget:GetName())
    oNotifyMgr:Notify(iTarget, sMsg)
    oChatMgr:HandleTeamChat(oPlayer, sMsg, true)
end
-- END

function VaildTakeOverLeader(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return false
    end
    local iLeader = oTeam:Leader()
    local oFriend = oPlayer:GetFriend()
    if oFriend:HasRelation(iLeader,frienddefines.RELATION_COUPLE) or oFriend:HasRelation(iLeader,frienddefines.RELATION_BROTHER) then
        return true
    end
    local iFriendShip = oFriend:GetFriendDegree(iLeader)
    if iFriendShip < 100 then
        return false,"low_friendship"
    end
    return true
end

function TakeOverLeader(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        local iPid = oPlayer.m_iPid
        local oWorldMgr = global.oWorldMgr
        local oCbMgr = global.oCbMgr
        local oLeader = oWorldMgr:GetOnlinePlayerByPid(oTeam.m_iLeader)
        local sContent = string.format("#B%s#n请求接管队长\n是否同意？",oPlayer:GetName())
        local mNet = {
            sContent = sContent,
            sConfirm = "同意",
            sCancle = "拒绝",
            default = 0,
            time = 30,
        }
        mNet = oCbMgr:PackConfirmData(nil, mNet)
        local func = function(oResponse,mData) 
            local oWorldMgr = global.oWorldMgr
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            local oTeam = oPlayer:HasTeam()
            if not oTeam then
                return
            end
            if mData.answer == 1 then
                local iLeader = oTeam:Leader()
                local oLeader = oWorldMgr:GetOnlinePlayerByPid(iLeader)
                local oWar = oLeader.m_oActiveCtrl:GetNowWar()
                if oWar then
                    local fCallback = function(mArgs)
                        local oWorldMgr = global.oWorldMgr
                        local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
                        TrueTakeOverLeader(oP)
                    end
                    oTeam:AddWarEndFunc(fCallback)
                    local oNotifyMgr = global.oNotifyMgr
                    oNotifyMgr:Notify(oPlayer.m_iPid,"战斗结束后生效")
                else
                    TrueTakeOverLeader(oPlayer) 
                end
                
            end
        end
        oCbMgr:SetCallBack(oLeader.m_iPid,"GS2CConfirmUI",mNet,nil,func)
    end
end

function TrueTakeOverLeader(oPlayer)
    local oTeam = oPlayer:HasTeam()
    local oNotifyMgr = global.oNotifyMgr
    if oTeam then
        oTeam:SetLeader(oPlayer.m_iPid) 
        local memlist = oTeam:GetTeamMember()
        for _,iMemId in pairs(memlist) do
            if iMemId == oPlayer.m_iPid then
                oNotifyMgr:Notify(iMemId,"你成功接管了本队队长")
            else
                --local sMsg = colorstring.FormatColorString("#role成为本队的队长", {role = oPlayer:GetName()})
                --oNotifyMgr:Notify(iMemId,sMsg)
                local sMsg = "#role成为本队的队长"
                local mArgs = {
                    role = oPlayer:GetName()
                }
                oNotifyMgr:BroadCastNotify(iMemId,{"GS2CNotify"},sMsg,mArgs)
            end
        end
    end
end
