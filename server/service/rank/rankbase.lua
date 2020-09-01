--import module
local global = require "global"
local skynet = require "skynet"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))

function NewRankObj(...)
    return CRankBase:New(...)
end


CRankBase = {}
CRankBase.__index = CRankBase
inherit(CRankBase, datactrl.CDataCtrl)

function CRankBase:New(idx, sName)
    local o = super(CRankBase).New(self)
    o.m_bLoading = true
    o:Init(idx, sName)
    return o
end

function CRankBase:Init(idx, sName)
    self.m_iShowLimit = 100
    self.m_iSaveLimit = 160
    self.m_mRankData = {}
    self.m_lSortList = {}
    self.m_mShowData = {}
    self.m_mShowRank = {}
    self.m_mTop3Data = {}
    self.m_iRankIndex = idx
    self.m_sShowName = sName
    self.m_sRankName = sName
    self.m_iStubShow = 0
    self.m_iShowPage = 20
    self.m_lSortDesc = {true}  --true 降序, false 升序
    self.m_iFirstStub = 1      --第一次生成排行榜
    self.m_iRushRank = 0    --限时冲榜
    self.m_mRushData = {}  --冲榜数据
    self.m_mRushShow = {} --
end

function CRankBase:ClearData()
    self:Dirty()
    self.m_mRankData = {}
    self.m_lSortList = {}
    self.m_mShowData = {}
    self.m_mShowRank = {}
    self.m_mTop3Data = {}
end

function CRankBase:ResetRankData()
    self:Dirty()
    self.m_mRankData = {}
    self.m_lSortList = {}
end

function CRankBase:PushDataToRank(mData,mArgs,bReInsert)
    local bNeedSort = false
    local sKey, mUnit = self:GenRankUnit(mData)
    if self.m_mRankData[sKey] then
        if self:NeedReplaceRankData(sKey, mUnit) or bReInsert then
            self:Dirty()
            self.m_mRankData[sKey] = nil
            extend.Array.remove(self.m_lSortList, sKey)
            self:InsertToOrderRank(sKey, mUnit)
        end
    else
        self:InsertToOrderRank(sKey, mUnit)
    end
end

function CRankBase:RemoveDataFromRank(mData)
    local sKey = db_key(mData.key)
    if self.m_mRankData[sKey] then
        self:Dirty()
        self.m_mRankData[sKey] = nil
        extend.Array.remove(self.m_lSortList, sKey)
    end
end

function CRankBase:SortFunction(mCompare1, mCompare2)
    local bSortDesc = self.m_lSortDesc[1]
    if not mCompare1 then return not bSortDesc end
    if not mCompare2 then return bSortDesc end

    for idx, bSortDesc in ipairs(self.m_lSortDesc) do
        if mCompare1[idx] > mCompare2[idx] then
            return bSortDesc
        elseif mCompare1[idx] < mCompare2[idx] then
            return not bSortDesc
        end
    end

    return bSortDesc
end

function CRankBase:GenRankUnit(mData)
    return db_key(mData.key), {mData.value}
end

function CRankBase:GenCompareUnit(sKey, mData)
    if mData then return mData end

    return self.m_mRankData[sKey]
end

function CRankBase:BinarySearch(sKey, mUnit)
    local iLen = #self.m_lSortList
    if iLen <= 0 then return 1 end

    local mCompare1 = nil
    local mCompare2 = self:GenCompareUnit(sKey, mUnit)

    if iLen >= self.m_iSaveLimit then
        mCompare1 = self:GenCompareUnit(self.m_lSortList[iLen])
        if self:SortFunction(mCompare1, mCompare2) then
            return
        else
            self:Dirty()
            self.m_mRankData[self.m_lSortList[iLen]] = nil
            table.remove(self.m_lSortList, iLen)
        end
    end

    local iStart, iEnd = 1, #self.m_lSortList
    local iMiddle
    while iStart <= iEnd do
        iMiddle = (iStart + iEnd) // 2
        mCompare1 = self:GenCompareUnit(self.m_lSortList[iMiddle])
        if self:SortFunction(mCompare1, mCompare2) then
            iStart = iMiddle + 1
        else
            iEnd = iMiddle - 1
        end
    end
    return iStart
end

function CRankBase:InsertToOrderRank(sKey, mUnit)
    local iIdx = self:BinarySearch(sKey, mUnit)
    if iIdx and iIdx >= 1 and iIdx <= self.m_iSaveLimit then
        table.insert(self.m_lSortList, iIdx, sKey)
        self.m_mRankData[sKey] = mUnit
        self:Dirty()
        return true
    end
    return false
end

function CRankBase:NeedReplaceRankData(sKey, mNewData)
    local mOldCompare = self:GenCompareUnit(sKey)
    local mNewCompare = self:GenCompareUnit(sKey, mNewData)
    if not self:CompareUnit(mOldCompare, mNewCompare) then
        return true
    end
    return false
end

function CRankBase:CompareUnit(mOld,mNew)
    local bSortDesc = self.m_lSortDesc[1]
    for idx, bSortDesc in ipairs(self.m_lSortDesc) do
        if mOld[idx] ~= mNew[idx] then
            return false
        end
    end
    return true
end

function CRankBase:CheckResetData(iWeekDay, iHour)
    local mData = self:GetRankData()
    local sResetTime = mData.reset_time
    if sResetTime and sResetTime ~= "" then
        local mArgs = formula_string(sResetTime, {})
        if mArgs.weekday and mArgs.hour then
            if mArgs.weekday == iWeekDay and mArgs.hour == iHour then
                self:ResetRankData()
            end
        elseif mArgs.weekday and mArgs.weekday == iWeekDay then
                self:ResetRankData()
        elseif mArgs.hour and mArgs.hour == iHour then
                self:ResetRankData()
        end
    end
end

function CRankBase:NewHour(iWeekDay, iHour)
    self:CheckResetData(iWeekDay, iHour)
end

function CRankBase:UpdateName(sName,mData)
    return false
end

function CRankBase:OnUpdateName(sKey, sName)
    local bUpdate = false
    local mShowData = self:GetShowRankDataByKey(sKey)
    if mShowData then
        self:UpdateName(sName, mShowData)
        bUpdate = true
    end
    local mKeepData = self.m_mRankData[sKey]
    if mKeepData then
        self:UpdateName(sName, mKeepData)
        bUpdate = true
    end
    if bUpdate then
        self:Dirty()
    end

    return bUpdate
end

function CRankBase:UpdatePosition(iPosition, mData)
    return false
end

function CRankBase:OnUpdatePosition(sKey, iPosition)
    local bUpdate = false
    local mShowData = self:GetShowRankDataByKey(sKey)
    if mData then
        self:UpdatePosition(iPosition, mData)
        bUpdate = true
    end
    local mKeepData = self.m_mRankData[sKey]
    if mKeepData then
        self:UpdatePosition(iPosition, mKeepData)
        bUpdate = true
    end
    if bUpdate then
        self:Dirty()
    end

    return bUpdate
end

function CRankBase:OnLogin(iPid, bReEnter)
end

function CRankBase:OnLogout(iPid)
end

function CRankBase:GetRankShift(sKey, iCurrRank)
    if not self.m_mShowRank[sKey] then
        return iCurrRank + self.m_iShowLimit
    end
    return iCurrRank - self.m_mShowRank[sKey]
end

function CRankBase:DoStubShowData()
    if table_count(self.m_mShowData) > 0 then
        self.m_iFirstStub = 0
    end
    local iMaxPage = self.m_iShowLimit // self.m_iShowPage + 1
    local iCount, iPage = 0, 1
    local lPageList = {}
    local mTmpData
    local iRankShift
    self.m_mShowData = {}
    self.m_mShowRank = {}

    for idx, sKey in ipairs(self.m_lSortList) do
        if self.m_mRankData[sKey] then
            mTmpData = table_deep_copy(self.m_mRankData[sKey])
            iRankShift = self:GetRankShift(sKey, idx)
            table.insert(mTmpData, iRankShift)
            table.insert(mTmpData, idx)
            table.insert(lPageList, mTmpData)
            iCount  = iCount + 1
            self.m_mShowRank[sKey] = idx
        end
        if iCount >= self.m_iShowPage then
            self.m_mShowData[iPage] = lPageList
            iCount = 0
            iPage = iPage + 1
            lPageList = {}
            if iPage > iMaxPage then
                break
            end
        end
    end
    if #lPageList > 0 then
        self.m_mShowData[iPage] = lPageList
    end
    self:Dirty()
end

function CRankBase:GetCompareVal(sKey)
    return {}
end

function CRankBase:EqualVal(mOldValue, mNewValue)
    return true
end

function CRankBase:ValidPage(iPage)
    if not iPage then
        return false
    end
    if iPage < 1 then
        return false
    end
    if iPage > (self.m_iShowLimit / self.m_iShowPage + 1) then
        return false
    end
    return true
end

function CRankBase:GetShowRankData(iPage, bRush)
    if not self:ValidPage(iPage) then
        return {}
    end
    if bRush and self:IsRushRankEnd() then
        return self.m_mRushData[iPage] or {}
    end
    return self.m_mShowData[iPage] or {}
end

function CRankBase:GetRankShowDataByLimit(iLimit)
    local iPage, iRet = iLimit // self.m_iShowPage, iLimit % self.m_iShowPage
    local lResult = {}
    for i = 1, iPage do
        for _, mInfo in pairs(self.m_mShowData[i] or {}) do
            table.insert(lResult, mInfo)
        end
    end
    if iRet > 0 then
        for idx, mInfo in pairs(self.m_mShowData[iPage+1] or {}) do
            if idx > iRet then break end
            table.insert(lResult, mInfo)
        end
    end
    return lResult
end

function CRankBase:GetOrgUnit(iOrgId)
end

function CRankBase:PackShowRankData(iPid, iPage, bRush)
    --local lPageList = self.m_mShowData[iPage] or {}
    return {}
end

function CRankBase:PackOrgShowRankData(iOrgId,iPid,iPage)
end

function CRankBase:PackTop3RankData()
    return {}
end

function CRankBase:GetCondition(mData)
    --
end

function CRankBase:GetMyRank(iPid, ...)
    return {
        idx = self.m_iRankIndex,
        rank_count = 0,
    }
end

function CRankBase:GetMyRankDefault(iPid, ...)
    -- body
end

function CRankBase:Key()
    -- body
end

function CRankBase:RemoteDone(mKeepInfo)
    if not mKeepInfo then
        return
    end
    if not self.m_mShowData[1] then
        return
    end
    for iRank, mData in pairs(mKeepInfo) do
        mData.value = self.m_mShowData[1][iRank][1]
        self.m_mTop3Data[iRank] = mData
    end
    self:Dirty()
end

function CRankBase:GetShowRankDataByKey(sKey, bRush)
    local idx = self.m_mShowRank[sKey]
    if bRush and self:IsRushRankEnd() then
        idx = self.m_mRushShow[sKey]
    end
    if idx and idx > 0 then
        local iPage = idx // self.m_iShowPage
        local iPageIdx = idx % self.m_iShowPage
        if iPageIdx == 0 then
            iPageIdx = self.m_iShowPage
        else
            iPage = iPage + 1
        end
        if iPage == 0 then
            iPage = 1
        end
        local mData = self:GetShowRankData(iPage,bRush)
        if mData then
            return mData[iPageIdx]
        end
    end
end

function CRankBase:CountShowRankData(bRush)
    local iPageCount = table_count(self.m_mShowData)
    if bRush and self:IsRushRankEnd() then
        iPageCount = table_count(self.m_mRushData)
    end
    if iPageCount > 0 then
        local mShowData = self:GetShowRankData(iPageCount, bRush)
        return (iPageCount - 1) * self.m_iShowPage + table_count(mShowData)
    end
    return 0
end

function CRankBase:SendReward()
    local mData = self:PackRankRewardInfo()
    if next(mData) then
        local mRet = {}
        mRet["name"] = self.m_sRankName
        mRet["data"] = mData
        interactive.Send(".world", "rank", "SendRankReward", mRet)
    end
end
function CRankBase:PackUpvoteInfo(iPid, iPage)
    local iKey
    local mUpvote
    local lUpvote = {}
    local lShowData = self:GetShowRankData(iPage)
    for iRank, mData in ipairs(lShowData) do
        iKey = self:Key(mData)
        mUpvote = self:GetUpvote(tostring(iKey))
        table.insert(lUpvote, {
            key = iKey,
            status = (mUpvote[iPid] and 1) or 0,
            count = table_count(mUpvote),
            })
    end
    local mNet = {}
    mNet["idx"] = self.m_iRankIndex
    mNet["page"] = iPage
    mNet["upvote_info"] = lUpvote
    return mNet
end

function CRankBase:PackRankRewardInfo()
    return {}
end

function CRankBase:Save()
    local mData = {}
    mData.rank_data = self.m_mRankData
    mData.sort_list = self.m_lSortList
    mData.show_data = self.m_mShowData
    mData.show_rank = self.m_mShowRank
    mData.top3_data = self.m_mTop3Data
    mData.first_stub = self.m_iFirstStub
    mData.rush_rank = self.m_iRushRank
    return mData
end

function CRankBase:Load(mData)
    mData = mData or {}
    self.m_mRankData = mData.rank_data or {}
    self.m_lSortList = mData.sort_list or {}
    self.m_mShowData = mData.show_data or {}
    self.m_mShowRank = mData.show_rank or {}
    self.m_mTop3Data = mData.top3_data or {}
    self.m_iFirstStub = mData.first_stub or 1
    self.m_iRushRank = mData.rush_rank or 0
end

function CRankBase:LoadRush(mData)
    mData = mData or {}
    if not self:IsRushShowEnd() then
        self.m_mRushShow = mData.rush_show
        self.m_mRushData = mData.rush_data
    end
end

function CRankBase:MergeFinish()
    -- body
end

function CRankBase:LoadFinish()
    self.m_bLoading = false
end

function CRankBase:IsLoading()
    return self.m_bLoading
end

function CRankBase:DBTbName()
    return self.m_sRankName
end

function CRankBase:SaveDb()
    if self:IsLoading() then return end
    if not self:IsDirty() then return end
    assert(self.m_sRankName,"rankname can't be empty")
    local mData = {
        rank_name = self:DBTbName(),
        data = self:Save()
    }
    gamedb.SaveDb("rank","common", "SaveDb", {
        module = "rankdb",
        cmd = "SaveRankByName",
        data = mData
    })
    self:UnDirty()
end

local lLoadInfo = {
    {"LoadRankByName","Load"},
    {"LoadRushRankByName","LoadRush"},
}
function CRankBase:LoadDb(idx)
    idx = idx or 1
    if idx > #lLoadInfo then
        self:LoadEnd()
        return
    end
    local mData = {
        rank_name = self:DBTbName(),
    }
    local sLoadFunc, rFunc = table.unpack(lLoadInfo[idx])
    local mArgs = {
        module = "rankdb",
        cmd = sLoadFunc,
        data = mData,
    }
    gamedb.LoadDb("rank", "common", "LoadDb", mArgs,
        function (mRecord, mData)
            self:_LoadModule(rFunc, mRecord, mData)
            if not is_release(self) then
                self:LoadDb(idx + 1)
            end
        end)
end

function CRankBase:_LoadModule(rFunc, mRecord, mData)
    self[rFunc](self,mData.data or {})
end

function CRankBase:LoadEnd()
    self:LoadFinish()
    self:Schedule()
    self:ConfigSaveFunc()
end

function CRankBase:ConfigSaveFunc()
    local idx = self.m_iRankIndex
    self:ApplySave(function ()
        local oRankMgr = global.oRankMgr
        local obj = oRankMgr:GetRankObj(idx)
        if not obj then
            record.warning(string.format("rank save err: %d no obj",idx))
            return
        end
        obj:_CheckSaveDb()
    end)
end

function CRankBase:_CheckSaveDb()
    assert(not is_release(self), string.format("rank %s is releasing, save fail", self.m_sRankName))
    assert(not self:IsLoading(), string.format("rank %s is loading, save fail", self.m_sRankName))
    self:SaveDb()
end

function CRankBase:Schedule()
    self:_CheckRefresh()
    self:SendSimpleRankData()
end

function CRankBase:_CheckRefresh()
    --下个正点刷新
    local iNow = get_time()
    local idx = self.m_iRankIndex
    local iUseSec = iNow % 3600
    local iSec = 3600 - iUseSec
    self.m_iEndTime = iNow + iSec
    self:DelTimeCb("_CheckRefresh")
    self:AddTimeCb("_CheckRefresh", iSec * 1000, function()
        local oRank = global.oRankMgr:GetRankObj(idx)
        if oRank then
            oRank:_CheckRefresh1()
        end
    end)
    -- self:RefreshData()
end

function CRankBase:_CheckRefresh1()
    local mData = self:GetRankData()
    local iRefreshSec = mData.refresh_time
    if iRefreshSec > 0 then
        self.m_iEndTime = get_time() + iRefreshSec
        local idx = self.m_iRankIndex
        self:DelTimeCb("_CheckRefresh1")
        self:AddTimeCb("_CheckRefresh1", iRefreshSec * 1000, function()
            local oRank = global.oRankMgr:GetRankObj(idx)
            if oRank then
                oRank:_CheckRefresh1()
            end
        end)
    end
    self:RefreshData()
end

function CRankBase:RefreshData(sReason)
    self:DoStubShowData()
    self:SendSimpleRankData()
end

function CRankBase:GetRankData()
    local res = require "base.res"
    local mData = res["daobiao"]["rank"][self.m_iRankIndex]
    assert(mData, string.format("rank data err: %s", self.m_iRankIndex))
    return mData
end



function CRankBase:SendSimpleRankData()

end

function CRankBase:CleanRankCache()
    self:ResetRankData()
end


function CRankBase:CleanAllData()
    self:ResetRankData()
    self:RefreshData()
    local oRankMgr = global.oRankMgr
    oRankMgr:ClearClientRankData(self.m_iRankIndex)
end

function CRankBase:GetRankInfo(iKey)
    local sKey = tostring(iKey)
    local iRank = self.m_mShowRank[sKey] or 0
    return {
        key = iKey,
        rank = iRank,
    }
end

function CRankBase:IsOrgRank()
    return false
end

function CRankBase:OnUpdateOrgInfo(iOrgId,mInfo)
end

function CRankBase:IsRushRankEnd()
    return self.m_iRushRank == 1
end

function CRankBase:IsRushShowEnd()
    return self.m_iRushRank == 2
end

function CRankBase:NewOrgUnit(iOrgId)
end

function CRankBase:RemoveOrgUint(iOrgId)
end

function CRankBase:NewOrgMem(iOrgId,iPid)
end

function CRankBase:OnTerrPointUpdate(iOrgId,iPid,iPersonal_points)
end

--每小时重新二分插入形成新的排名，避免一有变动就重新排序
function CRankBase:Resort()
    local mTemp = table_deep_copy(self.m_mRankData)
    for sKey,mUnit in pairs(mTemp) do
        local mData = self:RepackInfo(mUnit)
        if mData then
            self:PushDataToRank(mData,nil,true)
        end
    end
end

function CRankBase:RepackInfo(mUnit)
end

function CRankBase:OnOrgLeaderChange(sKey, mLeader)
    return false
end

function CRankBase:UpdateLeader(mLeader,mData)
end

function CRankBase:LeaveOrg(iOrgId,iPid)
end

function CRankBase:PackRushRankInfo()
    return {}
end

function CRankBase:PackRankFristList()
    return {}
end

function CRankBase:MergeFrom(mFromData, mArgs)
    self:Dirty()
    mFromData = mFromData or {}
    local mRankData = mFromData.rank_data or {}
    for sKey, mUnit in pairs(mRankData) do
        self:PushMergeDataToRank(sKey, mUnit)
    end
    return true
end

function CRankBase:PushMergeDataToRank(sKey, mUnit)
    if self.m_mRankData[sKey] then
        if self:NeedReplaceRankData(sKey, mUnit) then
            self:Dirty()
            self.m_mRankData[sKey] = nil
            extend.Array.remove(self.m_lSortList, sKey)
            self:InsertToOrderRank(sKey, mUnit)
        end
    else
        self:InsertToOrderRank(sKey, mUnit)
    end
end

function CRankBase:DoRushRankEnd()
    self:Dirty()
    self.m_iRushRank = 1
    self:DoStubShowData()
    self.m_mRushData = table_deep_copy(self.m_mShowData)
    self.m_mRushShow = table_deep_copy(self.m_mShowRank)
    self:SaveRushRank()
end

function CRankBase:RushRankShowEnd()
    self:Dirty()
    self.m_iRushRank = 2
    self.m_mRushData = {}
    self.m_mRushShow = {}
end

function CRankBase:SaveRushRank()
    local mSave = {}
    mSave.rush_data = self.m_mRushData
    mSave.rush_show = self.m_mRushShow
    local mData = {
        rank_name = self:DBTbName(),
        data = mSave,
    }
    gamedb.SaveDb("rank","common", "SaveDb", {
        module = "rankdb",
        cmd = "SaveRushRankByName",
        data = mData,
    })
end

function CRankBase:LogInfo(subtype, sReason)
end

function CRankBase:QueryRankBack()
    return {}
end

function CRankBase:TestOP(iPid,iCmd,...)
    local mArgs = {...}
    --刷榜
    if iCmd == 100 then

    elseif iCmd == 101 then
         self:DoStubShowData()
         self:SendSimpleRankData()
         local oRankMgr = global.oRankMgr
         oRankMgr:ClearClientRankData(self.m_iRankIndex)
    --清除数据
    elseif iCmd == 102 then
        self:ResetRankData("gm")
        self:RefreshData("gm")
        global.oRankMgr:ClearClientRankData(self.m_iRankIndex)
    elseif iCmd == 103 then
        self:SendReward()
    elseif iCmd == 104 then
        self:DoRushRankEnd()
        global.oRankMgr:ClearClientRankData(self.m_iRankIndex)
    end
end