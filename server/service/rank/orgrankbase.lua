--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local rankbase = import(service_path("rankbase"))
local orgunitbase = import(service_path("common/terrawars_orgunit"))

function NewRankObj(...)
    return CRank:New(...)
end

CRank = {}
CRank.__index = CRank
inherit(CRank, rankbase.CRankBase)

function CRank:Init(idx, sName)
    super(CRank).Init(self, idx, sName)
    self.m_lSortDesc = {true, true, false, false}
    self.m_mOrgUnit = {}
end


function CRank:Load(mData)
    super(CRank).Load(self,mData)
end

function CRank:GetOrgUnit(iOrgId)
    return self.m_mOrgUnit[iOrgId]
end

function CRank:OnUpdateName(sKey,sName)
    local bUpdate = false
    for iOrgId,oUnit in pairs(self.m_mOrgUnit) do
        if oUnit:GetShowRankDataByKey(sKey) then
            self:Dirty()
            oUnit:OnUpdateName(sKey,sName)
            bUpdate = true
        end
    end
    return bUpdate
end

function CRank:PackOrgShowRankData(iOrgId,iPid,iPage)
    local oOrgUnit = self:GetOrgUnit(iOrgId)
    if not oOrgUnit then
        return
    end
    return oOrgUnit:PackShowRankData(iPid,iPage)
end

function CRank:PackTop3RankData(iPid,iOrgId)
    local oUnit = self.m_mOrgUnit[iOrgId]
    if oUnit then
        return oUnit:PackTop3RankData(iPid)
    end
end

function CRank:GetMyRank(iPid,iOrgId)
    local oUnit = self.m_mOrgUnit[iOrgId]
    if oUnit then
        return oUnit:GetMyRank(iPid)
    end
end

function CRank:SendSimpleRankData()
    for iOrgId,oOrgUnit in pairs(self.m_mOrgUnit) do
        oOrgUnit:SendSimpleRankData()
    end
end

function CRank:GetCompareVal(sKey)
    local mVal = {}
    local mData = self.m_mRankData[sKey]
    if mData then
        mVal.personal_points = mData[1]
    end
    return mVal
end

function CRank:EqualVal(mOldVal, mNewVal)
    mOldVal = mOldVal or {}
    mNewVal = mNewVal or {}
    return mOldVal.personal_points == mNewVal.personal_points
end

function CRank:NewOrgUnit(iOrgId)
    -- body
end

function CRank:CleanAllData()
    self:Dirty()
    for iOrgId,oRankUnit in pairs(self.m_mOrgUnit) do
        oRankUnit:CleanAllData()
    end
end

function CRank:RemoveOrgUint(iOrgId)
    if not self.m_mOrgUnit[iOrgId] then
        return
    end
    self:Dirty()
    local oUnit = self.m_mOrgUnit[iOrgId]
    self.m_mOrgUnit[iOrgId] = nil
    oUnit:Release()
end

function CRank:ResetRankData()
    self:Dirty()
    for iOrgId,oUnit in pairs(self.m_mOrgUnit) do
        oUnit:ResetRankData()
    end
end

function CRank:PushDataToRank(mData,mArgs,bReInsert)
    mArgs = mArgs or {}
    local iOrgId = mArgs.orgid
    local oRankUnit = self:GetOrgUnit(iOrgId)
    if oRankUnit then
        self:Dirty()
        oRankUnit:PushDataToRank(mData,iOrgId,bReInsert)
    end
end

function CRank:TestOP(iPid,iCmd,...)
    self:Dirty()
    for iOrgId,oUnit in pairs(self.m_mOrgUnit) do
        oUnit:TestOP(iPid,iCmd,...)
    end
end

function CRank:CleanRankCache()
    self:Dirty()
    for iOrgId,oUnit in pairs(self.m_mOrgUnit) do
        oUnit:CleanRankCache()
    end
end

function CRank:NewOrgMem(iOrgId,iPid,mData)
    local oUnit = self:GetOrgUnit(iOrgId)
    if oUnit then
        self:Dirty()
        oUnit:PushDataToRank(mData)
    end
end

function CRank:OnUpdatePosition(sKey, iPosition)
    local bUpdate = false
    for iOrgId,oUnit in pairs(self.m_mOrgUnit) do
        if oUnit:GetShowRankDataByKey(sKey) then
            self:Dirty()
            oUnit:OnUpdatePosition(sKey,iPosition)
            bUpdate = true
        end
    end
    return bUpdate
end

function CRank:RemoveRecord(sKey)
end

function CRank:DoStubShowData()
    for iOrgId,oOrgUnit in pairs(self.m_mOrgUnit) do
        oOrgUnit:DoStubShowData()
    end
end

function CRank:LeaveOrg(iOrgId,iPid)
    local oRankUnit = self:GetOrgUnit(iOrgId)
    if oRankUnit then
        self:Dirty()
        oRankUnit:RemoveDataFromRank({key = iPid})
    end
end