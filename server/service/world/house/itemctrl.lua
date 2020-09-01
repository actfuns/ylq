--import module
local global = require "global"

local record = require "public.record"
local analy = import(lualib_path("public.dataanaly"))
local datactrl = import(lualib_path("public.datactrl"))
local loaditem = import(service_path("item/loaditem"))

local max = math.max
local min = math.min

CItemCtrl = {}
CItemCtrl.__index = CItemCtrl
inherit(CItemCtrl, datactrl.CDataCtrl)

function CItemCtrl:New(iPid)
    local o = super(CItemCtrl).New(self, {pid = iPid})
    o.m_iOwner = iPid
    o.m_ItemID = {}
    o.m_TraceNo = 1
    o.m_iItemId = 1
    return o
end

function CItemCtrl:Release()
    for _,oItem in pairs(self.m_ItemID) do
        baseobj_safe_release(oItem)
    end
    super(CItemCtrl).Release(self)
end

function CItemCtrl:Save()
    local mData = {}
    local mItemData = {}
    for iItemId,oItem in pairs(self.m_ItemID) do
        table.insert(mItemData,oItem:Save())
    end
    mData["itemdata"] = mItemData
    mData["traceno"] = self.m_TraceNo
    return mData
end

function CItemCtrl:Load(mData)
    mData = mData or {}
    local mItemData = mData["itemdata"] or {}
    for _,mData in pairs(mItemData) do
        local oItem = loaditem.LoadItem(mData["sid"],mData)
        assert(oItem,string.format("item sid error:%s,%s",self.m_iOwner,mData["sid"]))
        self:DispatchItemID(oItem)
        self.m_ItemID[oItem.m_ID] = oItem
        oItem.m_Container = self
    end
    self.m_TraceNo = mData["traceno"] or self.m_TraceNo
    self:Dirty()
end

function CItemCtrl:DispatchTraceNo()
    self:Dirty()
    local iTraceNo = self.m_TraceNo
    self.m_TraceNo = self.m_TraceNo + 1
    return iTraceNo
end

function CItemCtrl:DispatchItemID(oItem)
    local iItemId = self.m_iItemId
    self.m_iItemId = iItemId + 1
    oItem.m_ID = iItemId
    return iItemId
end

function CItemCtrl:UnDirty()
    super(CItemCtrl).UnDirty(self)
    for _,oItem in pairs(self.m_ItemID) do
        if oItem:IsDirty() then
            oItem:UnDirty()
        end
    end
end

function CItemCtrl:IsDirty()
    local bDirty = super(CItemCtrl).IsDirty(self)
   if bDirty then
        return true
    end
    for _,oItem in pairs(self.m_ItemID) do
        if oItem:IsDirty() then
            return true
        end
    end
    return false
end


function CItemCtrl:GetShapeItem(iSid)
    local mItem = {}
    for _,oItem in pairs(self.m_ItemID) do
        if oItem:SID() == iSid then
            table.insert(mItem,oItem)
        end
    end
    return mItem
end

function CItemCtrl:GetItemObj(iSid)
    for _,oItem in pairs(self.m_ItemID) do
        if oItem:SID() == iSid then
            return itemobj
        end
    end
end

function CItemCtrl:HasItem(itemid)
    return self.m_ItemID[itemid]
end

function CItemCtrl:LimitSize()
    return 20
end

function CItemCtrl:ValidAddItem()
    local iLimitSize = self:LimitSize()
    if table_count(self.m_ItemID) < iLimitSize then
        return true
    end
    return false
end

function CItemCtrl:GetCanUseSpaceSize()
    local iLimitSize = self:LimitSize()
    local iSize = iLimitSize - table_count(self.m_ItemID)
    return iSize
end

function CItemCtrl:AddItem(oSrcObj, sReason, mArgs)
    mArgs = mArgs or {}
    self:Dirty()
    local iLast = oSrcObj:GetAmount()
    local iMaxAmount = oSrcObj:GetMaxAmount()
    local mShowInfo = oSrcObj:GetShowInfo()
    for _,oItem in pairs(self.m_ItemID) do
        if oSrcObj:SID() == oItem:SID() then
            local iHave = oItem:GetAmount()
            local iAdd = max(iMaxAmount - iHave,0)
            if iLast > 0 and iAdd > 0 then
                iAdd = min(iAdd,iLast)
                iLast = iLast - iAdd
                self:AddAmount(oSrcObj,-iAdd,sReason)
                self:AddAmount(oItem,iAdd,sReason)
            end
        end
    end
    if not mArgs.cancel_show then
        global.oUIMgr:AddKeepItem(self:GetInfo("pid"), mShowInfo)
    end
    if iLast <= 0 then
        return
    end
    if not self:ValidAddItem() then
        return oSrcObj
    end
    self:AddToContainer(oSrcObj, sReason, mArgs)
end

function CItemCtrl:AddToContainer(oItem, sReason, mArgs)
    self:Dirty()
    if not oItem:GetData("TraceNo") then
        local iTraceNo = self:DispatchTraceNo()
        oItem:SetData("TraceNo",{self:GetInfo("pid"), iTraceNo})
    end
    self:DispatchItemID(oItem)
    self.m_ItemID[oItem.m_ID] = oItem
    oItem.m_Container = self
    self:GS2CAddItem(oItem)
end

function CItemCtrl:RemoveItem(oItem,bRefresh)
    self:Dirty()
    self.m_ItemID[oItem.m_ID] = nil
    oItem.m_Container = nil
    if bRefresh then
        self:GS2CDelItem(oItem)
    end
    baseobj_delay_release(oItem)
end

function CItemCtrl:GetItemAmount(iSid)
    local iAmount = 0
    for _,oItem in pairs(self.m_ItemID) do
        if oItem:SID() == iSid then
            iAmount = iAmount + oItem:GetAmount()
        end
    end
    return iAmount
end

function CItemCtrl:RemoveItemAmount(iSid,iAmount,sReason)
    local iHaveAmount = self:GetItemAmount(iSid)
    local mItemList = self:GetShapeItem(iSid)
    local SortFunc = function (oItem1,oItem2)
        if oItem1:IsBind() ~= oItem2:IsBind() then
            if oItem1:IsBind() then
                return true
            elseif oItem2:IsBind() then
                return true
            end
        else
            if oItem1:GetAmount() ~= oItem2:GetAmount() then
                return oItem1:GetAmount() < oItem2:GetAmount()
            else
                return oItem1.m_ID < oItem2.m_ID
            end
        end
    end
    table.sort(mItemList,SortFunc)

    for _,itemobj in pairs(mItemList) do
        local iSubAmount = itemobj:GetAmount()
        iSubAmount = min(iSubAmount,iAmount)
        iAmount = iAmount - iSubAmount
        self:AddAmount(itemobj,-iSubAmount,sReason)
        if iAmount <= 0 then
            break
        end
    end
    if iAmount > 0 then
        return false
    end
    return true
end

--ItemList:{iSid, iAmount, bBind}
function CItemCtrl:ValidGive(ItemList)
    local iNeedSpace = 0
    for _, mItem in pairs(ItemList) do
        local sid, iAmount, bBind = table.unpack(mItem)
        local lItem = self:GetShapeItem(sid)
        local iCanAddAmount = 0
        local oItem = loaditem.GetItem(sid)
        local iMaxAmount = oItem:GetMaxAmount()
        for _,oItem in pairs(lItem) do
            if oItem:IsBind() == bBind then
                local iAddAmount = max(iMaxAmount-oItem:GetAmount(),0)
                if iAddAmount > 0 then
                    iCanAddAmount = iCanAddAmount + iAddAmount
                end
            end
        end
        local iItemAmount = max(iAmount - iCanAddAmount,0)
        if iItemAmount > 0 then
            local iSize = iItemAmount // iMaxAmount + 1
            if iItemAmount % iMaxAmount == 0 then
                iSize = iItemAmount // iMaxAmount
            end
            iNeedSpace = iNeedSpace + iSize
        end
    end
    local iHaveSpace = self:GetCanUseSpaceSize()
    if iHaveSpace < iNeedSpace then
        return false
    end
    return true
end

--ItemList:{iSid, iAmount, bBind}
function CItemCtrl:GiveItem(ItemList, sReason, mArgs)
    mArgs = mArgs or {}
    local iPid = self:GetInfo("pid")
    for _, mItem in pairs(ItemList) do
        local sid, iAmount, bBind = table.unpack(mItem)
        local iRecord = iAmount
        while(iAmount > 0) do
            local oItem = loaditem.ExtCreate(sid)
            local iAddAmount = min(oItem:GetMaxAmount(),iAmount)
            iAmount = iAmount - iAddAmount
            oItem:SetAmount(iAddAmount)
            if bBind then
                oItem:Bind(iPid)
            end
            self:AddItem(oItem, sReason, mArgs)
            if iAmount <= 0 then
                break
            end
        end
    end
end

function CItemCtrl:AddAmount(oItem,iAmount,sReason,mArgs,bRefresh)
    mArgs = mArgs or {}
    local mLog = {}
    mLog.sid = oItem:SID()
    mLog.traceno = oItem:TraceNo()
    mLog.old = oItem:GetAmount()
    mLog.amount = iAmount
    mLog.reason = sReason
    oItem:AddAmount(iAmount,sReason,mArgs)
    mLog.now = oItem:GetAmount()
    if oItem:GetAmount() <= 0 then
        oItem:GS2CItemAmount(mArgs)
        self:RemoveItem(oItem,sReason,bRefresh)
    else
        if iAmount > 0 then
            oItem:SetCreateTime(get_time())
        end
        oItem:GS2CItemAmount(mArgs)
        if iAmount > 0 and oItem:IsQuickUse() then
             local iOwner = oItem:GetOwner()
             oItem:GS2CItemQuickUse(oItem:ID())
         end
    end
    self:LogItem("role_item_amount",mLog)
    self:LogAnaly(mLog.sid,iAmount,sReason)
end

function CItemCtrl:GS2CAddItem(itemobj)
    local mArgs = mArgs or {}
    local mNet = {}
    local itemdata = itemobj:PackItemInfo()
    mNet["itemdata"] = itemdata
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
    if oPlayer then
        oPlayer:Send("GS2CHouseAddItem",mNet)
    end
end

function CItemCtrl:GS2CDelItem(itemobj)
    local mNet = {}
    mNet["id"] = itemobj.m_ID
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
    if oPlayer then
        oPlayer:Send("GS2CHouseDelItem",mNet)
    end
end

function CItemCtrl:GS2CItemAmount(oItem,mArgs)
    mArgs = mArgs or {}
    local mNet = {}
    mNet["id"] = oItem.m_ID
    mNet["amount"] = oItem:GetAmount()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
    if oPlayer then
        oPlayer:Send("GS2CHouseItemAmount",mNet)
    end
end

function CItemCtrl:PackNetInfo()
    local mNet = {}
    for _,oItem in pairs(self.m_ItemID) do
        table.insert(mNet,oItem:PackItemInfo())
    end
    return mNet
end

function CItemCtrl:GetOwner()
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetInfo("pid")
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    return oPlayer
end

function CItemCtrl:LogItem(sSubType,mLog,mArgs)
    local oPlayer = self:GetOwner()
    if oPlayer then
        mLog.pid = oPlayer:GetPid()
        mLog.name = oPlayer:GetName()
        mLog.grade = oPlayer:GetGrade()
        if mArgs then
            table_combine(mLog, mArgs)
        end
        record.user("item", sSubType, mLog)
    end
end

function CItemCtrl:LogAnaly(iSID,iAmount,sReason)
    local oPlayer = self:GetOwner()
    if oPlayer then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["operation"] = iAmount > 0 and 1 or 2
        mLog["item_id"] = iSID
        mLog["num"] = iAmount
        mLog["remain_num"] = self:GetItemAmount(iSID)
        mLog["reason"] = sReason
        analy.log_data("BackpackChange",mLog)
    end
end