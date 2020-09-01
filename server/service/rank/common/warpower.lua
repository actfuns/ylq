--import module
local global = require "global"
local skynet = require "skynet"
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
    self.m_lSortDesc = {true, false, false}
end

function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.power,mData.pid,mData.time,mData.name,mData.school,mData.shape,mData.grade}
end

function CRank:GetCondition(iRank, mData)
    return {rank = iRank, pid = mData[2]}
end

function CRank:Key(mData)
    return mData[3]
end

function CRank:UpdateName(sName, mData)
    mData[4] = sName
end

function CRank:PackShowRankData(iPid, iPage)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.page = iPage
    mNet.first_stub = self.m_iFirstStub

    local mData = self:GetShowRankData(iPage)
    local lPowerRank = {}
    local mUnit
    for idx, lInfo in ipairs(mData) do
        mUnit = {}
        mUnit.warpower = lInfo[1]
        mUnit.pid = lInfo[2]
        mUnit.name = lInfo[4]
        mUnit.school = lInfo[5]
        mUnit.shape = lInfo[6]
        mUnit.grade = lInfo[7]
        mUnit.rank_shift = lInfo[8]
        mUnit.rank = lInfo[9]
        table.insert(lPowerRank, mUnit)
    end
    if #lPowerRank then
        mNet.warpower_rank = lPowerRank
    end
    return mNet
end

function CRank:GetCompareVal(sKey)
    local mVal = {}
    local mData = self.m_mRankData[sKey]
    if mData then
        mVal.power = mData[1]
    end
    return mVal
end

function CRank:EqualVal(mOldVal, mNewVal)
    mOldVal = mOldVal or {}
    mNewVal = mNewVal or {}
    return mOldVal.power == mNewVal.power
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

function CRank:GetMyRank(iPid, key, bRush, mDefault)
    local sKey = db_key(iPid)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.end_time = self.m_iEndTime
    mNet.rank_count = self:CountShowRankData()
    local mInfo = self:GetMyRankDefault(iPid, mDefault)
    local mData = self:GetShowRankDataByKey(sKey)
    if mData then
        mInfo.warpower = mData[1]
        mInfo.pid = mData[2]
        mInfo.name = mData[4]
        mInfo.grade = mData[7]
        mInfo.my_rank = mData[9]
    end
    if next(mInfo) then
        mNet.warpower_rank = mInfo
    end
    return mNet
end

function CRank:GetMyRankDefault(iPid, mDefault)
    local mInfo = {}
    if mDefault then
        mInfo.warpower = mDefault.warpower
        mInfo.pid = mDefault.pid
        mInfo.name = mDefault.name
        mInfo.grade = mDefault.grade
        mInfo.my_rank = 0
    end
    return mInfo
end

function CRank:PackRankRewardInfo()
    local iValue
    local iRank = 1
    local lRankInfo = {}
    for iPage, mShowData in ipairs (self.m_mShowData) do
        for _, mData in ipairs(mShowData) do
           table.insert(lRankInfo, {
            pid = mData[3],
            power = mData[1],
            })
        end
    end
    if next(lRankInfo) then
        local iRank = 1
        local iPower = lRankInfo[1].power
        lRankInfo[1].rank = iRank
        for i = 2, #lRankInfo do
            if iPower ~= lRankInfo[i].power then
                iRank = iRank + 1
            end
            iPower = lRankInfo[i].power
            lRankInfo[i].rank = iRank
        end
    end
    return lRankInfo
end

function CRank:SendSimpleRankData()
    local oWorldMgr = global.oWorldMgr
    local lData = {}
    local list
    for iPage, lRank in ipairs(self.m_mShowData) do
        list = {}
        for _, data in ipairs(lRank) do
            table.insert(list, {pid = data[2]})
        end
        lData[iPage] = list
    end
    local mRet = {}
    mRet.idx = self.m_iRankIndex
    mRet.data = lData
    interactive.Send(".world", "rank", "SendSimpleRankData", mRet)
end

function CRank:QueryRankBack()
    local lRank = {}
    local iPid, iRank
    for iPage, mData in pairs(self.m_mShowData) do
        for _, info in pairs(mData) do
            iPid = info[2]
            iRank =info[9]
            table.insert(lRank, {
                pid = iPid,
                rank = iRank,
                subtype = 0,
                idx = self.m_iRankIndex,
                })
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
                target = info[2],
                rank = info[9],
                reason = sReason,
                info = string.format("{ warpower = %s }", info[1]),
            }
            record.user("rank", subtype, mLog)
        end
    end
end