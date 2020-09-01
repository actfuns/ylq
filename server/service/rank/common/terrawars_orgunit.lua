--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local gamedb = import(lualib_path("public.gamedb"))
local rankbase = import(service_path("rankbase"))

function NewRankObj(...)
    return CRank:New(...)
end

CRank = {}
CRank.__index = CRank
inherit(CRank, rankbase.CRankBase)

function CRank:Init(idx, sName,iOrgId)
    super(CRank).Init(self, idx, sName)
    self.m_lSortDesc = {true,false}
    self.m_iOrgId = iOrgId
end

function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.personal_points,mData.time,mData.pid,mData.name, mData.position,}
end

function CRank:RepackInfo(mUnit)
    local mData = {
        personal_points = mUnit[1],
        pid = mUnit[3],
        time = mUnit[2],
        name = mUnit[4],
        position = mUnit[5],
    }
    return mData
end

function CRank:DoStubShowData()
    self:Resort()
    super(CRank).DoStubShowData(self)
end

function CRank:UpdateName(sName, mData)
    mData[4] = sName
end

function CRank:UpdatePosition(iPosition, mData)
    mData[5] = iPosition
end

function CRank:UpdatePersonalPoints(iPoints,mData)
    mData[1] = iPoints
end

function CRank:PackShowRankData(iPid, iPage)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.page = iPage
    mNet.first_stub = self.m_iFirstStub
    local mData = self:GetShowRankData(iPage)
    local lOrgRank = {}
    local mUnit
    for idx, lInfo in ipairs(mData) do
        mUnit = {}
        mUnit.personal_points = lInfo[1]
        mUnit.pid = lInfo[3]
        mUnit.name = lInfo[4]
        mUnit.position = lInfo[5]
        mUnit.rank_shift = lInfo[6]
        mUnit.rank = lInfo[7]
        table.insert(lOrgRank, mUnit)
    end
    if #lOrgRank then
        mNet.terrawars_org_rank = lOrgRank
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
        mInfo.personal_points = mData[1]
        mInfo.pid = mData[3]
        mInfo.name = mData[4]
        mInfo.position = mData[5]
        mInfo.my_rank = self.m_mShowRank[sKey]
    end
    if next(mInfo) then
        mNet.terrawars_org_rank = mInfo
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

function CRank:GetCompareVal(sKey)
    local mVal = {}
    local mData = self.m_mRankData[sKey]
    if mData then
        mVal.personal_points = mData[1]
        mVal.time = mData[2]
    end
    return mVal
end

function CRank:EqualVal(mOldVal, mNewVal)
    mOldVal = mOldVal or {}
    mNewVal = mNewVal or {}
    return mOldVal.personal_points == mNewVal.personal_points and mOldVal.time == mNewVal.time
end

function CRank:Save()
    local mData = super(CRank).Save(self)
    mData.orgid = self.m_iOrgId
    return mData
end

function CRank:Load(mData)
    -- body
    super(CRank).Load(self,mData)
    self.m_iOrgId = mData.orgid
end

function CRank:OnTerrPointUpdate(iOrgId,iPid,iPersonal_points)
    self:Dirty()
    local mData = self.m_mRankData[db_key(iPid)]
    if mData then
        mData[1] = iPersonal_points
    end
end

function CRank:NewHour(iWeekDay, iHour)
end

function CRank:ResetRankData()
    self:Dirty()
    for sPid,info in pairs(self.m_mRankData) do
        info[1] = 0
    end
    self:RefreshData()
end

function CRank:MergeFrom(mFromData, mArgs)
    super(CRank).MergeFrom(self,mFromData,mArgs)
    self:ResetRankData()
    return true
end

function CRank:PackRankRewardInfo()
    local lRankInfo = {}
    for iPage, mShowData in ipairs (self.m_mShowData) do
        for _, mData in ipairs(mShowData) do
            if mData[1] ~= 0 then
               table.insert(lRankInfo, {
                pid = mData[3],
                personal_points = mData[1],
                rank = mData[7],
                })
           end
        end
    end
    return lRankInfo
end

function CRank:SendReward()
    local mData = self:PackRankRewardInfo()
    if next(mData) then
        local mRet = {}
        mRet["name"] = self.m_sRankName
        mRet["data"] = mData
        mRet["mailid"] = 37
        interactive.Send(".world", "rank", "SendRankReward", mRet)
    end
end