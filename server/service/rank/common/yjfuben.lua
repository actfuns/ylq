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
    self.m_PreRank = {}
end

function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.point,mData.time,mData.pid,mData.name,mData.shape,mData.school}
end

function CRank:GetCondition(iRank, mData)
    return {rank = iRank, pid = mData[3]}
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

function CRank:UpdateName(sName, mData)
    mData[4] = sName
end

function CRank:PackShowRankData(iPid, iPage)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.page = iPage
    mNet.first_stub = self.m_iFirstStub
    local mData = self:GetShowRankData(iPage)
    local lYJRank = {}
    local mUnit
    for idx, lInfo in ipairs(mData) do
        mUnit = {}
        mUnit.pid = lInfo[3]
        mUnit.name = lInfo[4]
        mUnit.shape = lInfo[5]
        mUnit.point = lInfo[1]
        mUnit.school = lInfo[6]
        mUnit.rank_shift = lInfo[7]
        mUnit.rank = lInfo[8]
        table.insert(lYJRank, mUnit)
    end
    if #lYJRank then
        mNet.yj_rank = lYJRank
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

function CRank:GetMyRank(iPid)
    local sKey = db_key(iPid)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.end_time = self.m_iEndTime
    mNet.rank_count = self:CountShowRankData()
    local mInfo = {}
    local mData = self:GetShowRankDataByKey(sKey)
    if mData then
        mInfo.pid = mData[3]
        mInfo.name = mData[4]
        mInfo.point = mData[1]
        mInfo.my_rank = mData[8]
    end
    if next(mInfo) then
        mNet.yj_rank = mInfo
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
            point = mData[1],
            rank = mData[8],
            })
        end
    end
    return lRankInfo
end

function CRank:Save()
    local mData = super(CRank).Save(self)
    mData.prerank = self.m_PreRank
    return mData
end

function CRank:Load(mData)
    mData = mData or {}
    super(CRank).Load(self,mData)
    self.m_PreRank = mData.prerank
end

function CRank:SendReward()
    local mData = self:PackRankRewardInfo()
    if next(mData) then
        local mRet = {}
        mRet["pre"] = self.m_PreRank or {}
        mRet["data"] = mData
        self:Dirty()
        self.m_PreRank = mData
        interactive.Send(".world", "yjfuben", "SendReward", mRet)
    end
end

function CRank:DoStubShowData()
    if table_count(self.m_mShowData) > 0 then
        self.m_iFirstStub = 0
    end
    local iMaxPage = self.m_iShowLimit // self.m_iShowPage + 1
    local iCount, iPage = 0, 1
    local lPageList = {}
    local mShowData = {}
    local mShowRank = {}
    local mOldValue
    local iRank = 1

    for idx, sKey in ipairs(self.m_lSortList) do
        if self.m_mRankData[sKey] then
            local mNewValue = self:GetCompareVal(sKey)
            mOldValue = mOldValue or mNewValue
            if not self:EqualVal(mOldValue, mNewValue) then
                if  iPage == iMaxPage then
                    break
                end
                mOldValue = mNewValue
                iRank = iRank + 1
            end
            local mTmpData = table_deep_copy(self.m_mRankData[sKey])
            local iRankShift = self:GetRankShift(sKey, idx)
            table.insert(mTmpData, iRankShift)
            table.insert(mTmpData, iRank)
            table.insert(lPageList, mTmpData)
            iCount  = iCount + 1
            mShowRank[sKey] = idx
        end
        if iCount >= self.m_iShowPage then
            mShowData[iPage] = lPageList
            iCount = 0
            iPage = iPage + 1
            lPageList = {}
            if iPage > iMaxPage then
                break
            end
        end
    end
    if #lPageList > 0 then
        mShowData[iPage] = lPageList
    end
    self.m_mShowData = mShowData
    self.m_mShowRank = mShowRank
    self:Dirty()
end

function CRank:RefreshData()
    local iWeekDay = get_weekday()
    local mTb= get_hourtime({factor=1, hour = 0})
    if (iWeekDay  == 7 or iWeekDay == 3) and mTb.date.hour == 0 then
        super(CRank).RefreshData(self)
        self:SendReward()
        super(CRank).ResetRankData(self)
    else
        super(CRank).RefreshData(self)
    end
end

function CRank:NeedReplaceRankData(sKey, mNewData)
    local mOldCompare = self:GenCompareUnit(sKey)
    local mNewCompare = self:GenCompareUnit(sKey, mNewData)

    if not self:SortFunction(mOldCompare, mNewCompare) then
        return true
    end

    return false
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

function CRank:TestOP(iPid,iCmd,...)
    if iCmd == 104 then
        super(CRank).RefreshData(self)
        self:SendReward()
        super(CRank).ResetRankData(self)
        return
    end
    super(CRank).TestOP(self,iPid,iCmd,...)
end