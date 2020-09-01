--import module

local global = require "global"
local taskobj = import(service_path("task/taskobj"))
local gamedefines = import(lualib_path("public.gamedefines"))
local record = require "public.record"
local loadpartner = import(service_path("partner/loadpartner"))

CTask = {}
CTask.__index = CTask
CTask.m_sName = "partner"
CTask.m_sTempName = "伙伴支线任务"
inherit(CTask,taskobj.CTask)

function CTask:New(taskid)
    local o = super(CTask).New(self,taskid)
    o.m_SendRewardMailOnce = false
    o.m_mPartnerInfo = {}
    return o
end

function NewTask(taskid)
    local o = CTask:New(taskid)
    return o
end

function CTask:DoScript2(pid,npcobj,s,mArgs)
    super(CTask).DoScript2(self,pid,npcobj,s,mArgs)
    if string.sub(s,1,11) == "BindPartner" then
        local iParId = string.sub(s,12,-1)
        self:BindPartner(tonumber(iParId))
    elseif string.sub(s,1,5) == "PTEND" then
        --通过NPC对话进入战斗
        self:PartnerTaskEnd()
    end
end

function CTask:BindPartner(iParId)
    local mData = loadpartner.GetPartnerData(iParId)
    assert(mData,"BindPartner failed,not config:"..iParId)
    local sName = mData["name"]
    self.m_mPartnerInfo = {parid = iParId,name = sName}
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if oPlayer then
        oPlayer.m_oTaskCtrl:RefreshPartnerTask(false,iParId,self.m_ID)
    end
end

--当前伙伴所有任务完成
function CTask:PartnerTaskEnd()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(self.m_Owner)
    if oPlayer then
        oPlayer.m_oTaskCtrl:RefreshPartnerTask(false,self.m_mPartnerInfo.parid)
    end
end

function CTask:PackTaskInfo()
    local mNet = super(CTask).PackTaskInfo(self)
    mNet["partnertaskinfo"] = self.m_mPartnerInfo or {}
    return mNet
end

function CTask:Save()
    local mData = super(CTask).Save(self)
    mData["partnertaskinfo"] = self.m_mPartnerInfo or {}
    return mData
end

function CTask:Load(mData)
    mData = mData or {}
    super(CTask).Load(self,mData)
    self.m_mPartnerInfo = mData["partnertaskinfo"] or {}
end