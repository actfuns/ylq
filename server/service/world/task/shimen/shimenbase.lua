--import module

local global = require "global"

local taskobj = import(service_path("task/taskobj"))
local loadtask = import(service_path("task/loadtask"))
local gamedefines = import(lualib_path("public.gamedefines"))
local record = require "public.record"

local gsub = string.gsub

CTask = {}
CTask.__index = CTask
CTask.m_sName = "shimen"
CTask.m_sTempName = "师门任务"
inherit(CTask,taskobj.CTask)

function CTask:New(taskid)
    local o = super(CTask).New(self,taskid)
    return o
end

function CTask:AfterMissionDone(pid)
    super(CTask).AfterMissionDone(self,pid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end
    global.oAchieveMgr:PushAchieve(pid,"师门任务",{value=1})
    local iRing = self:GetData("Ring",1)
    local oHuodong = global.oHuodongMgr:GetHuodong("shimen")
    oHuodong:AfterTaskMissonDone(oPlayer,iRing)
end

function CTask:TransString(pid,npcobj,s)
    if string.find(s,"$ring") then
        s=gsub(s,"$ring",self:GetData("Ring",1))
    end
    return super(CTask).TransString(self,pid,npcobj,s)
end

function CTask:AfterAssign()
    local iTaskType = self:TaskType()
    if iTaskType == gamedefines.TASK_TYPE.TASK_FIND_ITEM then
        if self:ValidTakeItem(self.m_Owner) then
            local iNewStatus = gamedefines.TASK_STATUS.TASK_CANCOMMIT
            self:SetTaskStatus(iNewStatus,"任务完成")
        end
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    assert(oPlayer,string.format("afterassign task failed,pid:%s",self.m_Owner))
    record.user("task","receive_task",{pid = self.m_Owner,name = oPlayer:GetName(),grade = oPlayer:GetGrade(),taskid = self.m_ID,tasktype = self:TaskType()})
end

function CTask:TransReward(oRewardObj,sReward)
    local oWorldMgr = global.oWorldMgr
    local iServerGrade = oWorldMgr:GetServerGrade()
    local mEnv = {
        lv = oRewardObj and oRewardObj:GetGrade(),
        SLV = iServerGrade,
        ring = self:GetData("Ring",1),
    }
    local iValue = formula_string(sReward,mEnv)
    return iValue
end

function NewTask(taskid)
    local o = CTask:New(taskid)
    return o
end

function CTask:PackTaskInfo()
    local mNet = super(CTask).PackTaskInfo(self)
    mNet["shimeninfo"] = {cur_times = self:GetData("Ring",0),max_times = gamedefines.SHIMEN_MAXRING}
    return mNet
end

function CTask:CreateWar(pid,npcobj,iFight,mInfo)
    mInfo = mInfo or {}
    mInfo["war_type"] = gamedefines.WAR_TYPE.SHIMEN
    mInfo["remote_war_type"] = "shimen"
    return super(CTask).CreateWar(self,pid,npcobj,iFight,mInfo)
end