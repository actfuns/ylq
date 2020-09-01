--import module

local global = require "global"

function NewAttrMgr(...)
    return CAttrMgr:New(...)
end

CAttrMgr = {}
CAttrMgr.__index =CAttrMgr
inherit(CAttrMgr,logic_base_cls())

function CAttrMgr:New()
    local o = super(CAttrMgr).New(self)
    o.m_mApply = {}
    o.m_mRatioApply = {}
    o.m_bIsDirty = false
    return o
end

function CAttrMgr:Dirty()
    self.m_bIsDirty = true
end

function CAttrMgr:IsDirty()
    return self.m_bIsDirty
end

function CAttrMgr:UnDirty()
    self.m_bIsDirty = false
end

function CAttrMgr:AddApply(sApply,iSource,iValue)
    self:Dirty()
    local mApply = self.m_mApply[sApply] or {}
    local v = mApply[iSource] or 0
    mApply[iSource] = v + iValue
    self.m_mApply[sApply] = mApply
end

function CAttrMgr:GetApply(sApply)
    local mApply = self.m_mApply[sApply] or {}
    local iValue = 0
    for _,v in pairs(mApply) do
        iValue = iValue + v
    end
    return iValue
end

function CAttrMgr:ClearApply()
    self:Dirty()
    self.m_mApply = {}
    self.m_mRatioApply = {}
end

function CAttrMgr:AddRatioApply(sApply,iSource,iValue)
    self:Dirty()
    local mApply = self.m_mRatioApply[sApply] or {}
    local v = mApply[iSource] or 0
    mApply[iSource] = v + iValue
    self.m_mRatioApply[sApply] = mApply
end

function CAttrMgr:GetRatioApply(sApply)
    local mApply = self.m_mRatioApply[sApply] or {}
    local iValue = 0
    for _,v in pairs(mApply) do
        iValue = iValue + v
    end
    return iValue
end

function CAttrMgr:RemoveApply(sApply)
    self:Dirty()
    self.m_mApply[sApply] = nil
end

function CAttrMgr:RemoveRatioApply(sApply)
    self:Dirty()
    self.m_mRatioApply[sApply] =nil
end

function CAttrMgr:RemoveSource(iDestSource)
    self:Dirty()
    local mDelete = {}
    for sApply,mApply in pairs(self.m_mApply) do
        mApply[iDestSource] = nil
        if table_count(mApply) <=0 then
            table.insert(mDelete,sApply)
        end
    end
    for _,sApply in ipairs(mDelete) do
        self.m_mApply[sApply] =nil
    end
    mDelete = {}
    for sApply,mRatioApply in pairs(self.m_mRatioApply) do
        mRatioApply[iDestSource] = nil
        if table_count(mRatioApply) <= 0 then
            table.insert(mDelete,sApply)
        end
    end
    for _,sApply in ipairs(mDelete) do
        self.m_mRatioApply[sApply] = nil
    end
end