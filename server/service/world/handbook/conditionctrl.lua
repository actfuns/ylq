local global = require "global"
local record = require "public.record"

local datactrl  = import(lualib_path("public.datactrl"))
local loadcondition = import(service_path("handbook.loadcondition"))

function NewConditionCtrl()
    local o = CConditionCtrl:New()
    return o
end

CConditionCtrl = {}
CConditionCtrl.__index = CConditionCtrl
inherit(CConditionCtrl, datactrl.CDataCtrl)

function CConditionCtrl:New()
    local o = super(CConditionCtrl).New(self)
    o.m_mList = {}
    return o
end

function CConditionCtrl:Release()
    for _, oCondition in pairs(self.m_mList) do
        baseobj_safe_release(oCondition)
    end
    self.m_mList = nil
    super(CConditionCtrl).Release(self)
end

function CConditionCtrl:Load(mData)
    mData = mData or {}
    local mConditionData = mData["condition"] or {}
    for sConditionID, data in pairs(mConditionData) do
        local iConditionID = tonumber(sConditionID)
        local oCondition = loadcondition.LoadCondition(iConditionID, data)
        self.m_mList[iConditionID] = oCondition
    end
end

function CConditionCtrl:Save()
    local mData = {}
    local mConditionData = {}
    for iConditionID, oCondition in pairs(self.m_mList) do
        mConditionData[db_key(iConditionID)] = oCondition:Save()
    end
    mData["condition"] = mConditionData
    return mData
end

function CConditionCtrl:OnLogin(oPlayer, bReEnter)
end

function CConditionCtrl:UnDirty()
    super(CConditionCtrl).UnDirty(self)
    for _, oCondition in pairs(self.m_mList) do
        oCondition:UnDirty()
    end
end

function CConditionCtrl:IsDirty()
    if super(CConditionCtrl).IsDirty(self) then
        return true
    end
    for _, oCondition in pairs(self.m_mList) do
        if oCondition:IsDirty() then
            return true
        end
    end
    return false
end

function CConditionCtrl:GetList()
    return self.m_mList
end

function CConditionCtrl:GetCondition(iConditionID)
    return self.m_mList[iConditionID]
end

function CConditionCtrl:AddCondition(iConditionID)
    self:Dirty()
    local oCondition = loadcondition.CreateCondition(iConditionID)
    self.m_mList[iConditionID] = oCondition
    return oCondition
end

function CConditionCtrl:RemoveCondition(iConditionID)
    self:Dirty()
    local oCondition = self.m_mList(iConditionID)
    if oCondition then
        baseobj_safe_release(oCondition)
    end
    self.m_mList[iConditionID] = nil
end

function CConditionCtrl:AddCndProgress(iConditionID, iAdd)
    local oCondition = self:GetCondition(iConditionID)
    if not oCondition then
        oCondition = self:AddCondition(iConditionID)
    end
    oCondition:AddProgress(iAdd)
end

function CConditionCtrl:SetCndProgress(iConditionID, iProgress)
    local oCondition = self:GetCondition(iConditionID)
    if not oCondition then
        oCondition = self:AddCondition(iConditionID)
    end
    oCondition:SetProgress(iProgress)
end

function CConditionCtrl:IsDone(iConditionID)
    local oCondition = self:GetCondition(iConditionID)
    if oCondition then
        return oCondition:IsDone()
    end
    return false
end

function CConditionCtrl:TestCmd(oPlayer, sCmd, m, sReason)
end