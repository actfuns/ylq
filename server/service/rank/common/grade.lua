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
    self.m_lSortDesc = {true, true, false, false}
end

function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.grade, mData.exp,mData.pid,mData.time,mData.name, mData.school, mData.shape,}
end

function CRank:UpdateName(sName, mData)
    mData[5] = sName
end

function CRank:PackShowRankData(iPid, iPage)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.page = iPage
    mNet.first_stub = self.m_iFirstStub

    local mData = self:GetShowRankData(iPage)
    local lGradeRank = {}
    local mUnit
    for idx, lInfo in ipairs(mData) do
        mUnit = {}
        mUnit.grade = lInfo[1]
        mUnit.pid = lInfo[3]
        mUnit.name = lInfo[5]
        mUnit.school = lInfo[6]
        mUnit.shape = lInfo[7]
        mUnit.rank_shift = lInfo[8]
        mUnit.rank = lInfo[9]
        table.insert(lGradeRank, mUnit)
    end
    if #lGradeRank then
        mNet.grade_rank = lGradeRank
    end
    return mNet
end

function CRank:GetCondition(iRank, mData)
    return {rank = iRank, pid = mData[3]}
end

function CRank:PackTop3RankData(iPid)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.my_rank = self.m_mShowRank[db_key(iPid)]

    local lRoleInfo = {}
    local mModelInfo,mRoleInfo
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

function CRank:GetMyRank(iPid)
    local sKey = db_key(iPid)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.end_time = self.m_iEndTime
    mNet.rank_count = self:CountShowRankData()
    local mInfo = {}
    local mData = self:GetShowRankDataByKey(sKey)
    if mData then
        mInfo.grade = mData[1]
        mInfo.pid = mData[3]
        mInfo.name = mData[5]
        mInfo.my_rank = self.m_mShowRank[sKey]
    end
    if next(mInfo) then
        mNet.grade_rank = mInfo
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