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

function CRank:New(iRankIdx, sName, key)
    local o = super(CRank).New(self, iRankIdx, sName)
    o:Init(iRankIdx, sName, key)
    return o
end

function CRank:Init(iRankIdx, sName,key)
    super(CRank).Init(self, iRankIdx, sName)
    self.m_lSortDesc = {true, false}
    self.m_Key = key
end

function CRank:ConfigSaveFunc()
    local idx = self.m_iRankIndex
    local iKey = self.m_Key
    self:ApplySave(function ()
        local oRankMgr = global.oRankMgr
        local oBaseRank = oRankMgr:GetRankObj(idx)
        local obj = oBaseRank:GetRankObj(iKey)
        if not obj then
            record.warning(string.format("rank save err: %d no obj",idx))
            return
        end
        obj:_CheckSaveDb()
    end)
end

function CRank:_CheckSaveDb()
    local sName = self:DBTbName()
    assert(not is_release(self), string.format("rank %s is releasing, save fail", sName))
    assert(not self:IsLoading(), string.format("rank %s is loading, save fail", sName))
    self:SaveDb()
end

function CRank:SaveDb()
    if self:IsLoading() then return end
    if not self:IsDirty() then return end
    local sName = self:DBTbName()
    assert(sName,"rankname can't be empty")
    local mData = {
        rank_name = sName,
        data = self:Save()
    }
    gamedb.SaveDb("rank","common", "SaveDb", {
        module = "rankdb",
        cmd = "SaveRankByName",
        data = mData
    })
    self:UnDirty()
end

function CRank:_CheckRefresh()
    --下个正点刷新
    local iNow = get_time()
    local idx = self.m_iRankIndex
    local iKey = self.m_Key
    local iUseSec = iNow % 3600
    local iSec = 3600 - iUseSec
    if iSec > 0 then
        self.m_iEndTime = iNow + iSec
        self:DelTimeCb("_CheckRefresh")
        self:AddTimeCb("_CheckRefresh", iSec * 1000, function()
            local oRankBase = global.oRankMgr:GetRankObj(idx)
            if oRankBase then
                local oRank = oRankBase:GetRankObj(iKey)
                if oRank then
                    oRank:_CheckRefresh1()
                end
            end
        end)
    else
        self:_CheckRefresh1()
    end
end

function CRank:_CheckRefresh1()
    local mData = self:GetRankData()
    local iRefreshSec = mData.refresh_time
    local idx = self.m_iRankIndex
    if iRefreshSec > 0 then
        self.m_iEndTime = get_time() + iRefreshSec
        local iKey = self.m_Key
        self:DelTimeCb("_CheckRefresh1")
        self:AddTimeCb("_CheckRefresh1", iRefreshSec * 1000, function()
            local oRankBase = global.oRankMgr:GetRankObj(idx)
            if oRankBase then
                local oRank = oRankBase:GetRankObj(iKey)
                if oRank then
                    oRank:_CheckRefresh1()
                end
            end
        end)
    end
    self:RefreshData()
    local oRankBase = global.oRankMgr:GetRankObj(idx)
    if oRankBase then
        oRankBase:OnRefreshData()
    end
end

function CRank:GenRankUnit(mData)
    return db_key(mData.pid), {mData.power,mData.time, mData.pid,mData.name, mData.link}
end

function CRank:DoStubShowData()
    -- self:Resort()
    super(CRank).DoStubShowData(self)
end

function CRank:UpdateName(sName, mData)
    mData[4] = sName
end

function CRank:UpdateParName(sName, mData)
    mData[5].partner.name = sName
end

function CRank:UpdateParModel(mModel, mData)
    mData[5].partner.model_info = mModel
end

function CRank:OnUpdateParName(sKey, sName)
    local bUpdate = false
    local mShowData = self:GetShowRankDataByKey(sKey)
    if mShowData then
        self:UpdateParName(sName, mShowData)
        bUpdate = true
    end
    local mKeepData = self.m_mRankData[sKey]
    if mKeepData then
        self:UpdateParName(sName, mKeepData)
        bUpdate = true
    end
    if bUpdate then
        self:Dirty()
    end
    return bUpdate
end

function CRank:OnUpdateParModel(sKey, mModel)
    local bUpdate = false
    local mShowData = self:GetShowRankDataByKey(sKey)
    if mShowData then
        self:UpdateParModel(mModel, mShowData)
        bUpdate = true
    end
    local mKeepData = self.m_mRankData[sKey]
    if mKeepData then
        self:UpdateParModel(mModel, mKeepData)
        bUpdate = true
    end
    if bUpdate then
        self:Dirty()
    end
    return bUpdate
end

function CRank:PackShowRankData(iPid, iPage, bRush)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.page = iPage
    mNet.first_stub = self.m_iFirstStub
    mNet.key = self.m_Key

    local mData = self:GetShowRankData(iPage, bRush)
    local lNet = {}
    local iPid
    for idx, info in ipairs(mData) do
        iPid = info[3]
        table.insert(lNet, self:PackRankPartner(db_key(iPid), bRush))
    end
    if #lNet then
        mNet.parpower = lNet
    end
    return mNet
end

function CRank:GetCondition(iRank, mData)
    return {rank = iRank, partype = mData[5].partner_type}
end

function CRank:PackTop3RankData(iPid)
    return {}
end

function CRank:PackRankPartner(sKey, bRush)
    local mData = self:GetShowRankDataByKey(sKey, bRush)
    if mData then
        local mPar = mData[5].partner
        return {
            pid = mData[3],
            name =mData[4],
            rank_shift = mData[6],
            rank =  mData[7],
            parid = mPar.parid,
            partype = mPar.partner_type,
            parname = mPar.name,
            star = mPar.star,
            pargrade = mPar.grade,
            power = mPar.power,
            awake = mPar.awake,
        }
    end
    return {}
end

function CRank:RefreshTime()
    return self.m_iEndTime
end

function CRank:GetMyRank(iPid, bRush, mDefault)
    local sKey = db_key(iPid)
    local mNet = {}
    mNet.idx = self.m_iRankIndex
    mNet.end_time = self:RefreshTime()
    mNet.rank_count = self:CountShowRankData(bRush)
    mNet.key = self.m_Key
    local mInfo = self:GetMyRankDefault(iPid, mDefault)
    local mData = self:GetShowRankDataByKey(sKey,bRush)
    if mData then
        mInfo.partner = self:PackRankPartner(sKey,bRush)
        mInfo.my_rank = mData[7]
    end
    if next(mInfo) then
        mNet.parpower_rank = mInfo
    end
    return mNet
end

function CRank:GetMyRankDefault(iPid, mDefault)
    local mInfo = {}
    if mDefault then
        local mPar = mDefault.partner or {}
        if next(mPar) then
            mInfo.partner = {
                pid = mDefault.pid,
                name =mDefault.name,
                parid = mPar.parid,
                partype = mPar.partner_type,
                parname = mPar.name,
                star = mPar.star,
                pargrade = mPar.grade,
                power = mPar.power,
                awake = mPar.awake,
            }
            mInfo.my_rank = 0
        end
    end
    return mInfo
end

function CRank:SendSimpleRankData()
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

function CRank:DBTbName()
    return "partner" .. self.m_Key
end

function CRank:Save()
    local mData = super(CRank).Save(self)
    return mData
end

function CRank:Load(mData)
    super(CRank).Load(self,mData)
end

function CRank:NewHour(iWeekDay, iHour)
end

function CRank:PackRankRewardInfo()
end

function CRank:CompareUnit(mOld, mNew)
    local bSortDesc = self.m_lSortDesc[1]
    local iLen = #self.m_lSortDesc - 1
    for idx = 1, iLen do
        if mOld[idx] ~= mNew[idx] then
            return false
        end
    end
    return true
end

function CRank:GetRankParInfo(iPid)
    local mData = self:GetShowRankDataByKey(db_key(iPid))
    local mRet = {
        idx = self.m_iRankIndex,
    }
    if mData then
        local mLink = {}
        mLink.pid = mData[3]
        mLink.name = mData[4]
        mLink.parinfo = mData[5].partner
        mLink.equip = mData[5].equip
        mLink.soul = mData[5].soul
        mRet.parinfo = mLink
    end
    return mRet
end

function CRank:HasFirstUnit()
    local iPage = 1
    local idx = 1
    local mData = self:GetShowRankData(iPage)
    return mData and mData[idx]
end

function CRank:GetRankByKey(sKey, bRush)
    local mData = self:GetShowRankDataByKey(sKey,bRush)
    if mData then
        return {parid = mData[5].partner.parid, rank = mData[7], power = mData[5].partner.power}
    end
end

function CRank:PackRushRankInfo()
    local lRank = {}
    local iPid, iRank
    for iPage, mData in pairs(self.m_mRushData) do
        for _, info in pairs(mData) do
            iPid = info[3]
            iRank =info[7]
            if iRank > 10 then
                return lRank
            end
            table.insert(lRank, {pid = iPid, rank = iRank})
        end
    end
    return lRank
end

function CRank:PackRankFristList(bRush)
    local iPage = 1
    local idx = 1
    local mNet = {}
    local mData = self:GetShowRankData(iPage, bRush)
    mData = mData and mData[idx]
    if mData then
        local iPid = mData[3]
        mNet =  self:PackRankPartner(db_key(iPid), bRush)
    end
    return mNet
end

function CRank:QueryRankBack()
    local lRank = {}
    local iPid, iRank
    for iPage, mData in pairs(self.m_mShowData) do
        for _, info in pairs(mData) do
            iPid = info[3]
            iRank =info[7]
            table.insert(lRank, {
                pid = iPid,
                rank = iRank,
                subtype = self.m_Key,
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
                sub_key = self.m_Key,
                target = info[3],
                rank = info[7],
                reason = sReason,
                info = string.format("{ parpower = %s }", info[1]),
            }
            record.user("rank", subtype, mLog)
        end
    end
end