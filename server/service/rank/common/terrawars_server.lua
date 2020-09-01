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
    self.m_lSortDesc = {true,false}
end

function CRank:GenRankUnit(mData)
    return db_key(mData.orgid), {mData.org_points,mData.time,mData.org_name,mData.org_level,mData.orgid,mData.flag,mData.leader,}
end

function CRank:GetCompareVal(sKey)
    local mVal = {}
    local mData = self.m_mRankData[sKey]
    if mData then
        mVal.org_points = mData[1]
        mVal.time = mData[2]
    end
    return mVal
end

function CRank:IsOrgRank()
    return true
end

function CRank:EqualVal(mOldVal, mNewVal)
    mOldVal = mOldVal or {}
    mNewVal = mNewVal or {}
    return mOldVal.org_points >= mNewVal.org_points and mOldVal.time == mNewVal.time
end

function CRank:RepackInfo(mUnit)
    local mData = {
        org_name = mUnit[3],
        org_level = mUnit[4],
        orgid = mUnit[5],
        flag = mUnit[6],
        time = mUnit[2],
        leader = mUnit[7],
        org_points = mUnit[1],
    }
    return mData
end

function CRank:UpdateName(sName, mData)
    mData[3] = sName
end

function CRank:UpdatePersonalPoints(iPoints,mData)
    mData[1] = iPoints
end

function CRank:PackShowRankData(iOrgId, iPage)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.page = iPage
    mNet.first_stub = self.m_iFirstStub
    local mData = self:GetShowRankData(iPage)
    local lServerRank = {}
    local mUnit
    for idx, lInfo in ipairs(mData) do
        mUnit = {}
        mUnit.org_name = lInfo[3]
        mUnit.org_level = lInfo[4]
        mUnit.orgid = lInfo[5]
        mUnit.flag = lInfo[6]
        mUnit.leader = lInfo[7]
        mUnit.org_points = lInfo[1]
        mUnit.rank_shift = lInfo[8]
        mUnit.rank = lInfo[9]

        table.insert(lServerRank, mUnit)
    end
    if #lServerRank then
        mNet.terrawars_server_rank = lServerRank
    end
    return mNet
end

function CRank:GetCondition(iRank, mData)
    return {rank = iRank, orgid = mData[5]}
end

function CRank:PackTop3RankData(iOrgId)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.my_rank = self.m_mShowRank[db_key(iOrgId)]

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

function CRank:GetMyRank(iPid,iOrgId)
    local sKey = db_key(iOrgId)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.end_time = self.m_iEndTime
    mNet.rank_count = self:CountShowRankData()
    local mInfo = {}
    local mData = self:GetShowRankDataByKey(sKey)
    if mData then
        mInfo.org_name = mData[3]
        mInfo.org_level = mData[4]
        mInfo.orgid = mData[5]
        mInfo.flag = mData[6]
        mInfo.leader = mData[7]
        mInfo.org_points = mData[1]
        mInfo.my_rank = self.m_mShowRank[sKey]
    end
    if next(mInfo) then
        mNet.terrawars_server_rank = mInfo
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
            table.insert(list, {orgid = data[5]})
        end
        lData[iPage] = list
    end
    local mRet = {}
    mRet.idx = self.m_iRankIndex
    mRet.data = lData
    interactive.Send(".world", "rank", "SendSimpleRankData", mRet)
end

function CRank:UpdateLeader(mLeader,mData)
    mData[7] = mLeader.name
end

function CRank:OnOrgLeaderChange(sKey, mLeader)
    local bUpdate = false
    local mShowData = self:GetShowRankDataByKey(sKey)
    if mData then
        self:UpdateLeader(mLeader, mData)
        bUpdate = true
    end
    local mKeepData = self.m_mRankData[sKey]
    if mKeepData then
        self:UpdateLeader(mLeader, mKeepData)
        bUpdate = true
    end
    if bUpdate then
        self:Dirty()
    end

    return bUpdate
end

function CRank:UpdateOrgPoints(iOrgPoints,mData)
    mData[1] = iOrgPoints
end

function CRank:DoStubShowData()
    self:Resort()
    super(CRank).DoStubShowData(self)
end

function CRank:OnTerrOrgPointUpdate(iOrgId,iOrgPoints)
    local sKey = db_key(iOrgId)
    local bUpdate = false
    local mShowData = self:GetShowRankDataByKey(sKey)
    if mData then
        self:UpdateOrgPoints(iOrgPoints, mData)
        bUpdate = true
    end
    local mKeepData = self.m_mRankData[sKey]
    if mKeepData then
        self:UpdateOrgPoints(iOrgPoints, mKeepData)
        bUpdate = true
    end
    if bUpdate then
        self:Dirty()
    end
end

function CRank:ResetRankData()
    self:SendReward()
    super(CRank).ResetRankData(self)
end

function CRank:PackRankRewardInfo()
    local lRankInfo = {}
    for iPage, mShowData in ipairs (self.m_mShowData) do
        for _, mData in ipairs(mShowData) do
            if mData[1] ~= 0 then
               table.insert(lRankInfo, {
                orgid = mData[5],
                org_points = mData[1],
                rank = mData[9],
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
        interactive.Send(".world", "rank", "SendTerraServReward", mRet)
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
