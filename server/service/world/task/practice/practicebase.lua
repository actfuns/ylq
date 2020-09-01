--import module

local global = require "global"
local taskobj = import(service_path("task/taskobj"))

CTask = {}
CTask.__index = CTask
CTask.m_sName = "practice"
CTask.m_sTempName = "考验任务"
inherit(CTask,taskobj.CTask)

function CTask:New(taskid)
    local o = super(CTask).New(self,taskid)
    return o
end

function CTask:CheckGrade(iGrade)
    local iDoneGrade = self:GetData("grade")
    local oWorldMgr = global.oWorldMgr
    if iGrade < iDoneGrade then
        return
    end
    local iPid = self.m_Owner
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    oPlayer.m_oTaskCtrl:MissionDone(self,iPid)
end

function CTask:DoScript2(iPid,oNpc,sEvent,mArgs)
    if string.sub(sEvent,1,10) == "CREATETEAM" then
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer:Send("GS2CFastCreateTeam",{target = 1140})
        return
    end
    super(CTask).DoScript2(self,iPid,oNpc,sEvent,mArgs)
end

function CTask:AfterWarWin(oWar,iPid,oNpc,mArgs)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        --oPlayer.m_oTaskCtrl:MissionDone(self,iPid)
        --self:MissionDone(iPid)
        local iEvent = self:GetEvent(oNpc.m_ID)
        if not iEvent then
            return
        end
        local mEvent = self:GetEventData(iEvent)
        if not mEvent then
            return
        end
        self:DoScript(iPid,oNpc,mEvent["after_win"])
        local oTeam = oPlayer:HasTeam()
        if not oTeam then
            return
        end
        local lMem = oTeam:GetTeamMember()
        for _,pid in pairs(lMem) do
            if pid ~= iPid then
                local oMem = global.oWorldMgr:GetOnlinePlayerByPid(pid)
                if oMem then
                    local oTask = oMem.m_oTaskCtrl:GetTask(self.m_ID)
                    if oTask then
                        oTask:DoScript(pid,oNpc,mEvent["after_win"])
                    end
                end
            end
        end
    end
end

function NewTask(taskid)
    local o = CTask:New(taskid)
    return o
end