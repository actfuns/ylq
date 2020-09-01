-- import module
local huodongbase = import(service_path("huodong.huodongbase"))
local res = require "base.res"
local global = require "global"
local loadtask = import(service_path("task/loadtask"))
local templ = import(service_path("templ"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

local TEAM_MEMCNT_LIMIT = 3
local TRAIN_TASK_ID = 502

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "每日修行"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()

end

function CHuodong:do_look(oPlayer,oNpc)
    local iGrade = global.oWorldMgr:QueryControl("dailytrain","open_grade")
    if iGrade > oPlayer:GetGrade() then
        self:GS2CDialog(oPlayer.m_iPid,oNpc,300)
    else
        self:GS2CDialog(oPlayer.m_iPid,oNpc,100)
    end
end

function CHuodong:GetDialogBaseData()
    local mData = res["daobiao"]["huodong"][self.m_sName]["dialog"]
    assert(mData,string.format("Not Dialog Config:%s",self.m_sName))
    return mData
end

function CHuodong:GetDialogInfo(iDialog)
    local mData = self:GetDialogBaseData()
    for _,info in pairs(mData) do
        if info["dialog_id"] == iDialog then
            return table_deep_copy(info)
        end
    end
    assert(false,string.format("not dialog:%d",iDialog))
end

function CHuodong:TransString(iPid,oNpc,sContent,mArgs)
    if not sContent then
        return
    end
    if string.find(sContent,"$lefttime") then
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        local iLeftTime = oPlayer.m_oHuodongCtrl:GetTrainRewardTime()
        sContent = string.gsub(sContent,"$lefttime",iLeftTime)
    end
    if string.find(sContent,"$level") then
        local iGrade = global.oWorldMgr:QueryControl("dailytrain","open_grade")
        sContent = string.gsub(sContent,"$level",iGrade)
    end
    
    return sContent
end

function CHuodong:GS2CDialog(iPid,oNpc,iDialog)
    local mDialogInfo = self:GetDialogInfo(iDialog)
    if not mDialogInfo then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local m = {}
    m["dialog"] = {{
        ["type"] = mDialogInfo["type"],
        ["pre_id_list"] = mDialogInfo["pre_id_list"],
        ["content"] = self:TransString(iPid,oNpc,mDialogInfo["content"]),
        ["voice"] = mDialogInfo["voice"],
        ["last_action"] = mDialogInfo["last_action"],
        ["next"] = mDialogInfo["next"],
        ["ui_mode"] = mDialogInfo["ui_mode"],
        ["status"] = mDialogInfo["status"],
    }}
    m["dialog_id"] = iDialog
    m["npc_id"] = oNpc.m_ID
    m["npc_name"] = oNpc:Name()
    m["shape"] = oNpc:Shape()
    local iNpcId = oNpc.m_ID
    local sName = self.m_sName
    local func = function(oPlayer,mArgs)
        if mArgs.answer and mArgs.answer ~= 0 then
            local event = mDialogInfo["last_action"][mArgs.answer]["event"]
            if event then
                local oHuodongMgr = global.oHuodongMgr
                local oHuodong = oHuodongMgr:GetHuodong(sName)
                local oNpcMgr = global.oNpcMgr
                local obj = oNpcMgr:GetObject(iNpcId)
                if not obj then
                    return
                end
                oHuodong:DoScript(iPid,obj,{event})
            end
        end
    end
    local oCbMgr = global.oCbMgr
    oCbMgr:SetCallBack(iPid,"GS2CDialog",m,nil,func)
end

function CHuodong:DoScript2(iPid,oNpc,sEvent,mArgs)
    if string.sub(sEvent,1,5) == "START" then
        self:StartTraning(iPid,oNpc)
        return
    elseif string.sub(sEvent,1,10) == "CREATETEAM" then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer:Send("GS2CFastCreateTeam",{target = 1201})
        return
    end
    super(CHuodong).DoScript2(self,iPid,oNpc,sEvent,mArgs)
end

function CHuodong:StartTraning(iPid,oNpc)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        if oNpc then
            self:GS2CDialog(iPid,oNpc,200)
        end
        return
    end
    if not oTeam:IsLeader(oPlayer.m_iPid) then
        global.oNotifyMgr:Notify(iPid,"请让队长来找我")
        return
    end
    if oTeam:MemberSize() < TEAM_MEMCNT_LIMIT then
        global.oNotifyMgr:Notify(iPid,"队伍人数不足，无法修行")
        return
    end
    local lMem = oTeam:GetTeamMember()
    local iGrade = global.oWorldMgr:QueryControl("dailytrain","open_grade")
    for _,pid in pairs(lMem) do
        local oMem = global.oWorldMgr:GetOnlinePlayerByPid(pid)
        if oMem:GetGrade() < iGrade then
            global.oNotifyMgr:Notify(iPid,string.format("%s等级不足",oMem:GetName()))
            return
        end
    end
    local oTask = oTeam:GetTeamTask(TRAIN_TASK_ID)
    if oTask then
        oTask:AutoFindPath()
        return
    end
    self:_StartTraning1(oPlayer)
end

function CHuodong:_StartTraning1(oPlayer)
    local oTeam = oPlayer:HasTeam()
    local oTask = self:NewTask()
    oTask.m_iTeamId = oTeam.m_ID
    oTeam:AddTeamTask(oTask)
    oTask:StartTraning()
end

function CHuodong:NewTask()
    local oTask = loadtask.LoadTask(TRAIN_TASK_ID)
    return oTask
end

function CHuodong:SetSwitch(oPlayer,iClose)
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    local oTask = oTeam:GetTeamTask(TRAIN_TASK_ID)
    if not oTask then
        return
    end
    oTask:SetSwitch(oPlayer,iClose)
end

function CHuodong:QuitTrain(oPlayer)
    local oTeam = oPlayer:HasTeam()
    if not oTeam or not (oTeam:IsLeader(oPlayer.m_iPid)) then
        return
    end
    if oPlayer:GetNowWar() then
        return
    end
    local oTask = oTeam:GetTeamTask(TRAIN_TASK_ID)
    if not oTask then
        return
    end
    oTeam:RemoveTeamTask(oTask)
    oTask:Release()
end

function CHuodong:GetAutoSkill(oPlayer)
    local iSchool = oPlayer:GetSchool()
    local iBranch = oPlayer:GetSchoolBranch()
    local mData = res["daobiao"]["huodong"][self.m_sName]["auto_skill"]
    for _,info in pairs(mData) do
        if info["school"] == iSchool and info["school_branch"] == iBranch then
            return info["auto_skill"]
        end
    end
    return 1
end

function CHuodong:SetAutoSkill(oPlayer,iSkill)
    local oTeam = oPlayer:HasTeam()
    if not oTeam then
        return
    end
    local oTask = oTeam:GetTeamTask(TRAIN_TASK_ID)
    if not oTask then
        return
    end
    oTask:SetAutoSkill(oPlayer,iSkill)
end