--import module
local res = require "base.res"
local global = require "global"
local gamedefines = import(lualib_path("public.gamedefines"))
local taskobj = import(service_path("task/taskobj"))
local record = require "public.record"

CTask = {}
CTask.__index = CTask
CTask.m_sName = "daily"
CTask.m_sTempName = "日常任务"
inherit(CTask,taskobj.CTask)

function CTask:New(taskid)
    local o = super(CTask).New(self,taskid)
    return o
end

function CTask:Click(iPid)
    local bOpen = res["daobiao"]["global_control"]["dailytask"]["is_open"]
    if bOpen ~= "y" then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(iPid,"该功能正在维护，已临时关闭。请您留意官网相关信息。")
        return
    end
end

function NewTask(taskid)
    local o = CTask:New(taskid)
    return o
end
