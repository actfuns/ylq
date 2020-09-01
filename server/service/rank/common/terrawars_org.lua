--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local rankbase = import(service_path("orgrankbase"))
local orgunitbase = import(service_path("common/terrawars_orgunit"))

function NewRankObj(...)
    return CRank:New(...)
end

CRank = {}
CRank.__index = CRank
inherit(CRank, rankbase.CRank)

function CRank:Init(idx, sName)
    super(CRank).Init(self, idx, sName)
    self.m_lSortDesc = {true, true, false, false}
    self.m_mOrgUnit = {}
end

function CRank:Save()
    local mData = super(CRank).Save(self)
    local mUnit = {}
    for iOrgId,oUnit in pairs(self.m_mOrgUnit) do
        mUnit[iOrgId] = oUnit:Save()
    end
    mData.org_unit = mUnit
    return mData
end

function CRank:Load(mData)
    super(CRank).Load(self,mData)
    local mOrgUnit = {}
    local mOrgInfo = mData.org_unit or {}
    local oUnit, bSuccess
    for iOrgId,info in pairs(mOrgInfo) do
        oUnit = orgunitbase.NewRankObj(111, "terrawars_orgunit")
        bSuccess = safe_call(oUnit.Load,oUnit,info)
        if bSuccess then
            mOrgUnit[iOrgId] = oUnit
        end
    end
    self.m_mOrgUnit = mOrgUnit
end

function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.personal_points,mData.grade,mData.pid,mData.time,mData.name, mData.position, mData.power,}
end

function CRank:NewOrgUnit(iOrgId)
    -- body
    if self.m_mOrgUnit[iOrgId] then
        return
    end
    self:Dirty()
    local oUnit = orgunitbase.NewRankObj(111, "terrawars_orgunit")
    self.m_mOrgUnit[iOrgId] = oUnit
end

function CRank:OnTerrPointUpdate(iOrgId,iPid,iPersonal_points)
    local oRankUint = self.m_mOrgUnit[iOrgId]
    if oRankUint then
        self:Dirty()
        oRankUint:OnTerrPointUpdate(iOrgId,iPid,iPersonal_points)
    end
end

function CRank:NewHour(iWeekDay, iHour)
end

function CRank:SendReward()
    for iOrgId,oUnit in pairs(self.m_mOrgUnit) do
        oUnit:SendReward()
    end
end

function CRank:ResetRankData()
    for iOrgId,oUnit in pairs(self.m_mOrgUnit) do
        oUnit:ResetRankData()
    end
end