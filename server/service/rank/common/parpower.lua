--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local multirank = import(service_path("multirankbase"))
local parpowerunit = import(service_path("common/parpowerunit"))

function NewRankObj(...)
    return CRank:New(...)
end

CRank = {}
CRank.__index = CRank
inherit(CRank, multirank.CRank)

function CRank:Init(idx, sName)
    super(CRank).Init(self, idx, sName)

    local res = require "base.res"
    local mData = res["daobiao"]["partner"]["partner_info"]
    for iType, mPar in pairs(mData) do
        if mPar.rank == 0 then
            local oRank = parpowerunit.NewRankObj(self.m_iRankIndex, self.m_sRankName, iType)
            self.m_mList[iType] = oRank
        end
    end
end

function CRank:OnLogin(iPid, bReEnter)
    if not bReEnter then
        local mSend = {[iPid] = 1}
        self:RefreshPowerRank(mSend)
    end
end

function CRank:RefreshPowerRank(mPid)
    mPid = mPid or {}
    if not next(mPid) then
        return
    end
    local list = {}
    local mRank, sKey, mData, iRank, mPar
    for iPid, _ in pairs(mPid) do
        mRank = {}
        sKey = db_key(iPid)
        for _, oRank in pairs(self.m_mList) do
            mData = oRank:GetShowRankDataByKey(sKey)
            if mData then
                iRank = mData[7]
                mPar = oRank:PackRankPartner(sKey)
                mRank[mPar.parid] = iRank
            end
        end
        table.insert(list, {pid = iPid, rank = mRank})
    end
    interactive.Send(".world", "partner", "UpdateParPowerRank", {list = list})
end

function CRank:GetRankParInfo(iType, iTarget)
    local oRank = self:GetRankObj(iType)
    if oRank then
        return oRank:GetRankParInfo(iTarget)
    end
end

function CRank:NewHour(iWeekDay, iHour)
end

function CRank:SendReward()
end

function CRank:OnRefreshData()
    self.m_iRefresh = self.m_iRefresh or table_count(self.m_mList)
    self.m_iRefresh = self.m_iRefresh - 1
    if self.m_iRefresh <= 0 then
        local mSend = {}
        for iType, oRank in pairs(self.m_mList) do
            for sPid, _ in pairs(oRank.m_mShowRank) do
                if not mSend[sPid] then
                    mSend[tonumber(sPid)] = 1
                end
            end
        end
        self:RefreshPowerRank(mSend)
        self.m_iRefresh = table_count(self.m_mList)
    end
end

function CRank:CountRankFirst()
    local iCnt = 0
    for idx, oRank in pairs(self.m_mList) do
        if oRank:HasFirstUnit() then
            iCnt = iCnt + 1
        end
    end
    return iCnt
end

function CRank:OnUpdateParName(iParType, iPid, sName)
    local oRank = self:GetRankObj(iParType)
    if oRank then
        return oRank:OnUpdateParName(db_key(iPid), sName)
    end
    return false
end

function CRank:OnUpdateParModel(iParType, iPid, mModel)
    local oRank = self:GetRankObj(iParType)
    if oRank then
        return oRank:OnUpdateParModel(db_key(iPid), mModel)
    end
    return false
end

function CRank:PackRushRankInfo()
    local mRank = {}
    for iType, oRank in pairs(self.m_mList) do
        mRank[iType] = oRank:PackRushRankInfo()
    end
    return mRank
end

function CRank:PackPartnerRankList(iPid, bRush)
    local sKey = db_key(iPid)
    local lRank = {}
    for iType, oRank in pairs(self.m_mList) do
        local m = oRank:GetRankByKey(sKey, bRush)
        if m then
            table.insert(lRank, m)
        end
    end
    local mNet = {}
    mNet.ranks = lRank
    return mNet
end

function CRank:QueryRankBack()
    local lRank = {}
    for iType, oRank in pairs(self.m_mList) do
        list_combine(lRank, oRank:QueryRankBack())
    end
    return lRank
end