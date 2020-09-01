--import module

local global = require "global"
local taskobj = import(service_path("task/taskobj"))

CTask = {}
CTask.__index = CTask
CTask.m_sName = "test"
CTask.m_sTempName = "测试任务"
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

function NewTask(taskid)
    local o = CTask:New(taskid)
    return o
end