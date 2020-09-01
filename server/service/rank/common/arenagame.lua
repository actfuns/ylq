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
    self.m_iSaveLimit = 1000
    self.m_NeedSort = false
end

function CRank:PushDataToRank(mData)
    self.m_NeedSort = true
    super(CRank).PushDataToRank(self,mData)
end

function CRank:CheckShowData()
    if not self.m_NeedSort then
        return
    end
    self.m_NeedSort = false
    self:DoStubShowData()
    self:SendSimpleRankData()
end

function CRank:Key(mData)
    return mData[2]
end


function CRank:MyRank(pid)
    local iLen = self.m_DefaultRank
    if #self.m_lSortList <=0 then
        return iLen
    end
    local sKey = db_key(pid)
    local mUnit = self.m_mRankData[sKey]
    if not mUnit then
        return iLen
    end
    for iRank,sK in pairs(self.m_lSortList) do
        if sK == sKey then
            iLen = iRank
            break
        end
    end
    return iLen
end

function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.point,mData.pid,mData.name,mData.shape,mData.grade,mData.school,mData.segment,mData.time}
end

function CRank:UpdateName(sName, mData)
    mData[3] = sName
end

function CRank:PackShowRankData(iPid, iPage, key, bRush)
    self:CheckShowData()
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.page = iPage
    mNet.first_stub = self.m_iFirstStub

    local mData = self:GetShowRankData(iPage, bRush)
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
        mNet.arena_rank = lArenaRank
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

function CRank:GetExtraRankData(mData)
    local iPid = mData.pid
    local iRank = 0
    self:CheckShowData()
    local mMyRank = self:GetShowRankDataByKey(db_key(iPid))
    if mMyRank then
        iRank = mMyRank[10]
    end
    local lResult = self:GetRankShowDataByLimit(20)
    local mTop20 = {}
    local mUnit
    for _,lInfo in pairs(lResult) do
        mUnit ={ }
        mUnit.point = lInfo[1]
        mUnit.pid = lInfo[2]
        mUnit.name = lInfo[3]
        mUnit.shape = lInfo[4]
        mUnit.praise = 0
        mUnit.rank = lInfo[10]
        table.insert(mTop20,mUnit)
    end
    return {rank=iRank,top20 = mTop20}
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
    local mData = self:GetShowRankDataByKey(sKey,bRush)
    if mData then
        mInfo.pid = mData[2]
        mInfo.grade = mData[5]
        mInfo.name = mData[3]
        mInfo.point = mData[1]
        mInfo.segment = mData[7]
        mInfo.my_rank = mData[10]
    end
    if next(mInfo) then
        mNet.arena_rank = mInfo
    end
    return mNet
end

function CRank:SendSimpleRankData()
    local oWorldMgr = global.oWorldMgr
    local lPid = {}
    local lData = {}
    local list, pid, rank
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

function CRank:PackRushRankInfo()
    local lRank = {}
    local iPid, iRank
    for iPage, mData in pairs(self.m_mRushData) do
        for _, info in pairs(mData) do
            iPid = info[2]
            iRank =info[10]
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
                target = info[2],
                rank = info[10],
                reason = sReason,
                info = string.format("{ point = %s }", info[1]),
            }
            record.user("rank", subtype, mLog)
        end
    end
end