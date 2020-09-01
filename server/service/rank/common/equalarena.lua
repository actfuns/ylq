--import module
local global = require "global"
local skynet = require "skynet"
local rankbase = import(service_path("rankbase"))
local interactive = require "base.interactive"


function NewRankObj(...)
    return CRank:New(...)
end

CRank = {}
CRank.__index = CRank
inherit(CRank, rankbase.CRankBase)

function CRank:Init(idx, sName)
    super(CRank).Init(self, idx, sName)
    self.m_lSortDesc = {true, false,}
    self.m_iSaveLimit = 600
    self.m_iShowLimit = 500
end

function CRank:Key(mData)
    return mData[2]
end


function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.point,mData.pid,mData.name,mData.shape,mData.grade,mData.school,mData.segment,mData.time}
end

function CRank:UpdateName(sName, mData)
    mData[3] = sName
end

function CRank:PackShowRankData(iPid, iPage)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.page = iPage
    mNet.first_stub = self.m_iFirstStub

    local mData = self:GetShowRankData(iPage)
    local lArenaRank = {}
    local mUnit
    for idx, lInfo in ipairs(mData) do
        mUnit = {}
        mUnit.point = lInfo[1]
        mUnit.pid = lInfo[2]
        mUnit.name = lInfo[3]
        mUnit.shape = lInfo[4]
        mUnit.grade = lInfo[5]
        mUnit.school = lInfo[6]
        mUnit.segment = lInfo[7]
        mUnit.rank_shift = lInfo[9]
        mUnit.rank = lInfo[10]
        table.insert(lArenaRank, mUnit)
    end
    if #lArenaRank then
        mNet.equal_rank = lArenaRank
    end
    return mNet
end

function CRank:GetCondition(iRank, mData)
    return {rank = iRank, pid = mData[2]}
end

function CRank:GetCompareVal(sKey)
    local mVal = {}
    local mData = self.m_mRankData[sKey]
    if mData then
        mVal.point = mData[1]
    end
    return mVal
end

function CRank:EqualVal(mOldVal, mNewVal)
    mOldVal = mOldVal or {}
    mNewVal = mNewVal or {}
    return mOldVal.point == mNewVal.point
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
        mInfo.pid = mData[2]
        mInfo.grade = mData[5]
        mInfo.name = mData[3]
        mInfo.point = mData[1]
        mInfo.segment = mData[7]
        mInfo.my_rank = mData[10]
    end
    if next(mInfo) then
        mNet.equal_rank = mInfo
    end
    return mNet
end

function CRank:SendSimpleRankData()
    local oWorldMgr = global.oWorldMgr
    local lPid = {}
    local lData = {}
    local list,pid,rank
    for iPage, lRank in ipairs(self.m_mShowData) do
        list = {}
        for _, data in ipairs(lRank) do
            pid = data[2]
            rank = data[10]
            table.insert(list, { pid = pid, rank = rank })
            if rank <= 3 then
                lPid[rank] = lPid[rank] or {}
                table.insert(lPid[rank],pid)
            end
        end
        lData[iPage] = list
    end
    local mRet = {}
    mRet.idx = self.m_iRankIndex
    mRet.data = lData
    interactive.Send(".world", "rank", "SendSimpleRankData", mRet)
end

function CRank:GetExtraRankData(mData)
    self:DoStubShowData()
    self:SendSimpleRankData()
    local oRankMgr = global.oRankMgr
    oRankMgr:ClearClientRankData(self.m_iRankIndex)
    local lResult = self:GetRankShowDataByLimit(500)
    local mRank = {}
    local mUnit
    for _,lInfo in pairs(lResult) do
        mUnit ={ }
        mUnit.point = lInfo[1]
        mUnit.pid = lInfo[2]
        mUnit.rank = lInfo[10]
        table.insert(mRank,mUnit)
    end
    return {rank=mRank,}
end


