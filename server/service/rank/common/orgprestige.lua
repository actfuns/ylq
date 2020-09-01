--import module
local global = require "global"
local skynet = require "skynet"
local extend = require "base.extend"
local interactive = require "base.interactive"

local rankbase = import(service_path("rankbase"))


function NewRankObj(...)
    return CRank:New(...)
end

CRank = {}
CRank.__index = CRank
inherit(CRank, rankbase.CRankBase)

function CRank:IsOrgRank()
    return true
end

function CRank:Init(idx, sName)
    super(CRank).Init(self, idx, sName)
    self.m_lSortDesc = {true,false,false}
end

function CRank:GenRankUnit(mData)
    return db_key(mData.orgid), {mData.prestige,mData.time,mData.orgid,mData.org_level,mData.org_name,mData.flag,mData.leader,mData.flagbgid}
end

function CRank:GetCondition(iRank, mData)
    return {rank = iRank, orgid = mData[3]}
end

function CRank:GetCompareVal(sKey)
    local mVal = {}
    local mData = self.m_mRankData[sKey]
    if mData then
        mVal.prestige = mData[1]
    end
    return mVal
end

function CRank:EqualVal(mOldVal, mNewVal)
    return false
end

function CRank:UpdateName(sName,mData)
    mData[5] = sName
end

function CRank:PackShowRankData(iPid, iPage, key, bRush)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.page = iPage
    mNet.first_stub = self.m_iFirstStub
    local mData = self:GetShowRankData(iPage, bRush)
    local lPataRank = {}
    local mUnit
    for idx, lInfo in ipairs(mData) do
        mUnit = {}
        mUnit.orgid = lInfo[3]
        mUnit.org_level = lInfo[4]
        mUnit.org_name = lInfo[5]
        mUnit.flag = lInfo[6]
        mUnit.leader = lInfo[7]
        mUnit.flagbgid = lInfo[8]
        mUnit.prestige = lInfo[1]
        mUnit.rank_shift = lInfo[9]
        mUnit.rank = lInfo[10]
        table.insert(lPataRank, mUnit)
    end
    if #lPataRank then
        mNet.org_prestige_rank = lPataRank
    end
    return mNet
end

function CRank:GetMyRank(iPid,iOrgID, bRush)
    local sKey = db_key(iOrgID)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.end_time = self.m_iEndTime
    mNet.rank_count = self:CountShowRankData(bRush)
    local mInfo = {}
    local mData = self:GetShowRankDataByKey(sKey, bRush)
    if mData then
        mInfo.orgid = mData[3]
        mInfo.org_level = mData[4]
        mInfo.org_name = mData[5]
        mInfo.flag = mData[6]
        mInfo.leader = mData[7]
        mInfo.flagbgid = mData[8]
        mInfo.prestige = mData[1]
        mInfo.my_rank = mData[10]
    end
    if next(mInfo) then
        mNet.org_prestige_rank = mInfo
    end
    return mNet
end

function CRank:SendSimpleRankData()
    local mOrgRank = {}
    local list
    for iPage, lRank in ipairs(self.m_mShowData) do
        list = {}
        for _, data in ipairs(lRank) do
            table.insert(mOrgRank,{data[3],data[10]})
        end
    end

    interactive.Send(".org", "common", "SendOrgRankData", {info=mOrgRank})
end

function CRank:OnUpdateOrgInfo(iOrgId,mInfo)
    local bUpdate = false
    local sKey = db_key(iOrgId)
    local mShowData = self:GetShowRankDataByKey(sKey)
    if mShowData then
        mShowData[4] = mInfo.org_level or mShowData[4]
        mShowData[6] = mInfo.flag or mShowData[6]
        mShowData[7] = mInfo.leader or mShowData[7]
        mShowData[8] = mInfo.flagbgid or mShowData[8]
        bUpdate = true
    end
    local mKeepData = self.m_mRankData[sKey]
    if mKeepData then
        mKeepData[4] = mInfo.org_level or mKeepData[4]
        mKeepData[6] = mInfo.flag or mKeepData[6]
        mKeepData[7] = mInfo.leader or mKeepData[7]
        mKeepData[8] = mInfo.flagbgid or mKeepData[8]
        bUpdate = true
    end
    if bUpdate then
        self:Dirty()
    end
    return bUpdate
end

function CRank:PackRushRankInfo()
    local lRank = {}
    local iOrgId,iRank
    for iPage, mData in pairs(self.m_mRushData) do
        for _, info in ipairs(mData) do
            iOrgId = info[3]
            iRank =info[10]
            if iRank > 10 then
                return lRank
            end
            table.insert(lRank, {orgid = iOrgId, rank = iRank})
        end
    end
    return lRank
end

function CRank:LogInfo(subtype, sReason)
    for iPage, mData in pairs(self.m_mShowData) do
        for _, info in pairs(mData) do
            local mLog = {
                idx = self.m_iRankIndex,
                sub_key = 0,
                target = info[3],
                rank = info[10],
                reason = sReason,
                info = string.format("{prestige = %s }", info[1]),
            }
            record.user("rank", subtype, mLog)
        end
    end
end