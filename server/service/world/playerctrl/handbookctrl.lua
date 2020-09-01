--import module
local global = require "global"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local bookctrl = import(service_path("handbook.bookctrl"))
local chapterctrl = import(service_path("handbook.chapterctrl"))
local conditionctrl = import(service_path("handbook.conditionctrl"))

HANDBOOK_ITEM = 11822
HANDBOOK_TYPE = gamedefines.HANDBOOK_TYPE

local mKey2Func={
}

CHandBookCtrl = {}
CHandBookCtrl.__index = CHandBookCtrl
inherit(CHandBookCtrl, datactrl.CDataCtrl)

function CHandBookCtrl:New(pid)
    local o = super(CHandBookCtrl).New(self, {pid = pid})
    o:Init()
    return o
end

function CHandBookCtrl:Init()
    self.m_oBookCtrl = bookctrl.NewBookCtrl()
    self.m_oChapterCtrl = chapterctrl.NewChapterCtrl()
    self.m_oConditionCtrl = conditionctrl.NewConditionCtrl()
    self.m_mRedPoint = {}
    for _, iBookType in pairs(HANDBOOK_TYPE) do
        self.m_mRedPoint[iBookType]  = 0
    end
end

function CHandBookCtrl:Release()
    self.m_oBookCtrl:Release()
    self.m_oChapterCtrl:Release()
    self.m_oConditionCtrl:Release()
    super(CHandBookCtrl).Release(self)
end

function CHandBookCtrl:Load(mData)
    mData = mData or {}
    local mBookData = mData["book"] or {}
    self.m_oBookCtrl:Load(mBookData)
    local mChapterData = mData["chapter"] or {}
    self.m_oChapterCtrl:Load(mChapterData)
    local mConditionData = mData["condition"] or {}
    self.m_oConditionCtrl:Load(mConditionData)

    local mRedPoint = mData["red_point"] or {}
    for sBookType, iPoint in pairs(mRedPoint) do
        local iBookType = tonumber(sBookType)
        self.m_mRedPoint[iBookType] = iPoint or 0
    end
end

function CHandBookCtrl:Save()
    local mData = {}
    mData["book"] = self.m_oBookCtrl:Save()
    mData["chapter"] = self.m_oChapterCtrl:Save()
    mData["condition"] = self.m_oConditionCtrl:Save()
    local mRedPoint = {}
    for iBookType, iPoint in pairs(self.m_mRedPoint) do
        mRedPoint[db_key(iBookType)] = iPoint or 0
    end
    mData["red_point"] = mRedPoint
    return mData
end

function CHandBookCtrl:OnLogin(oPlayer, bReEnter)
    self.m_oConditionCtrl:OnLogin(oPlayer, bReEnter)
    self.m_oChapterCtrl:OnLogin(oPlayer, bReEnter)
    self.m_oBookCtrl:OnLogin(oPlayer, bReEnter)
    local mBookList = self.m_oBookCtrl:GetList()
    local lNetBookInfo = {}
    for iBookID, oBook in pairs(mBookList) do
        local mNet = self.m_oBookCtrl:PackBookInfo(iBookID)
        if next(mNet) then
            mNet["chapter"] = self:PackBookChapterInfo(iBookID)
            table.insert(lNetBookInfo, mNet)
        end
    end
    local lRedPoint = {}
    for iBookType, iPoint in pairs(self.m_mRedPoint) do
        table.insert(lRedPoint, {
            book_type = iBookType,
            red_point = iPoint,
            })
    end
    if next(lNetBookInfo) then
        oPlayer:Send("GS2CLoginBookList", {
            book_list = lNetBookInfo,
            red_points = lRedPoint,
            })
    end
end

function CHandBookCtrl:OnLogout(oPlayer)
end

function CHandBookCtrl:OnDisconnected(oPlayer)
end

function CHandBookCtrl:UnDirty()
    super(CHandBookCtrl).UnDirty(self)
    self.m_oBookCtrl:UnDirty()
    self.m_oChapterCtrl:UnDirty()
    self.m_oConditionCtrl:UnDirty()
end

function CHandBookCtrl:IsDirty()
    if super(CHandBookCtrl).IsDirty(self) then
        return true
    end
    if self.m_oBookCtrl:IsDirty() then
        return true
    end
    if self.m_oChapterCtrl:IsDirty() then
        return true
    end
    if self.m_oConditionCtrl:IsDirty() then
        return true
    end
    return false
end

function CHandBookCtrl:PushCondition(sKey, mData)
    local oHandBookMgr = global.oHandBookMgr
    local lCondition = oHandBookMgr:GetConditionByKey(sKey)
    local lCheckCondition = {}
    for _, iConditionID in ipairs(lCondition) do
        if not self.m_oConditionCtrl:IsDone(iConditionID) then
            self:CheckCondition(iConditionID, sKey, mData)
            if self.m_oConditionCtrl:IsDone(iConditionID) then
                self:ConditionDone(iConditionID)
            end
        end
    end
end

function CHandBookCtrl:CheckCondition(iConditionID, sKey, mData)
    local mCondition = self:HasCondition(iConditionID)
    local iDegreeType =mCondition["degreetype"]
    local sFunName = mKey2Func[sKey]
    local iValue = mData["value"]
    if sFunName then
        local func = self[sFunName]
        iValue = func(self, iConditionID, sKey, mData)
    end
    if iValue > 0 then
        if iDegreeType == 1 then
            self.m_oConditionCtrl:SetCndProgress(iConditionID, iValue)
        elseif iDegreeType == 2 then
            self.m_oConditionCtrl:AddCndProgress(iConditionID, iValue)
        end
    end
end

function CHandBookCtrl:ConditionDone(iConditionID)
    local lConditionEffect = self:GetCondtionEffect(iConditionID)
    for _, id in ipairs(lConditionEffect) do
        if id // 100000 == 3 then
            self:AddChapterCondition(id, iConditionID)
        else
            self:AddBookCondition(id, iConditionID)
        end
    end
end

function CHandBookCtrl:GetChapterEffect(iChapterID)
    local res = require "base.res"
    return res["daobiao"]["handbook"]["chapter_effect"][iChapterID] or {}
end

function CHandBookCtrl:GetCondtionEffect(iConditionID)
    local res = require "base.res"
    return res["daobiao"]["handbook"]["condition_effect"][iConditionID] or {}
end

function CHandBookCtrl:PackBookChapterInfo(iBookID)
    local res  = require "base.res"
    local mBookData = res["daobiao"]["handbook"]["book"][iBookID]
    assert(mBookData, string.format("handbook err: book id %s not exsit!", iBookID))
    local lChapter = mBookData["chapter_list"] or {}
    local lChapterNet = {}
    for _, iChapterID in ipairs(lChapter) do
        local mNet = self.m_oChapterCtrl:PackChapterInfo(iChapterID)
        if next(mNet) then
            table.insert(lChapterNet, mNet)
        end
    end
    return lChapterNet
end

function CHandBookCtrl:GetPid()
    return self:GetInfo("pid")
end

function CHandBookCtrl:GetOwner()
    local iPid = self:GetPid()
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    return oPlayer
end

function CHandBookCtrl:HasCondition(iConditionID)
    local res = require "base.res"
    return res["daobiao"]["handbook"]["condition"][iConditionID]
end

function CHandBookCtrl:CheckRedPoint(iBookType)
    return self.m_oBookCtrl:CheckRedPoint(iBookType)
end

function CHandBookCtrl:GetRedPoint(iBookType)
    return self.m_mRedPoint[iBookType]
end

function CHandBookCtrl:SetRedPoint(iBookType, iPoint)
    self:Dirty()
    self.m_mRedPoint[iBookType] = iPoint
end

function CHandBookCtrl:IsRedPoint(iBookType)
    return self:GetRedPoint(iBookType) ~= 0
end

function CHandBookCtrl:CloseHandBookUI(oPlayer, iBookType)
    -- local bRedPoint = self:CheckRedPoint(iBookType)
    local lUnSetBook = self.m_oBookCtrl:UnSetRedPoint(iBookType, 1)
    if next(lUnSetBook) or self:IsRedPoint(iBookType) then
        self:SetRedPoint(iBookType, 0)
        self:SendRedPointInfo(iBookType)
    end
    for _, iBookID in ipairs(lUnSetBook) do
        self:BookInfoChange(iBookID)
    end
    -- if not bRedPoint then
    --     self:SetRedPoint(iBookType, 0)
    --     self:SendRedPointInfo(iBookType)
    -- end
end

function CHandBookCtrl:SendRedPointInfo(iBookType)
    local oPlayer = self:GetOwner()
    if oPlayer then
        local mNet = {
            book_type = iBookType,
            red_point = self:GetRedPoint(iBookType),
        }
        oPlayer:Send("GS2CHandBookRedPoint", {red_point = mNet})
    end
end
---------------------------------------------book-------------------------------------------------

function CHandBookCtrl:AddBookCondition(iBookID, iConditionID)
    if self.m_oBookCtrl:HasCondition(iBookID, iConditionID) then
        return
    end
    self.m_oBookCtrl:AddCondition(iBookID, iConditionID)
    local oBook = self.m_oBookCtrl:GetBook(iBookID)
    local iBookType = oBook:Type()
    local oCondition = self.m_oConditionCtrl:GetCondition(iConditionID)
    local bRed = false
    if oCondition then
        if oCondition:SubType() == 1 then
            oBook:SetShow(iBookID)
            bRed = true
        elseif oCondition:SubType() == 3 then
            oBook:SetUnlock()
        end
    end
    if oBook:IsConditionDone() then
        if oBook:IsUnlock() then
            local oPlayer = self:GetOwner()
            if oBook:Type() == HANDBOOK_TYPE.PARTNER then
                oPlayer:PushAchieve("解锁伙伴数量",{value = 1})
            end
        end
        bRed = true
    end
    if bRed then
        oBook:SetRedPoint(1)
        self:SetRedPoint(iBookType, 1)
        self:SendRedPointInfo(iBookType)
    end
    self:BookInfoChange(iBookID)
end

function CHandBookCtrl:AddBook(iBookID)
    if self.m_oBookCtrl:HasBook(iBookID) then
        return
    end
    self.m_oBookCtrl:AddBook(iBookID)
    self:BookInfoChange(iBookID)
end

function CHandBookCtrl:UnlockBook(oPlayer, iBookID)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    local oBook = self.m_oBookCtrl:GetBook(iBookID)
    if oBook then
        if self:ValidUnlockBook(oPlayer, oBook) then
            local iNeedKeys = oBook:GetUnlockKeys()
            local sReason = "UnlockBook"
            local fCallback = function (mRecord,mData)
                local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
                if oPlayer then
                    oPlayer.m_oHandBookCtrl:_TrueUnlockBook(oPlayer,iBookID,mData)
                end
            end
            if iNeedKeys > 0 then
                local mArgs = {}
                oPlayer.m_oItemCtrl:RemoveItemAmount(HANDBOOK_ITEM, iNeedKeys, sReason,mArgs,fCallback)
            else
                local mData = {
                    success = true
                }
                oPlayer.m_oHandBookCtrl:_TrueUnlockBook(oPlayer,iBookID,mData)
            end
        end
    else
        oNotifyMgr:Notify(iPid, "该书未开启")
    end
end

function CHandBookCtrl:_TrueUnlockBook(oPlayer,iBookID,mData)
    local oNotifyMgr = global.oNotifyMgr
    local bSuccess = mData.success
    if not bSuccess then
        oNotifyMgr:Notify(iPid,"网络异常,请稍后再试")
        return
    end
    local oBook = self.m_oBookCtrl:GetBook(iBookID)
    if oBook then
        oBook:SetUnlock()
        self:BookInfoChange(iBookID)
    end
end

function CHandBookCtrl:ValidUnlockBook(oPlayer, oBook)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if not oBook:IsShow() then
        oNotifyMgr:Notify(iPid, "解锁书失败，该书未开启")
        return false
    end
    if not oBook:IsConditionDone() then
        oNotifyMgr:Notify(iPid, "解锁书失败，条件未解锁")
        return false
    end
    if  oBook:IsUnlock() then
        oNotifyMgr:Notify(iPid, "解锁书失败，该书已解锁")
        return false
    end
    local iNeedKeys = oBook:GetUnlockKeys()
    if iNeedKeys > 0 then
        if oPlayer.m_oItemCtrl:GetItemAmount(HANDBOOK_ITEM) >= iNeedKeys then
            return true
        else
            oNotifyMgr:Notify(iPid, "时光钥匙不足，阅读伙伴传记可获得更多钥匙")
            return false
        end
    end
    return true
end

function CHandBookCtrl:EnterBookName(oPlayer, iBookID)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    local oBook = self.m_oBookCtrl:GetBook(iBookID)
    if oBook then
        local sReason = "EnterBookName"
        local fCallback = function (mRecord,mData)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oPlayer.m_oHandBookCtrl:_TrueEnterBookName(oPlayer,iBookID,mData)
            end
        end
        if self:ValidEnterName(oPlayer,oBook) then
            local iNeedKeys = oBook:GetEnterNameKeys()
            if iNeedKeys > 0 then
                local mArgs = {}
                oPlayer.m_oItemCtrl:RemoveItemAmount(HANDBOOK_ITEM, iNeedKeys, sReason,mArgs,fCallback)
            else
                local mData = {
                    success = true
                }
                oPlayer.m_oHandBookCtrl:_TrueEnterBookName(oPlayer,iBookID,mData)
            end
        end
    else
        oNotifyMgr:Notify(iPid, "名字录入失败，该书未开启")
    end
end

function CHandBookCtrl:_TrueEnterBookName(oPlayer,iBookID,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local bSuccess = mData.success
    if not bSuccess then
        oNotifyMgr:Notify(iPid,"网络异常，请稍后再试")
        return
    end
    local oBook = self.m_oBookCtrl:GetBook(iBookID)
    if oBook then
        oBook:SetName()
        if oBook:IsRepair() then
            local oPlayer = self:GetOwner()
            if oPlayer then
                local sKey = string.format("获得%s完整佚书", oBook:Name())
                oPlayer:PushAchieve(sKey,{value = 1})
            end
        end
        self:BookInfoChange(iBookID)
    end
end

function CHandBookCtrl:ValidEnterName(oPlayer, oBook)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if not oBook:IsShow() then
        oNotifyMgr:Notify(iPid, "名字录入失败，该书未开启")
        return false
    end
    if not oBook:IsConditionDone() then
        oNotifyMgr:Notify(iPid, "名字录入失败，条件未解锁")
        return false
    end
    if not oBook:IsUnlock() then
        oNotifyMgr:Notify(iPid, "名字录入失败，书未解锁")
        return false
    end
    if  oBook:IsName() then
        oNotifyMgr:Notify(iPid, "名字录入失败，该名字已录入")
        return false
    end
    local iNeedKeys = oBook:GetEnterNameKeys()
    if iNeedKeys > 0 then
        if oPlayer.m_oItemCtrl:GetItemAmount(HANDBOOK_ITEM) >= iNeedKeys then
            return true
        else
            oNotifyMgr:Notify(iPid, "时光钥匙不足，阅读伙伴传记可获得更多钥匙")
            return false
        end
    end
    return true
end

function  CHandBookCtrl:RepairBookDraw(oPlayer, iBookID)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    local oBook = self.m_oBookCtrl:GetBook(iBookID)
    if oBook then
        if self:ValidRepairBookDraw(oPlayer, oBook) then
            local sReason = "RepairBookDraw"
            local mArgs = {}
            local fCallback = function (mRecord,mData)
                local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
                if oPlayer then
                    oPlayer.m_oHandBookCtrl:_TrueRepairBookDraw(oPlayer,iBookID,mData)
                end
            end
            local iNeedKeys = oBook:GetUnlockKeys()
            if iNeedKeys > 0 then
                local mArgs = {}
                oPlayer.m_oItemCtrl:RemoveItemAmount(HANDBOOK_ITEM, iNeedKeys, sReason,mArgs,fCallback)
            else
                local mData = {
                    success = true
                }
                oPlayer.m_oHandBookCtrl:_TrueRepairBookDraw(oPlayer,iBookID,mData)
            end
        end
    else
        oNotifyMgr:Notify(iPid, "修复绘像失败，书未解锁")
    end
end

function CHandBookCtrl:_TrueRepairBookDraw(oPlayer,iBookID,mData)
    local bSuccess = mData.success
    if not bSuccess then
        return
    end
    local oBook = self.m_oBookCtrl:GetBook(iBookID)
    if oBook then
        oBook:SetRepair()
        self:BookInfoChange(iBookID)
        if oBook:IsName() then
            local oPlayer = self:GetOwner()
            if oPlayer then
                local sKey = string.format("获得%s完整佚书", oBook:Name())
                oPlayer:PushAchieve(sKey,{value = 1})
            end
        end
    end
end

function CHandBookCtrl:ValidRepairBookDraw(oPlayer, oBook)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if not oBook:IsShow() then
        oNotifyMgr:Notify(iPid, "修复绘像失败，该书未开启")
        return false
    end
    if not oBook:IsConditionDone() then
        oNotifyMgr:Notify(iPid, "修复绘像失败，条件未解锁")
        return false
    end
    if not oBook:IsUnlock() then
        oNotifyMgr:Notify(iPid, "修复绘像失败，书未解锁")
        return false
    end
    local iNeedKeys = oBook:GetUnlockKeys()
    if iNeedKeys > 0 then
        if oPlayer.m_oItemCtrl:GetItemAmount(HANDBOOK_ITEM) >= iNeedKeys then
            return true
        else
            oNotifyMgr:Notify(iPid, "时光钥匙不足，阅读伙伴传记可获得更多钥匙")
            return false
        end
    end
    return true
end

function CHandBookCtrl:UpdateBookChapter(iBookID, iChapterID, bRedPoint)
    if not self.m_oBookCtrl:HasChapter(iBookID, iChapterID) then
        local oBook = self.m_oBookCtrl:AddChapter(iBookID, iChapterID)
        if bRedPoint then
            oBook:SetRedPoint(2)
            local iBookType = oBook:Type()
            self:SetRedPoint(iBookType, 1)
            self:SendRedPointInfo(iBookType)
        end
    end
    self:BookInfoChange(iBookID)
end

function CHandBookCtrl:BookInfoChange(iBookID)
    local mNet = self.m_oBookCtrl:PackBookInfo(iBookID)
    if next(mNet) then
        mNet["chapter"] = self:PackBookChapterInfo(iBookID)
        local oPlayer = self:GetOwner()
        if oPlayer then
            oPlayer:Send("GS2CBookInfoChange", {book_info = mNet})
        end
    end
end

------------------------------------------------chapter----------------------------------------------
function CHandBookCtrl:AddChapterCondition(iChapterID, iConditionID)
    local bUnlock = self.m_oChapterCtrl:IsUnlock(iChapterID)
    local bDone = self.m_oChapterCtrl:ConditionDone(iChapterID)
    if self.m_oChapterCtrl:HasCondition(iChapterID, iConditionID) then
        return
    end

    self.m_oChapterCtrl:AddCondition(iChapterID, iConditionID)
    local bRedPoint = false
    if (bUnlock ~= self.m_oChapterCtrl:IsUnlock(iChapterID)) or (bDone ~= self.m_oChapterCtrl:ConditionDone(iChapterID)) then
        bRedPoint = true
    end
    local lBookEffect = self:GetChapterEffect(iChapterID)
    for _, iBookID in ipairs(lBookEffect) do
        self:UpdateBookChapter(iBookID, iChapterID, bRedPoint)
    end
end

function CHandBookCtrl:UnlockChapter(oPlayer, iChapterID)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    local oChapter = self.m_oChapterCtrl:GetChapter(iChapterID)
    if not oChapter then
        oChapter = self.m_oChapterCtrl:AddChapter(iChapterID)
    end
    if self:ValidUnlockChapter(oPlayer, oChapter) then
        local sReason = "UnlockChapter"
        local fCallback = function (mRecord,mData)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                oPlayer.m_oHandBookCtrl:_TrueUnlockChapter(oPlayer,iChapterID,mData)
            end
        end
        local iNeedKeys = oChapter:GetUnlockKeys()
        if iNeedKeys > 0 then
            local mArgs = {}
            oPlayer.m_oItemCtrl:RemoveItemAmount(HANDBOOK_ITEM, iNeedKeys, sReason,mArgs,fCallback)
        else
            local mData = {
                success = true
            }
            oPlayer.m_oHandBookCtrl:_TrueUnlockChapter(oPlayer,iChapterID,mData)
        end

    end
end

function CHandBookCtrl:_TrueUnlockChapter(oPlayer,iChapterID,mData)
    local bSuccess = mData.success
    if not bSuccess then
        return
    end
    local oChapter = self.m_oChapterCtrl:GetChapter(iChapterID)
    if not oChapter then
        return
    end
    oChapter:SetUnlock()
    local lBookEffect = self:GetChapterEffect(iChapterID)
    for _, iBookID in ipairs(lBookEffect) do
        self:UpdateBookChapter(iBookID, iChapterID)
    end
end

function CHandBookCtrl:ValidUnlockChapter(oPlayer, oChapter)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if not oChapter:IsConditionDone() then
        oNotifyMgr:Notify(iPid, "解锁章节失败，条件未完成")
        return false
    end
    if oChapter:IsUnlock() then
        oNotifyMgr:Notify(iPid, "解锁章节失败，章节已解锁")
        return false
    end
    local iNeedKeys = oChapter:GetUnlockKeys()
    if iNeedKeys > 0 then
        if oPlayer.m_oItemCtrl:GetItemAmount(HANDBOOK_ITEM) >= iNeedKeys then
            return true
        else
            oNotifyMgr:Notify(iPid, "时光钥匙不足，阅读伙伴传记可获得更多钥匙")
            return false
        end
    end
    return true
end

function CHandBookCtrl:ReadChapter(oPlayer, iChapterID)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oChapter = self.m_oChapterCtrl:GetChapter(iChapterID)
    if not oChapter then
        oChapter = self.m_oChapterCtrl:AddChapter(iChapterID)
    end
    if self:ValidReadChapter(oPlayer, oChapter) then
        local sReason = string.format("读取图鉴章节 %s", iChapterID)
        oChapter:SetRead()
        local iAddKeys = oChapter:ReadRewardKeys()
        if iAddKeys > 0 then
            oPlayer:GiveItem({{HANDBOOK_ITEM, iAddKeys}}, sReason)
        end
        local mReward = oChapter:ReadReward()
        if next(mReward) then
            local lGive = self:TranferReward(mReward)
            self:AddReward(lGive, sReason, {cancel_show = 1})
        end
        local lBookEffect = self:GetChapterEffect(iChapterID)
        for _, iBookID in ipairs(lBookEffect) do
            self:UpdateBookChapter(iBookID, iChapterID)
            local oBook = self.m_oBookCtrl:GetBook(iBookID)
            if oBook and oBook:Name() == "重华" then
                oPlayer:PushAchieve("阅读重华传记", {value = 1})
            end
        end
        record.user("handbook", "read_chapter", {
            pid = self:GetPid(),
            chapter_id = iChapterID,
            is_read = oChapter:GetRead(),
            })
    end
end

function CHandBookCtrl:TranferReward(mReward)
    local lGive = {}
    for _, m in ipairs(mReward) do
        table.insert(lGive, {m.sid, m.amount})
    end
    return lGive
end

function CHandBookCtrl:ValidReadChapter(oPlayer, oChapter)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if not oChapter:IsConditionDone() then
        oNotifyMgr:Notify(iPid, "读取章节失败，条件未完成")
        return false
    end
    if not oChapter:IsUnlock() then
        oNotifyMgr:Notify(iPid, "读取章节失败，章节未解锁")
        return false
    end
    if oChapter:IsRead() then
        oNotifyMgr:Notify(iPid, "读取章节失败，章节已读取")
        return false
    end
    return true
end

function CHandBookCtrl:OpenBookChapter(oPlayer, iBookID)
    local oBook = self.m_oBookCtrl:GetBook(iBookID)
    if not oBook then
        return
    end

    if oBook:IsRedPoint(1) or oBook:IsRedPoint(2) then
        local iBookType = oBook:Type()
        oBook:UnSetRedPoint(1)
        oBook:UnSetRedPoint(2)
        self:BookInfoChange(iBookID)
        local bRedPoint =  self:CheckRedPoint(iBookType)
        if not bRedPoint then
            self:SetRedPoint(iBookType,0)
            self:SendRedPointInfo(iBookType)
        end
    end
end

function CHandBookCtrl:AddReward(lGive, sReason, mArgs)
    lGive = lGive or {}
    if not next(lGive) then
        return
    end
    local oPlayer = self:GetOwner()
    if oPlayer and oPlayer:ValidGive(lGive,{cancel_tip = 1}) then
        oPlayer:GiveItem(lGive, sReason, mArgs)
    else
        self:SendRewardMail(lGive, sReason, mArgs)
    end

    record.user("handbook", "add_reward", {
        pid = self:GetPid(),
        reward = ConvertTblToStr(lGive),
        reason = sReason,
        })
end

function CHandBookCtrl:SendRewardMail(lGive, sReason, mArgs)
    lGive = lGive or {}
    local oMailMgr = global.oMailMgr
    local iMailId = 1
    local mData, name = oMailMgr:GetMailInfo(iMailId)
    local oItems = {}
    for _, m in ipairs (lGive) do
        local sid, amount = table.unpack(m)
        local oItem = loaditem.ExtCreate(sid)
        oItem:SetAmount(amount or 1)
        table.insert(oItems, oItem)
    end
    oMailMgr:SendMail(0, name, self:GetPid(), mData, {}, oItems)
    oNotifyMgr:Notify(self:GetPid(), "背包已满，道具已通过邮件发放")
end

function CHandBookCtrl:TestCmd(oPlayer, sCmd, mArgs)
    local sReason = "gm"
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if sCmd == "conditiondone" then
        local iConditionID = table.unpack({mArgs})
        local mCondition = self:HasCondition(iConditionID)
        if mCondition then
            local lValue = split_string(mCondition["condition"], "=")
            local sKey, iVal = table.unpack(lValue)
            self:PushCondition(sKey, {value = tonumber(iVal)})
            oNotifyMgr:Notify(iPid, "解锁条件成功")
        else
            oNotifyMgr:Notify(iPid,string.format("条件id:%s", iConditionID or 0))
        end
    elseif sCmd == "allcondition" then
        local res = require "base.res"
        local mData = res["daobiao"]["handbook"]["condition"]
        for iConditionID, mCondition in pairs(mData) do
            local lValue = split_string(mCondition["condition"], "=")
            local sKey, iVal = table.unpack(lValue)
            self:PushCondition(sKey, {value = tonumber(iVal)})
        end
        oNotifyMgr:Notify(iPid, "完成所有条件")
    end
end