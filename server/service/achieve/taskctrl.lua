local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loadachieve = import(service_path("loadachieve"))

function NewTaskCtrl(iPid)
    local o = CTaskCtrl:New(iPid)
    return o
end

CTaskCtrl = {}
CTaskCtrl.__index = CTaskCtrl
inherit(CTaskCtrl, datactrl.CDataCtrl)

function CTaskCtrl:New(iPid)
    local o = super(CTaskCtrl).New(self)
    o.m_iOwner = iPid
    o.m_mList = {}
    o.m_iHasInit = 0
    return o
end

function CTaskCtrl:Release()
    for _, oAchieve in pairs(self.m_mList) do
        baseobj_safe_release(oAchieve)
    end
    self.m_mList = nil
    super(CTaskCtrl).Release(self)
end

function CTaskCtrl:Load(mData)
    self.m_iHasInit = mData["hasinit"] or 0
    if self.m_iHasInit == 0 then
        self:InitTask()
        return
    end

    local mTask = mData["task"]
    local res = require "base.res"
    local mDaobiao = res["daobiao"]["achieve"]["achievetask"]
    for iTaskId,info in pairs(mTask) do
        if mDaobiao[tonumber(iTaskId)] then
            local oTask = loadachieve.LoadAchieveTask(tonumber(iTaskId),info)
            self.m_mList[tonumber(iTaskId)] = oTask
        end
    end
end

function CTaskCtrl:Save()
    local mData = {}
    local mTaskData = {}
    for iTaskId,oTask in pairs(self.m_mList) do
        mTaskData[db_key(iTaskId)] = oTask:Save()
    end
    mData["task"] = mTaskData
    mData["hasinit"] = self.m_iHasInit
    return mData
end

function CTaskCtrl:OnLogin(oPlayer)
    local m = {}
    for iTaskId,oTask in pairs(self.m_mList) do
        if oTask:IsOpen() then
            local mNet = oTask:PackTaskInfo()
            table.insert(m,mNet)
        end
    end
    oPlayer:Send("GS2CLoginAchieveTask",{info=m})
end

function CTaskCtrl:UnDirty()
    super(CTaskCtrl).UnDirty(self)
    for _,oTask in pairs(self.m_mList) do
        oTask:UnDirty()
    end

end

function CTaskCtrl:IsDirty()
   if super(CTaskCtrl).IsDirty(self) then
        return true
    end
    for _,oTask in pairs(self.m_mList) do
        if oTask:IsDirty() then
            return true
        end
    end
    return false
end

function CTaskCtrl:InitTask()
    self:Dirty()
    local oAchieveMgr = global.oAchieveMgr
    local res = require "base.res"
    local mData = res["daobiao"]["achieve"]["achievetask"]
    for iTaskId,info in pairs(mData) do
        local oTask = loadachieve.CreateAchieveTask(iTaskId)
        oTask:SetOwner(self.m_iOwner)
        self.m_mList[iTaskId] = oTask
    end
    self.m_iHasInit = 1
end

function CTaskCtrl:PushPreCondition(iTaskId,sKey,mData)
    if self.m_mList[iTaskId] then
        self:Dirty()
        local oTask = self.m_mList[iTaskId]
        oTask:PushPreCondition(sKey,mData)
    end
end

function CTaskCtrl:PushCondition(iTaskId,sKey,mData)
    if self.m_mList[iTaskId] then
        self:Dirty()
        local oTask = self.m_mList[iTaskId]
        oTask:PushCondition(sKey,mData)
    end
end

function CTaskCtrl:TaskOpen(iTaskId)
    self:Dirty()
    local oTask = self.m_mList[iTaskId]
    assert(oTask,"TaskOpen failed,"..iTaskId)
    local oAchieveMgr = global.oAchieveMgr
    local oPlayer = oAchieveMgr:GetPlayer(self.m_iOwner)
    local mTaskInfo = oTask:PackTaskInfo()
    oPlayer:Send("GS2CAddAchieveTask",{info = mTaskInfo})
    record.user("achievetask","task_open",{pid = self.m_iOwner,taskid = iTaskId,degree = oTask:PackLogInfo()})
end

function CTaskCtrl:RefreshTask(iTaskId)
    local oTask = self.m_mList[iTaskId]
    assert(oTask,"ReachTask failed,"..iTaskId)
    local mTaskInfo = oTask:PackTaskInfo()
    local oAchieveMgr = global.oAchieveMgr
    local oPlayer = oAchieveMgr:GetPlayer(self.m_iOwner)
    oPlayer:Send("GS2CRefreshAchieveTask",{info = mTaskInfo})
end

function CTaskCtrl:GetAchieveTaskReward(iTaskId)
    local oTask = self.m_mList[iTaskId]
    if not oTask then
        return false
    end
    if not oTask:CheckCanReward() then
        return false
    end
    self:FinishTask(iTaskId)
    return true
end

function CTaskCtrl:FinishTask(iTaskId)
    self:Dirty()
    local oTask = self.m_mList[iTaskId]
    assert(oTask,"FinishTask failed,"..iTaskId)

    local oAchieveMgr = global.oAchieveMgr
    local oPlayer = oAchieveMgr:GetPlayer(self.m_iOwner)
    oPlayer:Send("GS2CDelAchieveTask",{taskid = iTaskId})

    
    self.m_mList[iTaskId] = nil
    
    oAchieveMgr:Push("完成成就任务",{pid=self.m_iOwner,data={value = iTaskId}})
    record.user("achievetask","task_finish",{pid = self.m_iOwner,taskid = iTaskId,degree = oTask:PackLogInfo()})
    baseobj_safe_release(oTask)
end

function CTaskCtrl:GetAchieveTaskInfo(iAchieveId)
    return loadachieve.GetAchieveTaskInfo(iAchieveId)
end