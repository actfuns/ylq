--import module

local global = require "global"
local taskobj = import(service_path("task/taskobj"))
local gamedefines = import(lualib_path("public.gamedefines"))
local record = require "public.record"

CTask = {}
CTask.__index = CTask
CTask.m_sName = "teach"
CTask.m_sTempName = "教学任务"
inherit(CTask,taskobj.CTask)

function CTask:New(taskid)
    local o = super(CTask).New(self,taskid)
    o.m_SendRewardMailOnce = false
    return o
end

function CTask:Init()
    self.m_mStatusInfo = {}
end

function CTask:Config(pid,npcobj)
    self.m_Owner = pid
    self:InitTeachInfo()
end

function CTask:InitTeachInfo()
    local res = require "base.res"
    local mData = res["daobiao"]["task"]["teach"]["task"][self.m_ID]
    self:Dirty()
    self.m_TeachInfo = {title=mData["title"],desc = mData["desc"],needtime = mData["times"],progress = 0}
end

function CTask:GetType()
    return self.m_TeachInfo["title"]
end

function CTask:Setup()
end

function CTask:AssignToPlayer(iPid)
    if self:GetStatus() ~= gamedefines.TASK_STATUS.TASK_CANACCEPT then
        return
    end
    self:SetData("accepttime",get_time())
    self:SetTaskStatus(gamedefines.TASK_STATUS.TASK_HASACCEPT,"Accept Task")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    assert(oPlayer,string.format("afterassign task failed,pid:%s",self.m_Owner))
    record.user("task","receive_task",{pid = self.m_Owner,name = oPlayer:GetName(),grade = oPlayer:GetGrade(),taskid = self.m_ID,tasktype = self:TaskType()})
end

function CTask:TaskType()
    return gamedefines.TASK_TYPE.TASK_TEACH
end

function CTask:PackTaskInfo()
    local mNet = {}
    mNet["taskid"] = self.m_ID
    mNet["tasktype"] = self:TaskType()
    mNet["teachinfo"] = self.m_TeachInfo
    mNet["acceptnpc"] = self:GetData("acceptnpc")
    mNet["statusinfo"] = self.m_mStatusInfo
    return mNet
end

function CTask:Refresh(mNet)
    local mNet = {}
    mNet["taskid"] = self.m_ID
    mNet["statusinfo"] = self.m_mStatusInfo
    local mTaskInfo = {teachinfo = self.m_TeachInfo}
    mNet["taskdata"] = mTaskInfo
    mNet["accepttime"] = self:GetData("accepttime",0)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if oPlayer then
        oPlayer:Send("GS2CRefreshTask",mNet)
    end
end

function CTask:Load(mData)
    self.m_Owner = mData["owner"] or 0
    self.m_TeachInfo = mData["teachinfo"] or {}
    self.m_mStatusInfo = mData["statusinfo"] or {}
end

function CTask:Save()
    local mData = {}
    mData["owner"] = self.m_Owner
    mData["teachinfo"] = self.m_TeachInfo
    mData["statusinfo"] = self.m_mStatusInfo
    return mData
end

function CTask:AddDoneTime(times)
    self:Dirty()
    local bRefresh = false
    if self.m_TeachInfo["progress"] < self.m_TeachInfo["needtime"] then
        bRefresh = true
    end
    self.m_TeachInfo["progress"] = self.m_TeachInfo["progress"] + times
    if self.m_TeachInfo["progress"] >= self.m_TeachInfo["needtime"] then
        self:SetTaskStatus(gamedefines.TASK_STATUS.TASK_CANCOMMIT,"任务完成")
    end
    if bRefresh then
        self:Refresh()
    end
end

function CTask:CanGetReward()
    local iP = self.m_TeachInfo["progress"] or 0
    local iN = self.m_TeachInfo["needtime"] or 0
    return iP >= iN
end

function CTask:GetReward()
    local res = require "base.res"
    local mData = res["daobiao"]["task"]["teach"]["task"][self.m_ID]
    local mReward = mData["reward"]
    for _,reward in pairs(mReward) do
        self:Reward(self.m_Owner, reward, {cancel_tip=1})
    end
    global.oUIMgr:ShowKeepItem(self.m_Owner)
end

function NewTask(taskid)
    local o = CTask:New(taskid)
    return o
end