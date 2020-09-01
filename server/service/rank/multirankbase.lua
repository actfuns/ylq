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
    self.m_mList = {}
end

function CRank:LoadDb()
    for iType, oRank in pairs(self.m_mList) do
        oRank:LoadDb()
    end
end

function CRank:GetRankObj(key)
    return self.m_mList[key]
end

function CRank:OnUpdateName(sKey,sName)
    local bUpdate = false
    for key,oRank in pairs(self.m_mList) do
        if oRank:OnUpdateName(sKey, sName) then
            bUpdate = true
        end
    end
    return bUpdate
end

function CRank:PackShowRankData(key1,iPage,key2, bRush)
    local oRank = self:GetRankObj(key2)
    if not oRank then
        return self:PackRankFristList(key1,iPage,key2, bRush)
    end
    return oRank:PackShowRankData(key1,iPage, bRush)
end

function CRank:PackTop3RankData(key2,key1)
    local oRank = self:GetRankObj(key1)
    if oRank then
        return oRank:PackTop3RankData(key2)
    end
end

function CRank:GetMyRank(key1 ,key2, bRush, mDefault)
    local oRank = self:GetRankObj(key2)
    if oRank then
        return oRank:GetMyRank(key1,bRush, mDefault)
    end
    return {idx=self.m_iRankIndex, key = key2, end_time = self:RefreshTime(), rank_count = self:CountRankFirst()}
end

function CRank:CountRankFirst()
    return table_count(self.m_mList)
end

function CRank:RefreshTime()
    local iKey = table_random_key(self.m_mList)
    local oRank = self:GetRankObj(iKey)
    return oRank:RefreshTime()
end

function CRank:SendSimpleRankData()
    for key1,oRank in pairs(self.m_mList) do
        oRank:SendSimpleRankData()
    end
end

function CRank:CleanAllData()
    self:Dirty()
    for key1,oRank in pairs(self.m_mList) do
        oRank:CleanAllData()
    end
end

function CRank:ResetRankData()
    self:Dirty()
    for key1,oRank in pairs(self.m_mList) do
        oRank:ResetRankData()
    end
end

function CRank:PushDataToRank(mData,mArgs,bReInsert)
    local oRank = self:GetRankObj(mArgs.key)
    if oRank then
        -- self:Dirty()
        oRank:PushDataToRank(mData,mArgs.key,bReInsert)
    end
end

function CRank:IsDirty()
    local bDirty = super(CRank).IsDirty(self)
    if bDirty then
        return true
    end
    for iType, oRank in pairs(self.m_mList) do
        if oRank:IsDirty() then
            return true
        end
    end
    return false
end

function CRank:UnDirty()
    super(CRank).UnDirty(self)
    for iType, oRank in pairs(self.m_mList) do
        oRank:UnDirty()
    end
end

function CRank:CleanRankCache()
    self:Dirty()
    for key1,oRank in pairs(self.m_mList) do
        oRank:CleanRankCache()
    end
end

function CRank:DoStubShowData()
    for key1,oRank in pairs(self.m_mList) do
        oRank:DoStubShowData()
    end
end

function CRank:RefreshData()
    for key1,oRank in pairs(self.m_mList) do
        oRank:RefreshData()
    end
end

function CRank:OnRefreshData()
end

function CRank:RemoveDataFromRank(key1, key2)
    local oRank = self:GetRankObj(key1)
    if oRank then
        oRank:RemoveDataFromRank({key =key2})
    end
end

function CRank:MergeFrom(mFromData, mArgs)
    local  key1 = mArgs.key
    local oRank = self:GetRankObj(key1)
    if oRank then
        oRank:MergeFrom(mFromData, mArgs)
    end
end

function CRank:PackRankFristList(key1,iPage,key2, bRush)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.page = iPage
    mNet.first_stub = 0
    mNet.key = key1
    local list = {}
    local m
    for key1, oRank in pairs(self.m_mList) do
        m = oRank:PackRankFristList(bRush)
        if next(m) then
            table.insert(list, m)
        end
    end
    mNet.parpower = list
    return mNet
end

function CRank:DoRushRankEnd()
    for key1, oRank in pairs(self.m_mList) do
        oRank:DoRushRankEnd()
    end
end

function CRank:RushRankShowEnd()
    for key1, oRank in pairs(self.m_mList) do
        oRank:RushRankShowEnd()
    end
end

function CRank:IsRushRankEnd()
    for key1, oRank in pairs(self.m_mList) do
        if oRank:IsRushRankEnd() then
            return true
        end
    end
    return false
end

function CRank:IsRushShowEnd()
    for key1, oRank in pairs(self.m_mList) do
        if oRank:IsRushShowEnd() then
            return true
        end
    end
    return false
end

function CRank:TestOP(iPid,iCmd,...)
    local oRankMgr = global.oRankMgr
    local mArgs = {...}
    --刷榜
    if iCmd == 100 then

    elseif iCmd == 101 then
        for key1,oRank in pairs(self.m_mList) do
             oRank:DoStubShowData()
             oRank:SendSimpleRankData()
        end
        self:OnRefreshData()
         oRankMgr:ClearClientRankData(self.m_iRankIndex)
    --清除数据
    elseif iCmd == 102 then
        self:CleanAllData()
    elseif iCmd == 103 then
        self:SendReward()
    elseif iCmd == 104 then
        for key1,oRank in pairs(self.m_mList) do
             oRank:DoRushRankEnd()
        end
         oRankMgr:ClearClientRankData(self.m_iRankIndex)
    end
end