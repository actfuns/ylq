local oAnleiTask = require("task_anlei")
local oFightTask = require("task_fight")
local oFindItemTask = require("task_finditem")
local oFindPersonTask = require("task_findperson")
local oFindSummonTask = require("task_findsummon")
local oPickTask = require("task_pick")
local oUseItemTask = require("task_useitem")
local taskdefines = require("taskdefines")
local tprint = require('extend').Table.print
require("tableop")
local CTaskMgr = {}
CTaskMgr.__index = CTaskMgr

function CTaskMgr:New(oPlayer)
    local o = setmetatable({}, CTaskMgr)
    o.m_oMaster = oPlayer
    return o
end

function CTaskMgr:Init()
    print("客户端初始化")
    self.m_mTypeToTaskObj = {
        [taskdefines.ANLEI_TASK_TYPE] = oAnleiTask:New(taskdefines.ANLEI_TASK_TYPE),
        [taskdefines.FIGHT_TASK_TYPE] = oFightTask:New(taskdefines.FIGHT_TASK_TYPE),
        [taskdefines.FINDITEM_TASK_TYPE] = oFindItemTask:New(taskdefines.FINDITEM_TASK_TYPE),
        [taskdefines.FINDPERSON_TASK_TYPE] = oFindPersonTask:New(taskdefines.FINDPERSON_TASK_TYPE),
        [taskdefines.FINDSUMMON_TASK_TYPE] = oFindSummonTask:New(taskdefines.FINDSUMMON_TASK_TYPE),
        [taskdefines.PICK_TASK_TYPE] = oPickTask:New(taskdefines.PICK_TASK_TYPE),
        [taskdefines.USEITEM_TASK_TYPE] = oUseItemTask:New(taskdefines.USEITEM_TASK_TYPE),
    }
end

function CTaskMgr:GetParent()
    return self.m_oMaster
end

function CTaskMgr:run_cmd(...)
    local oPlayer = self:GetParent()
    oPlayer:run_cmd(...)
end

function CTaskMgr:GetCurTaskId()
    assert(self.m_iCurTaskId,"error:    havn't CurTaskId")
    return self.m_iCurTaskId
end

function CTaskMgr:GetCurTaskIndex()
   assert(self.m_iCurTaskIndex,"error:    havn't CurTaskIndex")
   return self.m_iCurTaskIndex
end

function CTaskMgr:GetCurTaskType()
    assert(self.m_iCurTaskId,"error:    havn't CurTaskType")
    return self.m_mTaskInfoTbl[self.m_iCurTaskIndex].tasktype
end

function CTaskMgr:GetCurTaskInfoTbl()
    local iCurTaskIndex = self:GetCurTaskIndex()
    assert(#self.m_mTaskInfoTbl > 0,"error:    TaskInfoTbl is empty")
    return self.m_mTaskInfoTbl[iCurTaskIndex]
end

function CTaskMgr:InitTaskInfoOnLogin(mTaskInfoTbl)
   self.m_mTaskInfoTbl = self.m_mTaskInfoTbl or mTaskInfoTbl or {}
end

function CTaskMgr:RandomDoTaskEvent()
    if self.m_mTaskInfoTbl and not self.m_iCurTaskIndex then
        local iTaskNum = #self.m_mTaskInfoTbl
        if iTaskNum > 0 then
	local iTargetTaskIndex = math.random(1,iTaskNum)
	local mTaskInfo = self.m_mTaskInfoTbl[iTargetTaskIndex]
	local iTaskId = mTaskInfo.taskid
	local iTaskType = mTaskInfo.tasktype
	self:run_cmd("C2GSClickTask", {taskid = iTaskId})
	self.m_iCurTaskId = iTaskId
	self.m_iCurTaskIndex = iTargetTaskIndex
        end
    end
end

function CTaskMgr:AddTask(mTaskInfoTbl)
    self.m_mTaskInfoTbl = self.m_mTaskInfoTbl or {}
    table.insert(self.m_mTaskInfoTbl,mTaskInfoTbl)
    print("客户端增加任务:",mTaskInfoTbl.taskid)
    print("客户端还剩 "..#self.m_mTaskInfoTbl.." 个任务")
end

function CTaskMgr:DelTask(mArgs)
    if mArgs.taskid == self.m_iCurTaskId then
        table.remove(self.m_mTaskInfoTbl,self.m_iCurTaskIndex)
        self.m_iCurTaskIndex = nil
        self.m_iCurTaskId = nil
    end
    print("客户端删除任务:",mArgs.taskid)
end

function CTaskMgr:TriggerEventByProto(sProtoName,mArgs)
    local mTaskInfoTbl = self:GetCurTaskInfoTbl()
    local oTaskObj = self.m_mTypeToTaskObj[mTaskInfoTbl.tasktype]
    local oPlayer = self:GetParent()
    oTaskObj[sProtoName](oTaskObj[sProtoName],oPlayer,mTaskInfoTbl,mArgs)
end

return CTaskMgr