--import module

local global = require "global"
local taskobj = import(service_path("task/taskobj"))
local gamedefines = import(lualib_path("public.gamedefines"))
local gsub = string.gsub
CTask = {}
CTask.__index = CTask
CTask.m_sName = "huodong"
CTask.m_sTempName = "活动任务"
inherit(CTask,taskobj.CTask)

function CTask:New(taskid)
    local o = super(CTask).New(self,taskid)
    o.m_ID = taskid
    o.m_iNpcNum = 0
    o.m_mKillList = {}
    o.m_NpcList = {}
    return o
end

function CTask:SetGameId(iGid)
    self:Dirty()
    self.m_iGameID = iGid
end

function CTask:Save()
    local mData = super(CTask).Save(self)
    mData.gameid = self.m_iGameID
    mData.npclist = self.m_NpcList
    mData.killlist = self.m_mKillList
    return mData
end

function CTask:Load(mData)
    super(CTask).Load(self,mData)
    self.m_iGameID = mData.gameid
    self.m_NpcList = mData.npclist or {}
    self.m_mKillList = mData.killlist or {}
end

function CTask:SetNpcInfo(mNpc)
    self:Dirty()
    self.m_NpcList = mNpc or {}
    self.m_iNpcNum = table_count(self.m_NpcList)
end

function CTask:TransString(pid,npcobj,s)
    s = super(CTask).TransString(self,pid,npcobj,s)
    if not s then
        return
    end
    if string.find(s,"{killnpc}") then
        local killnpc = #self.m_mKillList
        s=gsub(s,"{killnpc}",killnpc)
    end
    if string.find(s,"{alivenpc}") then
        local alivenpc = tostring(self.m_iNpcNum)
        s=gsub(s,"{alivenpc}",alivenpc)
    end
    return s
end

function CTask:AddKillTime(iNpc)
    self:Dirty()
    table.insert(self.m_mKillList,iNpc)
end

function CTask:AssignToPlayer(iPid,bAutoAsign)
    if self:GetStatus() ~= gamedefines.TASK_STATUS.TASK_CANACCEPT then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    if not self:ValidAssign(iPid) then
        if not bAutoAsign then
            oNotifyMgr:Notify(iPid,"组队状态下不可进行当前任务")
        end
        return
    end
    self:SetData("accepttime",get_time())
    self:SetData("owner",iPid)
    self:SetTaskStatus(gamedefines.TASK_STATUS.TASK_HASACCEPT,"Accept Task")
    self:AfterAssign()
end

function CTask:TimeoutRemove()
    return true
end

function NewTask(taskid)
    local o = CTask:New(taskid)
    return o
end