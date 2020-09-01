--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local handleteam = import(service_path("team.handleteam"))
local gamedefines = import(lualib_path("public.gamedefines"))
local colorstring = require "public.colorstring"
local res = require "base.res"

function C2GSCreateTeam(oPlayer,mData)
    local bValidAddTeam,iErrCode = oPlayer:ValidAddTeam()
    local oNotifyMgr = global.oNotifyMgr
    if not bValidAddTeam then
        if iErrCode == gamedefines.ADDTEAMFAIL_CODE.GRADE_LIMIT then
            local iOpenGrade = tonumber(res["daobiao"]["global_control"]["team"]["open_grade"])
            oNotifyMgr:Notify(oPlayer.m_iPid,string.format("角色需要达到%d级可开启组队系统",iOpenGrade))
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PERSONAL_TASK then
            oNotifyMgr:Notify(oPlayer.m_iPid,"请先完成当前任务")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.IN_HOUSE then
            oNotifyMgr:Notify(oPlayer:GetPid(),"宅邸中，无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PREPARE_TERRAWARS then
            oNotifyMgr:Notify(oPlayer:GetPid(),"据点战准备中，无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.CONVOY then
            oNotifyMgr:Notify(oPlayer:GetPid(),"帝都宅急便护送中，无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.SCENE_QUESTION then
            oNotifyMgr:Notify(oPlayer:GetPid(), '该玩家正在“学霸去哪儿”的考场中，无法邀请。')
        end
        return
    end
    if oPlayer.m_oActiveCtrl:GetNowScene():QueryLimitRule("team") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止组队")
        return
    end
     if oPlayer.m_RefuseTeamOperate then
        NotifyRefuseMsg(oPlayer:GetPid(),oPlayer,"CreateTeam")
        return
    end
    if oPlayer.m_InArenaGameMatch or oPlayer.m_InArenaGame or oPlayer.m_oStateCtrl:GetState(1007) then
        oNotifyMgr:Notify(oPlayer:GetPid(),"正在比武场战斗中,不能创建队伍")
        return
    end

    local iTargetID = mData.auto_target
    local iMinGrade = mData.min_grade
    local iMaxGrade = mData.max_grade
    local mTarget
    if iMaxGrade >= iMinGrade then
        mTarget = {
            auto_target = iTargetID,
            min_grade = iMinGrade,
            max_grade = iMaxGrade,
        }
    else
        mTarget = {
            auto_target = iTargetID,
            min_grade = iMaxGrade,
            max_grade = iMinGrade,
        }
    end
    if oPlayer:HasTeam() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"你已经有队伍了，无法创建")
        return
    end
    local iPid = oPlayer.m_iPid
    local oTeamMgr = global.oTeamMgr
    if oPlayer:GetNowWar() then
        local fFunc = function(iP, mT)
            oTeamMgr:CreateTeam(iP, mT)
        end
        oTeamMgr:AddWarEndFunc(iPid,fFunc,{iPid, mTarget})
        oNotifyMgr:Notify(oPlayer:GetPid(),"创建队伍成功、战斗结束后生效")
    else
        oTeamMgr:CreateTeam(iPid, mTarget)
    end

end

function C2GSApplyTeam(oPlayer,mData)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
     if oPlayer:HasTeam() then
        oNotifyMgr:Notify(oPlayer.m_iPid,"你已经在队伍中")
        return
    end
    local bValidAddTeam,iErrCode = oPlayer:ValidAddTeam()
    if not bValidAddTeam then
        if iErrCode == gamedefines.ADDTEAMFAIL_CODE.GRADE_LIMIT then
            local iOpenGrade = tonumber(res["daobiao"]["global_control"]["team"]["open_grade"])
            oNotifyMgr:Notify(oPlayer.m_iPid,string.format("角色需要达到%d级可开启组队系统",iOpenGrade))
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PERSONAL_TASK then
            oNotifyMgr:Notify(oPlayer.m_iPid,"请先完成当前任务")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.IN_HOUSE then
            oNotifyMgr:Notify(oPlayer:GetPid(),"宅邸中，无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PREPARE_TERRAWARS then
            oNotifyMgr:Notify(oPlayer:GetPid(),"据点战准备中，无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.CONVOY then
            oNotifyMgr:Notify(oPlayer:GetPid(),"帝都宅急便护送中，无法进行组队")
        end
        return
    end
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene:QueryLimitRule("team") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止组队")
        return
    end

    if oPlayer.m_RefuseTeamOperate then
        NotifyRefuseMsg(oPlayer:GetPid(),oPlayer,"ApplyTeam")
        return
    end
    local target = mData["pid"]
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(target)
    if not oTarget then
        return
    end

    local oScene = oTarget.m_oActiveCtrl:GetNowScene()
    if oScene:QueryLimitRule("team") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"对方场景禁止组队")
        return
    end
    if oScene.m_TeamApply and not oScene.m_TeamApply(oPlayer,oTarget) then
        return
    end
    local oTeam = oTarget:HasTeam()
    if not oTeam then
        oNotifyMgr:Notify(oPlayer.m_iPid,"队伍已解散")
        return
    end
    if oTeam:TeamSize() >= 4 then
        oNotifyMgr:Notify(oPlayer.m_iPid,"队伍人数已满，无法申请")
        return
    end

    local oTeamMgr = global.oTeamMgr
    local oChatMgr = global.oChatMgr

    if oTeam:ValidAutoMatchMem(oPlayer) then
        oTeamMgr:AddTeamMember(oTeam:TeamID(),oPlayer:GetPid())
        local oLeader = oWorldMgr:GetOnlinePlayerByPid(oTeam:Leader())
        if oLeader then
            local sText = colorstring.FormatColorString("你已加入#role的队伍", {role = oLeader:GetName()})
            oNotifyMgr:Notify(oPlayer:GetPid(),sText)
        end
        local sText = colorstring.FormatColorString("欢迎#role加入队伍", {role = oPlayer:GetName()})
        oTeamMgr:TeamNotify(oTeam,sText,{pid=oPlayer:GetPid()})
        oChatMgr:HandleTeamChat(oPlayer, sText, true)
        return
    end
    oTeamMgr:ApplyTeam(oPlayer,target)
end

function C2GSCancelApply(oPlayer, mData)
    local iTeamID = mData["teamid"]
    local pid = oPlayer:GetPid()
    local oTeamMgr = global.oTeamMgr
    local oTeam = oTeamMgr:GetTeam(iTeamID)
    local oNotifyMgr = global.oNotifyMgr
    if oTeam then
        local oApplyMgr = oTeam:GetApplyMgr()
        if oApplyMgr:HasApply(pid) then
            oApplyMgr:RemoveApply(pid)
        end
        local iLeader = oTeam:Leader()
        local oWorldMgr = global.oWorldMgr
        local oLeader= oWorldMgr:GetOnlinePlayerByPid(iLeader)
        oNotifyMgr:Notify(pid, string.format("已取消向%s队伍的申请", oLeader:GetName()))
    else
        oNotifyMgr:Notify(pid, "队伍已经解散，请重新刷新")
    end
end

function C2GSTeamApplyInfo(oPlayer)
    local oTeamMgr = global.oTeamMgr
    oTeamMgr:SendTeamApplyInfo(oPlayer)
end

function C2GSApplyTeamPass(oPlayer,mData)
    local target = mData["pid"]
    local oTeamMgr = global.oTeamMgr
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local bValidAddTeam,iErrCode = oPlayer:ValidAddTeam()

    if not bValidAddTeam then
        if iErrCode == gamedefines.ADDTEAMFAIL_CODE.PERSONAL_TASK then
            oNotifyMgr:Notify(oPlayer.m_iPid,"请先完成当前任务")
        end
        return
    end

    local oTarget = oWorldMgr:GetOnlinePlayerByPid(target)
    if oTarget then
        local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
        if oScene.m_ApplyTeamPass and not oScene.m_ApplyTeamPass(oPlayer,oTarget) then
            return
        end
        if oScene:QueryLimitRule("team") then
            oNotifyMgr:Notify(oPlayer:GetPid(),"场景禁止组队操作")
            return
        end

        local oScene = oTarget.m_oActiveCtrl:GetNowScene()
        if oTarget.m_InArenaGameMatch or oTarget.m_InArenaGame or oTarget.m_oStateCtrl:GetState(1007)  then
            oNotifyMgr:Notify(oPlayer:GetPid(),"对方正在比武场战斗中")
            return
        end

        if oScene:QueryLimitRule("team") then
            oNotifyMgr:Notify(oPlayer:GetPid(),"对方场景禁止组队")
            return
        end
        if oTarget:IsTrapmining() then
            oNotifyMgr:Notify(oPlayer:GetPid(),string.format("#R%s#n已开始进行探索，无法邀请入队", oTarget:GetName()))
            return
        end
        if oTarget:IsInHouse() then
            oNotifyMgr:Notify(oPlayer:GetPid(),"该玩家沉迷宅邸，不能自拔")
            return
        end
        if oTarget.m_RefuseTeamOperate then
            NotifyRefuseMsg(oPlayer:GetPid(),oTarget,"TeamPass")
            return
        end
        if oTarget.m_oActiveCtrl:GetData("task_show",0) == 1 then
            oNotifyMgr:Notify(oPlayer:GetPid(),"玩家正忙")
            return
        end
        if oTarget:IsOnConvoy() then
            oNotifyMgr:Notify(oPlayer:GetPid(),"帝都宅急便护送中，无法进行组队")
            return
        end
        if oScene.m_ApplyTeamPass and not oScene.m_ApplyTeamPass(oPlayer,oTarget) then
            return
        end
    end
    oTeamMgr:ApplyTeamPass(oPlayer,target)
end

function NotifyRefuseMsg(pid,oTarget,sKey)
    local oNotifyMgr = global.oNotifyMgr
    local mOperate = oTarget.m_RefuseTeamOperate["operate"]
    local mData = mOperate[sKey] or (mOperate["all"] or {})
    oNotifyMgr:Notify(pid,mData["notify"])
end


function C2GSClearApply(oPlayer,mData)
    local pid = oPlayer.m_iPid
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    if not oTeam:IsLeader(pid) then
        oNotifyMgr:Notify(pid,"你不是队长，不能清除申请信息")
        return
    end
    local oApplyMgr = oTeam:GetApplyMgr()
    oApplyMgr:ClearApply(pid)
end

function C2GSInviteTeam(oPlayer,mData)
    local target = mData["target"]
    local oTeamMgr = global.oTeamMgr
    local oTeam = oPlayer:HasTeam()
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local bValidAddTeam,iErrCode = oPlayer:ValidAddTeam()
    if not bValidAddTeam then
        if iErrCode == gamedefines.ADDTEAMFAIL_CODE.GRADE_LIMIT then
            local iOpenGrade = tonumber(res["daobiao"]["global_control"]["team"]["open_grade"])
            oNotifyMgr:Notify(oPlayer.m_iPid,string.format("角色需要达到%d级可开启组队系统",iOpenGrade))
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PERSONAL_TASK then
            oNotifyMgr:Notify(oPlayer.m_iPid,"请先完成当前任务")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.IN_HOUSE then
            oNotifyMgr:Notify(oPlayer:GetPid(),"宅邸中，无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PREPARE_TERRAWARS then
            oNotifyMgr:Notify(oPlayer:GetPid(),"据点战准备中，无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.CONVOY then
            oNotifyMgr:Notify(oPlayer:GetPid(),"帝都宅急便护送中，无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.SCENE_QUESTION then
            oNotifyMgr:Notify(oPlayer:GetPid(),"邀请人收到提示：该玩家正在“学霸去哪儿”的考场中，无法邀请。")
        end
        return
    end
    if target == oPlayer.m_iPid then
        oNotifyMgr:Notify(oPlayer.m_iPid,"不能邀请自己")
        return
    end
    if oTeam and oTeam:TeamSize() >= 4 then
        oNotifyMgr:Notify(oPlayer.m_iPid,"队伍已满，无法邀请")
        return
    end
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene:QueryLimitRule("team") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止组队")
        return
    end

    local oTarget = oWorldMgr:GetOnlinePlayerByPid(target)
    if not oTarget then
        return
    end
    if oScene.m_InviteTeam and not oScene.m_InviteTeam(oPlayer,oTarget) then
        return
    end

    if oTarget:HasTeam() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"邀请失败，对方已经存在队伍")
        return
    end
    if oTarget:IsTrapmining() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"对方正在探索中，无法进行组队")
        return
    end
    if oTarget:IsInHouse() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该玩家沉迷宅邸，不能自拔")
        return
    end
    if oTarget.m_RefuseTeamOperate then
        NotifyRefuseMsg(oPlayer:GetPid(),oTarget,"InviteTeam")
        return
    end
    local bValidAddTeam,iErrCode = oTarget:ValidAddTeam()
    if not bValidAddTeam then
        if iErrCode == gamedefines.ADDTEAMFAIL_CODE.GRADE_LIMIT then
            oNotifyMgr:Notify(oPlayer.m_iPid,"该玩家未开启组队系统")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PERSONAL_TASK then
            oNotifyMgr:Notify(oPlayer.m_iPid,"玩家正处于任务状态中")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.LILIANING then
            oNotifyMgr:Notify(oPlayer.m_iPid,"该玩家正在修行中，请稍后再邀请")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PREPARE_TERRAWARS then
            oNotifyMgr:Notify(oPlayer:GetPid(),"该玩家正在据点战准备中，无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.CONVOY then
            oNotifyMgr:Notify(oPlayer:GetPid(),"帝都宅急便护送中，无法进行组队")
        end
        return
    end
    if oTarget then
        if oTarget.m_InArenaGameMatch or oTarget.m_InArenaGame  or oTarget.m_oStateCtrl:GetState(1007) then
            oNotifyMgr:Notify(oPlayer:GetPid(),"对方正在比武场战斗中")
            return
        end

        if oTarget.m_oActiveCtrl:GetNowScene():QueryLimitRule("team") then
            oNotifyMgr:Notify(oPlayer:GetPid(),"对方场景禁止组队")
            return
        end

        if oTarget.m_RefuseTeamOperate then
            NotifyRefuseMsg(oPlayer:GetPid(),oTarget,"nviteTeam")
            return
        end

    end

    if oTarget and oTarget:GetFriend():IsShield(oPlayer:GetPid()) then
        return
    end
    local oInviteMgr = oTeamMgr:GetInviteMgr(target)
    oInviteMgr:AddInvitor(oPlayer,mData)
end

function C2GSInviteAll(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local bValidAddTeam,iErrCode = oPlayer:ValidAddTeam()
    if not bValidAddTeam then
        if iErrCode == gamedefines.ADDTEAMFAIL_CODE.PERSONAL_TASK then
            oNotifyMgr:Notify(oPlayer.m_iPid,"请先完成当前任务")
        end
        return
    end
    local mTargetList = mData["target_list"]
    local oTeamMgr = global.oTeamMgr
    local auto_target = mData["auto_target"]
    local min_grade = mData["min_grade"]
    local max_grade = mData["max_grade"]
    local iPid = oPlayer:GetPid()
    local res = require "base.res"
    local iOpenGrade = tonumber(res["daobiao"]["global_control"]["team"]["open_grade"])
    for i = 1,#mTargetList do
        local target = mTargetList[i]
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(target)
        if oTarget then
            local oScene = oTarget.m_oActiveCtrl:GetNowScene()
            if oTarget:GetGrade() < iOpenGrade then
                oNotifyMgr:Notify(iPid, string.format("%s 未开启组队系统，无法邀请", oTarget:GetName()))
            elseif oTarget:IsInHouse() then
                oNotifyMgr:Notify(iPid, string.format("%s 沉迷宅邸，无法邀请", oTarget:GetName()))
            elseif oTarget:IsTrapmining() then
                oNotifyMgr:Notify(iPid, string.format("%s 正在探索暗雷，无法邀请", oTarget:GetName()))
            elseif oTarget:IsOnConvoy() then
                oNotifyMgr:Notify(iPid,"帝都宅急便护送中，无法进行组队")
            elseif oScene.m_InviteTeam and not oScene.m_InviteTeam(oPlayer,oTarget) then
                --
            else
                local oInviteMgr = oTeamMgr:GetInviteMgr(target)
                local mInviteInfo = {
                    target = target,
                    auto_target = auto_target,
                    min_grade = min_grade,
                    max_grade = max_grade,
                }
                oInviteMgr:AddInvitor(oPlayer,mInviteInfo)
            end
        end
    end
end

function C2GSTeamInviteInfo(oPlayer,mData)
    local pid = oPlayer.m_iPid
    local oTeamMgr = global.oTeamMgr
    local oInviteMgr = oTeamMgr:GetInviteMgr(pid)
    if not oInviteMgr then
        return
    end
    oInviteMgr:SendInviteInfo(pid)
end

function C2GSInvitePass(oPlayer,mData)
    local iTeamID = mData["teamid"]
    local pid = oPlayer.m_iPid
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
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
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene:QueryLimitRule("team") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止组队")
        return
    end
    if oPlayer:IsTrapmining() then
        oNotifyMgr:Notify(pid,"探索中，无法进行组队")
        return
    end
    if oPlayer:IsInHouse() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"宅地中，无法进行组队")
        return
    end
    if oPlayer.m_RefuseTeamOperate then
        NotifyRefuseMsg(oPlayer:GetPid(),oPlayer,"InvitePass")
        return
    end
    local oInviteMgr = oTeamMgr:GetInviteMgr(pid)
    local mData = oInviteMgr:HasInvite(iTeamID)
    if not mData then
        return
    end
    local oTeam = oTeamMgr:GetTeam(iTeamID)
    if not oTeam then
        oInviteMgr:RemoveInvite(iTeamID,pid)
        oNotifyMgr:Notify(pid,"队伍已经解散")
        return
    end
    local oLeader = oTeam:GetTeamLeader()
    if oScene.m_InvitePass and not oScene.m_InvitePass(oPlayer,oLeader) then
        return
    end
    if oTeam:TeamSize() >= 4 then
        oInviteMgr:RemoveInvite(iTeamID,pid)
        oNotifyMgr:Notify(pid,"该队伍人数已满")
        return
    end
    if oInviteMgr:IsOutTime(iTeamID) then
        oInviteMgr:RemoveInvite(iTeamID,pid)
        return
    end

    local oScene = oLeader.m_oActiveCtrl:GetNowScene()
    if oScene.m_InvitePass and not oScene.m_InvitePass(oPlayer,oLeader) then
        return
    end

    local iInvitor = mData.pid
    oInviteMgr:RemoveInvite(iTeamID,pid)
    if oTeam:IsLeader(iInvitor) then
        oTeamMgr:AddTeamMember(iTeamID,pid)
        local oLeader = oWorldMgr:GetOnlinePlayerByPid(iInvitor)
        if oLeader then
            local sText = colorstring.FormatColorString("你已加入#role的队伍", {role = oLeader:GetName()})
            oNotifyMgr:Notify(pid,sText)
        end
        local sText = colorstring.FormatColorString("欢迎#role加入队伍", {role = oPlayer:GetName()})
        oTeamMgr:TeamNotify(oTeam,sText,{[pid]=pid})
        oChatMgr:HandleTeamChat(oPlayer, sText, true)
    else
        local iLeader = oTeam:Leader()
        if not iLeader then
            return
        end
        oTeamMgr:ApplyTeam(oPlayer,iLeader)
        oNotifyMgr:Notify(pid,"已接受邀请，请等待队长同意")
    end
end

function C2GSClearInvite(oPlayer)
    local pid = oPlayer.m_iPid
    local oTeamMgr = global.oTeamMgr
    local oInviteMgr = oTeamMgr:GetInviteMgr(pid)
    if not oInviteMgr then
        return
    end
    oInviteMgr:ClearInviteInfo(pid)
end

function C2GSShortLeave(oPlayer,mData)
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local pid = oPlayer.m_iPid
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene:QueryLimitRule("shortleave") then
        oNotifyMgr:Notify(pid,"该场景不能暂离")
        return
    end
    if oTeam:IsLeader(pid) then
        oNotifyMgr:Notify(pid,"队长不能暂离")
        return
    end
    oTeam:ShortLeave(oPlayer.m_iPid)
    --local sMsg = colorstring.FormatColorString("#role暂时离队", {role=oPlayer:GetName()})
    --oChatMgr:HandleTeamChat(oPlayer, sMsg, true)
    local sMsg = "#role暂时离队"
    local mArgs = {
        role = oPlayer:GetName(),
    }
    oChatMgr:HandleBroadCastTeamChat(oPlayer,{"GS2CChat",},sMsg,mArgs)
    oNotifyMgr:Notify(pid,"你暂离了队伍")
end

function C2GSLeaveTeam(oPlayer,mData)
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local pid = oPlayer.m_iPid
    local iTeamID = oPlayer:TeamID()
    if not iTeamID then
        return
    end
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    if oPlayer:GetNowWar() then
        return
    end
    oTeamMgr:LeaveTeam(oTeam, oPlayer)
end

function C2GSLeaveLiLianTeam(oPlayer,mData)
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oNowWar then
        return
    end
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local pid = oPlayer.m_iPid
    local iTeamID = oPlayer:TeamID()
    if not iTeamID then
        return
    end
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end

    ---oPlayer:SetAutoMatching(0, false)
    --local sText = colorstring.FormatColorString("#role离开了队伍", {role = oPlayer:GetName()})
    --oChatMgr:HandleTeamChat(oPlayer, sText, true)
    local sMsg = "#role离开了队伍"
    local mArgs = {
        role = oPlayer:GetName(),
    }
    oChatMgr:HandleBroadCastTeamChat(oPlayer,{"GS2CChat"},sMsg,mArgs)
    oTeam:Leave(pid)
    oTeamMgr:OnLeaveTeam(iTeamID,pid)
end

function C2GSKickOutTeam(oPlayer,mData)
    local target = mData["target"]
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
    local pid = oPlayer.m_iPid
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    if not oTeam:IsLeader(pid) then
        return
    end
    handleteam.KickoutTeam(oPlayer, target)

end

function C2GSBackTeam(oPlayer,mData)
    local pid = oPlayer.m_iPid
    local oChatMgr = global.oChatMgr
    local oNotifyMgr = global.oNotifyMgr
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    if not oTeam:IsShortLeave(pid) then
        return
    end
    local bValidAddTeam,iErrCode = oPlayer:ValidAddTeam()
    if not bValidAddTeam then
        if iErrCode == gamedefines.ADDTEAMFAIL_CODE.PERSONAL_TASK then
            oNotifyMgr:Notify(oPlayer.m_iPid,"请先完成当前任务")
            return
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PREPARE_TERRAWARS then
            oNotifyMgr:Notify(oPlayer:GetPid(),"据点战准备中，暂时无法归队")
        end
    end
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene:QueryLimitRule("team") and oScene:QueryLimitRule("allowback") ~= 1 then
        oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止组队")
        return
    end

    if oScene.m_BackTeam and not oScene.m_BackTeam(oPlayer) then
        return
    end
    if oPlayer.m_RefuseTeamOperate then
        NotifyRefuseMsg(oPlayer:GetPid(),oPlayer,"BackTeam")
        return
    end
    local oLeader = global.oWorldMgr:GetOnlinePlayerByPid(oTeam:Leader())
    local oLScene = oLeader.m_oActiveCtrl:GetNowScene()
    if oLScene.m_BackTeam and not oLScene.m_BackTeam(oPlayer) then
        return
    end
    if oScene:IsVirtual() and oScene.m_iSceneId ~= oLeader.m_oActiveCtrl:GetNowSceneID() then
        local oCbMgr = global.oCbMgr
        local sContent = "队长不在同一个场景中，是否回归？\n(回归后将离开该场景)"
        local mData = {
            sContent = sContent,
            sConfirm = "是",
            sCancle = "否",
            default = 0,
            time = 30,
        }
        local mData = oCbMgr:PackConfirmData(nil, mData)
        local func = function (oPlayer,mData)
            local iAnswer = mData["answer"]
            if iAnswer == 1 then
                local oTeam = oPlayer:HasTeam()
                if not oTeam then
                    return
                end
                local oLeader = global.oWorldMgr:GetOnlinePlayerByPid(oTeam:Leader())
                local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
                if oScene:IsVirtual() and oScene.m_iSceneId ~= oLeader.m_oActiveCtrl:GetNowSceneID() then
                    if oScene.m_fLeaveCallBack then
                        oScene.m_fLeaveCallBack(oPlayer)
                    end
                end
                TrueBackTeam(oPlayer)
            end
        end
        oCbMgr:SetCallBack(oPlayer:GetPid(),"GS2CConfirmUI",mData,nil,func)
        return
    end
    TrueBackTeam(oPlayer)
end

function TrueBackTeam(oPlayer)
    local pid = oPlayer.m_iPid
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    local bSuccess = oTeam:BackTeam(pid)
    local oChatMgr = global.oChatMgr
    local oNotifyMgr = global.oNotifyMgr
    if bSuccess then
        local oHuodongMgr =global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("trapmine")
        oHuodong:BackTeam(oPlayer)
        --local sMsg = colorstring.FormatColorString("#role回到队伍", {role = oPlayer:GetName()})
        --oChatMgr:HandleTeamChat(oPlayer, sMsg, true)
        local sMsg = "#role回到队伍"
        local mArgs = {
            role = oPlayer:GetName()
        }
        oChatMgr:HandleBroadCastTeamChat(oPlayer,{"GS2CChat"},sMsg,mArgs)
        oNotifyMgr:Notify(pid,"你回到了队伍")
    end
end

function C2GSSetLeader(oPlayer,mData)
    local target = mData["target"]
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oChatMgr = global.oChatMgr
    local pid = oPlayer.m_iPid
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    if not oTeam:IsLeader(pid) then
        return
    end
    if oTeam:IsShortLeave(target) then
        oNotifyMgr:Notify(pid,"需要对方为归队状态才能移交队长")
        return
    end
    if not oTeam:IsTeamMember(target) then
        oNotifyMgr:Notify(pid,"需要对方为归队状态才能移交队长")
        return
    end
    handleteam.SetLeader(oPlayer, target)
end

function C2GSTeamSummon(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local oCbMgr = global.oCbMgr
    local iTarget = mData.pid
    local pid = oPlayer.m_iPid
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        oNotifyMgr:Notify(pid,"只有队长可以操作")
        return
    end
    if not oTeam:IsLeader(pid) then
        oNotifyMgr:Notify(pid,"只有队长可以操作")
        return
    end
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene:QueryLimitRule("team") and oScene:QueryLimitRule("allowback") ~= 1 then
        oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止归队")
        return
    end
    if oPlayer.m_RefuseTeamOperate then
        NotifyRefuseMsg(oPlayer:GetPid(),oPlayer,"TeamSummon")
        return
    end
    local mShortMem = oTeam:GetShortLeave()
    for memid,_ in pairs(mShortMem) do
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(memid)

        if oTarget and (iTarget == 0 or iTarget == memid)then
            if oTarget.m_oActiveCtrl:GetNowWar() then
                oNotifyMgr:Notify(pid,string.format("%s 正在战斗",oTarget:GetName()))
                return
            end
            local oScene = oTarget.m_oActiveCtrl:GetNowScene()
            if oScene:QueryLimitRule("team") and oScene:QueryLimitRule("allowback") ~= 1 then
                oNotifyMgr:Notify(oPlayer:GetPid(),"对方场景禁止组队")
                return
            end
            local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
            if oScene:IsVirtual() and oPlayer.m_oActiveCtrl:GetNowSceneID() ~= oTarget.m_oActiveCtrl:GetNowSceneID() then
                if oScene.m_sCallBackFailTips then
                    local sTip = string.gsub(oScene.m_sCallBackFailTips,"$name",{["$name"]=oTarget:GetName()})
                    oNotifyMgr:Notify(pid,sTip)
                    return
                end
            end
            if oTarget.m_RefuseTeamOperate then
                NotifyRefuseMsg(oPlayer:GetPid(),oTarget,"TeamSummon")
                return
            end
            local iBeenCalled = oTarget.m_oActiveCtrl:GetInfo("been_called",0)
            if iBeenCalled == 0 then
                oTarget.m_oActiveCtrl:SetInfo("been_called",1)
                local sContent = "队长召唤你立即归队"
                if oTarget.m_oActiveCtrl:GetNowScene():IsVirtual() then
                    sContent = sContent.."\n(回归后将离开该场景)"
                end
                local mData = {
                    sContent = sContent,
                    sConfirm = "归队",
                    sCancle = "取消",
                    default = 0,
                    time = 30,
                }
                local iSceneId = oPlayer.m_oActiveCtrl:GetNowSceneID()
                local mData = oCbMgr:PackConfirmData(nil, mData)
                local func = function (oTarget,mData)
                    local iAnswer = mData["answer"]
                    if iAnswer == 1 then
                        local oScene = oTarget.m_oActiveCtrl:GetNowScene()
                        if oScene:IsVirtual() and oScene.m_fLeaveCallBack and oScene.m_iSceneId ~= iSceneId then
                            oScene.m_fLeaveCallBack(oTarget)
                        end
                        TeamBack(oTarget)
                    else
                        oNotifyMgr:Notify(pid,string.format("%s 正忙",oTarget:GetName()))
                    end
                    oTarget.m_oActiveCtrl:SetInfo("been_called",0)
                end
                oCbMgr:SetCallBack(oTarget:GetPid(),"GS2CConfirmUI",mData,nil,func)
            end
        end
    end
end

function TeamBack(oPlayer)
    local pid = oPlayer.m_iPid
    local oNotifyMgr = global.oNotifyMgr
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    if not oTeam:IsShortLeave(pid) then
        return
    end
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene:QueryLimitRule("team") and oScene:QueryLimitRule("allowback") ~= 1 then
        oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止归队")
        return
    end
    if oPlayer.m_RefuseTeamOperate then
        NotifyRefuseMsg(oPlayer:GetPid(),oPlayer,"TeamBack")
        return
    end
    if oScene.m_BackTeam and not oScene.m_BackTeam(oPlayer) then
        return
    end
    local bSuccess = oTeam:BackTeam(pid)
    if bSuccess then
        oNotifyMgr:Notify(pid,"你回到了队伍")
    end
end

function C2GSApplyLeader(oPlayer)
    local res = require "base.res"
    local mRoleColor = res["daobiao"]["othercolor"]["role"]
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oChatMgr = global.oChatMgr
    local oTeamMgr = global.oTeamMgr
    local pid = oPlayer:GetPid()
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    if oTeam:IsLeader(pid) then
        return
    end
    local iNow = get_time()
    local iApplyLeaderEnd = oTeam.m_iApplyLeaderTime or 0
    if iApplyLeaderEnd > iNow then
        oNotifyMgr:Notify(pid, "申请太频繁，请稍后再试")
        return
    end
    local mVoteBox = oTeam.m_oVoteBox
    if mVoteBox and not mVoteBox.m_bEnd then
        local iTargetPid = mVoteBox.m_iPID
        local oTarget = oWorldMgr:GetOnlinePlayerByPid(iTargetPid)
        if oTarget then
            local sMsg = string.format("请等待%s申请队长结果", mRoleColor.color)
            sMsg = string.format(sMsg, oTarget:GetName())
            oNotifyMgr:Notify(pid, sMsg)
        end
    else
        oTeam.m_oVoteBox = nil
        oTeamMgr:ApplyLeaderStartVote(oPlayer, oTeam)
        oTeam.m_iApplyLeaderTime = get_time()
    end
end

function C2GSTeamAutoMatch(oPlayer,mData)
    local res = require "base.res"
    local iMatch = mData.team_match
    local iMinGrade = mData.min_grade
    local iMaxGrade = mData.max_grade
    local iTargetID = mData.auto_target
    local pid = oPlayer:GetPid()
    local oNotifyMgr = global.oNotifyMgr
    if iMaxGrade < iMinGrade then
        return
    end
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene and oScene:QueryLimitRule("team") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止组队")
        return
    end
    if oScene and oScene:QueryLimitRule("banautoteam") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止自动组队")
        return
    end

    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    if not oTeam:IsLeader(pid) then
        oNotifyMgr:Notify(pid,"只有队长可以操作")
        return
    end
    if iTargetID == 0 then
        if oTeam:AutoMatching() then
            oTeam:CancleAutoMatch()
        end
        oNotifyMgr:Notify(pid, "请先设置匹配目标")
        return
    end
    local mTarget = res["daobiao"]["autoteam"][iTargetID]
    if not mTarget then
        oNotifyMgr:Notify(pid, "请先设置匹配目标")
        return
    end
    if (mTarget.is_parent == 1 and mTarget.is_show == 0)then
        return
    end
    if oTeam:AutoMatching() then
        oTeam:CancleAutoMatch()
    end
    local mTarget = {auto_target = iTargetID, min_grade = iMinGrade, max_grade = iMaxGrade, team_match = iMatch}
    if iMatch == 0 then
        oTeam:SetAutoMatchTarget(mTarget)
        oTeam:SetUnAutoMatching()
    else
        if oTeam:ValidAutoMatch(pid,mTarget) then
            oTeam:SetAutoMatching()
            oTeam:StartAutoMatch(pid, mTarget)
            oNotifyMgr:Notify(pid,"已开始自动匹配，请稍候")
        end
    end
end

function C2GSTeamCancelAutoMatch(oPlayer, mData)
    local oTeam = oPlayer:HasTeam()
    local pid = oPlayer:GetPid()
    local oNotifyMgr = global.oNotifyMgr
    if oTeam then
        if oTeam:IsLeader(pid) then
            oTeam:CancleAutoMatch()
            oNotifyMgr:Notify(pid,"已取消自动匹配")
        else
            oNotifyMgr:Notify(pid, "只有队长可以操作")
        end
    else
        oNotifyMgr:Notify(pid, "队伍不存在")
    end
end

function C2GSPlayerAutoMatch(oPlayer, mData)
    local iTargetID = mData["auto_target"]
    local min_grade = mData["min_grade"] or 0
    local max_grade = mData["max_grade"] or 150
    local res = require "base.res"
    local mTarget = res["daobiao"]["autoteam"][iTargetID]
    local pid = oPlayer:GetPid()
    local oNotifyMgr = global.oNotifyMgr
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene and oScene:QueryLimitRule("banautoteam") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"当前场景禁止自动组队")
        return
    end
    local bValidAddTeam,iErrCode = oPlayer:ValidAddTeam()
    if not bValidAddTeam then
        if iErrCode == gamedefines.ADDTEAMFAIL_CODE.GRADE_LIMIT then
            local iOpenGrade = tonumber(res["daobiao"]["global_control"]["team"]["open_grade"])
            oNotifyMgr:Notify(oPlayer.m_iPid,string.format("角色需要达到%d级可开启组队系统",iOpenGrade))
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PERSONAL_TASK then
            oNotifyMgr:Notify(oPlayer.m_iPid,"请先完成当前任务")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.PREPARE_TERRAWARS then
            oNotifyMgr:Notify(oPlayer:GetPid(),"据点战准备中，无法进行组队")
        elseif iErrCode == gamedefines.ADDTEAMFAIL_CODE.CONVOY then
            oNotifyMgr:Notify(oPlayer:GetPid(),"帝都宅急便护送中，无法进行组队")
        end
        return
    end
    if iTargetID == 1 then
        local iGrade = oPlayer:GetGrade()
        if iGrade < 50 then
            oNotifyMgr:Notify(oPlayer.m_iPid,"50级开启该功能")
            return
        end
    end

    local oTeam = oPlayer:HasTeam()
    if oTeam then
        oNotifyMgr:Notify(pid, "您已经在队伍中")
        return
    end
    if oPlayer:GetAutoMatchTargetID() then
        oNotifyMgr:Notify(pid, "您已经在匹配队列中")
        return
    end
    if (mTarget and (mTarget.is_parent == 0 or (mTarget.is_parent == 1 and mTarget.is_show==1))) or  iTargetID ==1 then
        local mArgs = {
            target = iTargetID,
            model_info = oPlayer:GetModelInfo(),
            grade = oPlayer:GetGrade(),
            school = oPlayer:GetSchool(),
            name = oPlayer:GetName(),
            min_grade = min_grade,
            max_grade = max_grade,
            school_branch = oPlayer:GetSchoolBranch(),
        }
        oPlayer:SetAutoMatching(iTargetID)
        interactive.Send(".autoteam","team","PlayerStartAutoMatch",{targetid = iTargetID,min_grade = min_grade,max_grade = max_grade, pid=pid, mem_info=mArgs})
        oPlayer:Send("GS2CPlayerMatchTargetInfo",{target_info = {auto_target = iTargetID,min_grade = min_grade,max_grade = max_grade,team_match = 1}})
    else
        oNotifyMgr:Notify(pid, "目标活动不存在")
    end
end

function C2GSPlayerCancelAutoMatch(oPlayer, mData)
    local iTargetID = oPlayer.m_oActiveCtrl:GetInfo("auto_targetid")
    local iNotTips = mData.tips
    local pid = oPlayer:GetPid()
    if iTargetID then
        interactive.Send(".autoteam", "team", "CanclePlayerAutoMatch", {targetid = iTargetID, pid = pid})
        oPlayer:SetAutoMatching(nil)
    end
    local oNotifyMgr = global.oNotifyMgr
    if not iNotTips == 1 then
        oNotifyMgr:Notify(pid, "已取消自动匹配")
    end
end

function C2GSGetTargetTeamInfo(oPlayer, mData)
    local iTargetID = mData["auto_target"]
    local res = require "base.res"
    local mTarget = res["daobiao"]["autoteam"][iTargetID]
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local iRefreshTime = oPlayer.m_oActiveCtrl:GetInfo("refresh_team", 0)
    local iNow = get_time()
    if iRefreshTime > iNow then
        oNotifyMgr:Notify(oPlayer:GetPid(), "刷新太频繁，请稍后再试")
    end
    if iTargetID == 0 or (mTarget and (mTarget.is_parent == 0 or (mTarget.is_parent == 1 and mTarget.is_show==1))) then
        local mNet = oTeamMgr:GetTargetTeamListNetInfo(oPlayer:GetPid(), iTargetID)
        interactive.Send(".autoteam", "team", "CountAutoMatch", {targetid = iTargetID,pid = oPlayer:GetPid()})
        oPlayer:Send("GS2CTargetTeamInfoList", mNet)
    end
end

function C2GSTeamInfo(oPlayer, mData)
    local oTeamMgr = global.oTeamMgr
    local oNotifyMgr = global.oNotifyMgr
    local pid = oPlayer:GetPid()
    local iTeamID = mData["teamid"]
    local oTeam = oTeamMgr:GetTeam(iTeamID)
    if not oTeam then
        oNotifyMgr:Notify(pid, "队伍已经解散")
        return
    end

    local mTeamInfo = oTeam:PackTeamInfo()
    mTeamInfo.applying = 0
    local oApplyMgr = oTeam:GetApplyMgr()
    if oApplyMgr:HasApply(pid) then
        mTeamInfo.applying = 1
    end
    local mNet = {}
    mNet["teaminfo"] = mTeamInfo
    oPlayer:Send("GS2CTargetTeamInfo", mNet)
end

function C2GSTakeOverLeader(oPlayer,mData)
    local bValid,sErrCode = handleteam.VaildTakeOverLeader(oPlayer)
    if bValid then
        handleteam.TakeOverLeader(oPlayer)
    else
        if sErrCode and sErrCode == "low_friendship" then
            local oNotifyMgr = global.oNotifyMgr
            oNotifyMgr:Notify(oPlayer.m_iPid,"好友度不足，无法接管")
        end
    end
end

function C2GSSetTeamTarget(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        oNotifyMgr:Notify(oPlayer:GetPid(), "队伍已经解散")
        return
    end
    if not oTeam:IsLeader(oPlayer:GetPid()) then
        oNotifyMgr:Notify(oPlayer:GetPid(), "只有队长可以操作")
        return
    end
    local iTargetID = mData.auto_target
    local iMinGrade = mData.min_grade
    local iMaxGrade = mData.max_grade
    local mTarget = {
        auto_target = iTargetID,
        min_grade = iMinGrade,
        max_grade = iMaxGrade,
    }
    oTeam:SetAutoMatchTarget(mTarget)
end

function C2GSLeaderSleep(oPlayer,mData)
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    local iStatus = mData.status
    oTeam:LeaderSleep(oPlayer,iStatus,true)
end

function C2GSChangeTeamSetting(oPlayer,mData)
    local mSetting = mData["setting_info"]
    local mNewSetting = {}
    for _,v in pairs(mSetting) do
        local sOption = v["option"]
        local iValue = v["value"]
        mNewSetting[sOption] = iValue
    end
    oPlayer.m_oBaseCtrl:SetSystemSetting({teamsetting = mNewSetting})
end

function C2GSGetMingleiTeamInfo(oPlayer,mData)
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    local iType = mData.type
    local mNet = {}
    local oWorldMgr = global.oWorldMgr
    local mMem = oTeam:GetTeamMember()
    for _,iMemId in pairs(mMem) do
        local oMem = oWorldMgr:GetOnlinePlayerByPid(iMemId)
        if oMem then
            local iF = oMem.m_oToday:Query("minglei_fighttime",0)
            local iB = oMem.m_oToday:Query("minglei_buytime",0)
            local sF = string.format("%d/%d",iF>0 and iF or 0,10+iB)
            local sB = string.format("%d/2",(2-iB)>0 and (2-iB) or 0)
            table.insert(mNet,{pid=iMemId,name=oMem:GetName(),fight_time=sF,buy_time = sB})
        end
    end
    if iType == 1 then
        oPlayer:Send("GS2CTeamMingleiInfo",{minglei_info=mNet})
    elseif iType == 2 then
        local oChatMgr = global.oChatMgr
        local sMsg = "喵萌茶会玩法检测结果：\n"
        for _,info in pairs(mNet) do
            if string.sub(info.fight_time,1,1) == "0" then
                sMsg = sMsg..info.name..": ".."次数不足".."\n"
            else
                sMsg = sMsg..info.name..": "..info.fight_time.."\n"
            end
        end
        oChatMgr:HandleTeamChat(oPlayer, sMsg,  true)
    end
end

function C2GSTrapmineTeamInfo(oPlayer, mData)
    local oWorldMgr = global.oWorldMgr
    local oTeam = oPlayer:HasTeam()
    if oTeam then
        local res = require "base.res"
        local mGlobal = res["daobiao"]["global"]["trapmine_box_monster_cd"]
        local iCDVal =  tonumber(mGlobal.value)
        local lMem = oTeam:GetTeamMember()
        local mNet = {}
        for _, iMemId in ipairs(lMem) do
            local oMem = oWorldMgr:GetOnlinePlayerByPid(iMemId)
            if oMem then
                local iTime = oMem.m_oThisTemp:Query("trapmine_box_monster_cd", 0)
                local iCD = math.max(0, iCDVal - (get_time() - iTime))
                table.insert(mNet, {pid = iMemId, name=oMem:GetName(), cd = iCD})
            end
        end
        oPlayer:Send("GS2CTeamTrapmineInfo", {trapmine_info=mNet})
    end
end

function C2GSInviteFriendList(oPlayer,mData)
    local oTeamMgr  = global.oTeamMgr
    oTeamMgr:InviteFriendList(oPlayer)
end

function C2GSAwardWarBattleCommand(oPlayer,mData)
    local iPid = mData["target"]
    local iOp = mData["op"]
    local oWorldMgr = global.oWorldMgr
    if not oPlayer:IsTeamLeader() then
        return
    end
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    if not oTeam:GetMember(iPid) then
        return
    end
    oTeam:WarBattleCmd(iPid,iOp)
end

function C2GSGetTargetMemList(oPlayer,mData)
    local iPid = oPlayer.m_iPid
    local iTargetID = mData.target
    interactive.Send(".autoteam","team","GetTargetMemList",{targetid = iTargetID,pid = iPid})
end