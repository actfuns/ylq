
--import module
local global  = require "global"
local extend = require "base.extend"
local record = require "public.record"

local analy = import(lualib_path("public.dataanaly"))
local loaditem = import(service_path("item/loaditem"))
local clientnpc = import(service_path("task/clientnpc"))
local loadtask = import(service_path("task/loadtask"))
local tasknet = import(service_path("netcmd/task"))
local gamedefines = import(lualib_path("public.gamedefines"))

local templ = import(service_path("templ"))
local taskobj = import(service_path("task/taskobj"))

CTask = {}
CTask.__index = CTask
CTask.m_sName = "teamtaskbase"
inherit(CTask,taskobj.CTask)

function CTask:New(taskid)
    local o = super(CTask).New(self)
    o.m_mTeamMem = {}
    return o
end

--1：新增  2：归队   
function CTask:EnterTeam(iPid,iType)
    self.m_mTeamMem[iPid] = true
end

--1：离队  2：暂离
function CTask:LeaveTeam(iPid,iType)
    self.m_mTeamMem[iPid] = nil
end

function CTask:MemAmount()
    return table_count(self.m_mTeamMem)
end

function CTask:RemoveClientNpc(npcobj)
    if not npcobj then
        return
    end
    local bFlag
    local npcid = npcobj.m_ID
    for _,oClientNpc in ipairs(self.m_mClientNpc) do
        if oClientNpc.m_ID == npcid then
            bFlag = true
        end
    end
    if not bFlag then
        return
    end
    local iTarget = 0
    local iType = self:Target()
    if iType then
        local oTargetNpc = self:GetNpcObjByType(iType)
        iTarget = oTargetNpc:Type()
    end
    extend.Array.remove(self.m_mClientNpc,npcobj)
    local npcid = npcobj:ID()
    local oNpcMgr = global.oNpcMgr
    oNpcMgr:RemoveObject(npcid)
    baseobj_delay_release(npcobj)
    local mNet = {}
    mNet["taskid"] = self.m_ID
    mNet["npcid"] = npcid
    mNet["target"] = iTarget
    self:BracastInfo("GS2CRemoveTeamNpc",mNet)
end

function CTask:BracastInfo(sMessage,mData)
    for iPid,_ in pairs(self.m_mTeamMem) do
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer:Send(sMessage,mData)
        end
    end
end