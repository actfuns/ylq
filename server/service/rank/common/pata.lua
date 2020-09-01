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

function CRank:Init(idx, sName)
    super(CRank).Init(self, idx, sName)
    self.m_lSortDesc = {true,false,false}
end

function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.level,mData.time,mData.pid,mData.name,mData.shape,mData.school}
end

function CRank:GetCondition(iRank, mData)
    return {rank = iRank, pid = mData[3]}
end

function CRank:GetCompareVal(sKey)
    local mVal = {}
    local mData = self.m_mRankData[sKey]
    if mData then
        mVal.level = mData[1]
    end
    return mVal
end

function CRank:EqualVal(mOldVal, mNewVal)
    mOldVal = mOldVal or {}
    mNewVal = mNewVal or {}
    return mOldVal.level == mNewVal.level
end

function CRank:UpdateName(sName, mData)
    mData[4] = sName
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
        mUnit.pid = lInfo[3]
        mUnit.name = lInfo[4]
        mUnit.shape = lInfo[5]
        mUnit.level = lInfo[1]
        mUnit.school = lInfo[6]
        mUnit.rank_shift = lInfo[7]
        mUnit.rank = lInfo[8]
        table.insert(lPataRank, mUnit)
    end
    if #lPataRank then
        mNet.pata_rank = lPataRank
    end
    return mNet
end

function CRank:PackTop3RankData(iPid)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.my_rank = self.m_mShowRank[db_key(iPid)]

    local lRoleInfo = {}
    local mModelInfo, mRoleInfo
    for iRank, mInfo in pairs(self.m_mTop3Data) do
        mModelInfo = {}
        mModelInfo.shape = mInfo.model.shape
        mModelInfo.scale = mInfo.model.scale
        mModelInfo.color = mInfo.model.color
        mModelInfo.mutate_texture = mInfo.model.mutate_texture
        mModelInfo.weapon = mInfo.model.weapon
        mModelInfo.adorn = mInfo.model.adorn

        mRoleInfo = {}
        mRoleInfo.pid = mInfo.pid
        mRoleInfo.name = mInfo.name
        mRoleInfo.upvote = mInfo.upvote
        mRoleInfo.school = mInfo.school
        mRoleInfo.value = mInfo.value
        mRoleInfo.model_info = mModelInfo
        table.insert(lRoleInfo, mRoleInfo)
    end

    if #lRoleInfo > 0 then
        mNet.role_info = lRoleInfo
    end
    return mNet
end

function CRank:GetMyRank(iPid, key, bRush)
    local sKey = db_key(iPid)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.end_time = self.m_iEndTime
    mNet.rank_count = self:CountShowRankData(bRush)
    local mInfo = {}
    local mData = self:GetShowRankDataByKey(sKey, bRush)
    if mData then
        mInfo.pid = mData[3]
        mInfo.name = mData[4]
        mInfo.level = mData[1]
        mInfo.my_rank = mData[8]
    end
    if next(mInfo) then
        mNet.pata_rank = mInfo
    end
    return mNet
end

function CRank:SendSimpleRankData()
    local oWorldMgr = global.oWorldMgr
    local lData = {}
    local list
    for iPage, lRank in ipairs(self.m_mShowData) do
        list = {}
        for _, data in ipairs(lRank) do
            table.insert(list, {pid = data[3]})
        end
        lData[iPage] = list
    end
    local mRet = {}
    mRet.idx = self.m_iRankIndex
    mRet.data = lData
    interactive.Send(".world", "rank", "SendSimpleRankData", mRet)
end

function CRank:PackRankRewardInfo()
    local lRankInfo = {}
    for iPage, mShowData in ipairs (self.m_mShowData) do
        for _, mData in ipairs(mShowData) do
           table.insert(lRankInfo, {
            pid = mData[3],
            rank = mData[8],
            })
        end
    end
    return lRankInfo
end

function CRank:PackRushRankInfo()
    local lRank = {}
    local iPid, iRank
    for iPage, mData in pairs(self.m_mRushData) do
        for _, info in pairs(mData) do
            iPid = info[3]
            iRank =info[8]
            if iRank > 10 then
                return lRank
            end
            table.insert(lRank, {pid = iPid, rank = iRank})
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
                rank = info[8],
                reason = sReason,
                info = string.format("{ pata_level = %s }", info[1]),
            }
            record.user("rank", subtype, mLog)
        end
    end
end