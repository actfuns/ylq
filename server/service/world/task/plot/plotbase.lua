--import module

local global = require "global"
local taskobj = import(service_path("task/taskobj"))
local gamedefines = import(lualib_path("public.gamedefines"))
local record = require "public.record"

CTask = {}
CTask.__index = CTask
CTask.m_sName = "plot"
CTask.m_sTempName = "剧情支线任务"
inherit(CTask,taskobj.CTask)

function CTask:New(taskid)
    local o = super(CTask).New(self,taskid)
    o.m_SendRewardMailOnce = false
    return o
end

function NewTask(taskid)
    local o = CTask:New(taskid)
    return o
end