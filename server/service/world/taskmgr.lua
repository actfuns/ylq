local global = require "global"
local extend = require "base.extend"
local gamedefines = import(lualib_path("public.gamedefines"))
local rewardmonitor = import(service_path("rewardmonitor"))

function NewTaskMgr()
    return CTaskMgr:New()
end

CTaskMgr = {}
CTaskMgr.__index = CTaskMgr
inherit(CTaskMgr, logic_base_cls())

function CTaskMgr:New()
    local o = super(CTaskMgr).New(self)
    o.m_oTaskRewardMonitor = rewardmonitor.CTaskRewardMonitor:New()
    return o
end

function CTaskMgr:Release()
    baseobj_safe_release(self.m_oTaskRewardMonitor)
    self.m_oTaskRewardMonitor = nil
    super(CTaskMgr).Release(self)
end

function CTaskMgr:GetTaskRewardMonitor()
    return self.m_oTaskRewardMonitor
end
