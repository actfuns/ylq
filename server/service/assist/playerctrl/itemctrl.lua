local skynet = require "skynet"
local global = require "global"

local interactive = require "base.interactive"
local extend = require "base.extend"
local record = require "public.record"
local colorstring = require "public.colorstring"
local res = require "base.res"

local shareobj = import(lualib_path("base.shareobj"))
local datactrl = import(lualib_path("public.datactrl"))
local loaditem = import(service_path("item.loaditem"))
local handleitem = import(service_path("item/handleitem"))
local itemdefines = import(service_path("item/itemdefines"))
local gamedefines = import(lualib_path("public.gamedefines"))
local analy = import(lualib_path("public.dataanaly"))

local max = math.max
local min = math.min

local MAX_GRID_SIZE = 500
local CONTAINER_TYPE = gamedefines.ITEM_CONTAINER

function NewContainer( ... )
    return CContainer:New(...)
end

CItemCtrl = {}
CItemCtrl.__index = CItemCtrl
inherit(CItemCtrl, datactrl.CDataCtrl)

function CItemCtrl:New(iPid)
    local o = super(CItemCtrl).New(self, {pid = iPid})
    o.m_mContainer = {}
    o.m_mEquip = {}
    o.m_mFuWenName = {}
    o.m_mBuffStone = {}
    o.m_iTraceNo = 1
    o.m_iItemId = 1
    o.m_iMaxOldGemLv = 0
    o:Init(iPid)
    return o
end

function CItemCtrl:Release()
    for _, oContainer in pairs(self.m_mContainer) do
        baseobj_safe_release(oContainer)
    end
    baseobj_safe_release(self.m_oItemShareObj)
    super(CItemCtrl).Release(self)
end

function CItemCtrl:Init(iPid)
    for _, iType in pairs(CONTAINER_TYPE) do
        if iType ~= CONTAINER_TYPE.EQUIP then
            local oContainer = NewContainer(iPid, iType, self:MaxGridSize(iType))
            self.m_mContainer[iType] = oContainer
        end
    end
    local mShapeAmount = self:PackItemShapeAmount()
    self.m_oItemShareObj = CItemShareObj:New(mShapeAmount)
    self.m_oItemShareObj:Init()
end

function CItemCtrl:MaxGridSize(iType)
    if iType == CONTAINER_TYPE.PARTNER_AWAKE then
        local mAwakeData = res["daobiao"]["partner_item"]["awake_item"]
        return table_count(mAwakeData)
    elseif iType == CONTAINER_TYPE.PARTNER_CHIP then
        local mChipData = res["daobiao"]["partner_item"]["partner_chip"]
        return table_count(mChipData)
    elseif iType == CONTAINER_TYPE.PARTNER_SKIN then
        local mSkinData = res["daobiao"]["partner_item"]["partner_skin"]
        return table_count(mSkinData)
    elseif iType == CONTAINER_TYPE.PARTNER_TRAVEL then
        local mTravelData = res["daobiao"]["partner_item"]["travel"]
        return table_count(mTravelData)
    elseif iType == CONTAINER_TYPE.PARTNER_STONE then
        local mParStone = res["daobiao"]["partner_item"]["stone"]
        return table_count(mParStone)
    else
        return gamedefines.ITEM_CONTAINER_SIZE[iType] or 100
    end
end

function CItemCtrl:Save()
    local mData = {}

    local itemdata = {}
    for iType, oContainer in pairs(self.m_mContainer) do
        iType = db_key(iType)
        itemdata[iType] = oContainer:Save()
    end
    mData["itemdata"] = itemdata
    local mEquip = {}
    for iPos,oEquip in pairs(self.m_mEquip) do
        mEquip[db_key(iPos)] = oEquip:Save()
    end
    mData["equip"] = mEquip
    local mFuWenName = {}
    for iPlan, sName in pairs(self.m_mFuWenName) do
        mFuWenName[db_key(iPlan)] = sName
    end
    mData["fuwen_name"] = mFuWenName
    local mBuffStone = {}
    for sid, oStone in pairs(self.m_mBuffStone) do
        mBuffStone[db_key(sid)] = oStone:Save()
    end
    mData["buff_stone"] = mBuffStone
    mData["trace_no"] = self.m_iTraceNo
    mData["pequip_compose"] = self:GetData("pequip_compose", 0)
    mData["max_gem_lv"] = self.m_iMaxOldGemLv
    return mData
end

function CItemCtrl:Load(mData)
    mData = mData or {}
    local itemdata = mData["itemdata"] or {}
    for iType, data in pairs(itemdata) do
        iType = tonumber(iType)
        local oContainer = self.m_mContainer[iType]
        if oContainer then
            oContainer:Load(data)
        else
            record.error(string.format("item type error:%s,%s", self:GetInfo("pid"), iType))
        end
    end
    local mEquip = mData["equip"] or {}
    for iPos,mEquipData in pairs(mEquip) do
        iPos = tonumber(iPos)
        local oEquip = loaditem.LoadItem(mEquipData["sid"],mEquipData)
        self.m_mEquip[iPos] = oEquip
        oEquip.m_iPos = iPos
        self:DispatchItemID(oEquip)
    end

    local mFuWenName = mData["fuwen_name"] or {}
    for sPlan, sName in pairs(mFuWenName) do
        local iPlan = tonumber(sPlan)
        self.m_mFuWenName[iPlan] = sName
    end

    local mBuffStone = mData["buff_stone"] or {}
    for sid, m in pairs(mBuffStone) do
        local iSid = tonumber(sid)
        local oBuffStone = loaditem.LoadItem(iSid, m)
        self:DispatchItemID(oBuffStone)
        self:WieldBuffStone(oBuffStone)
    end

    self.m_iTraceNo = mData["trace_no"] or self.m_iTraceNo
    self:SetData("pequip_compose", mData.pequip_compose or 0)
    self.m_iMaxOldGemLv = mData["max_gem_lv"] or 0

    self:Dirty()
end

function CItemCtrl:DispatchTraceNo()
    self:Dirty()
    local iTraceNo = self.m_iTraceNo
    self.m_iTraceNo = self.m_iTraceNo + 1
    return iTraceNo
end

function CItemCtrl:DispatchItemID(oItem)
    local iItemId = self.m_iItemId
    self.m_iItemId = self.m_iItemId + 1
    oItem.m_ID = iItemId
    return iItemId
end

function CItemCtrl:UnDirty()
    super(CItemCtrl).UnDirty(self)
    for _,oContainers in pairs(self.m_mContainer) do
        oContainers:UnDirty()
    end
    for _,oEquip in pairs(self.m_mEquip) do
        oEquip:UnDirty()
    end
end

function CItemCtrl:IsDirty()
    local bDirty = super(CItemCtrl).IsDirty(self)
   if bDirty then
        return true
    end
    for _,oContainers in pairs(self.m_mContainer) do
        if oContainers:IsDirty() then
            return true
        end
    end
    for _,oEquip in pairs(self.m_mEquip) do
        if oEquip:IsDirty() then
            return true
        end
    end
    return false
end

function CItemCtrl:GetPid()
    return self:GetInfo("pid")
end

function CItemCtrl:GetOwner()
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetInfo("pid")
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
    return oPlayer
end

function CItemCtrl:GetContainer(iType)
    return self.m_mContainer[iType]
end

function CItemCtrl:GetItemObj(sid)
    local oItem = loaditem.GetItem(sid)
    local iType = oItem:Type()
    local oContainer = self.m_mContainer[iType]
    assert(oContainer, string.format("item type err: %s, %s", self:GetInfo("pid"), iType))
    return oContainer:GetItemObj(sid)
end

function CItemCtrl:HasItem(itemid)
    for iType, oContainer in pairs(self.m_mContainer) do
        local oItem = oContainer:HasItem(itemid)
        if oItem then
            return oItem
        end
    end
    return nil
end

function CItemCtrl:GiveVirtualItem(lItem, sReason, mArgs)
    local iPid = self:GetInfo("pid")
    lItem = lItem or {}
    local oPlayer = self:GetOwner()
    assert(oPlayer,string.format("itemctrl error:%s,%s", self:GetInfo("pid"), sReason))
    local lRemoteItem = {}
    for _,m in ipairs(lItem) do
        local iSid, iAmount = table.unpack(m)
        local oItem = loaditem.ExtCreate(iSid)
        local iShape = oItem:SID()
        local iAmount = iAmount or 1
        local iValue = oItem:GetData("value", 1) * iAmount
        oItem:SetData("value", iValue)
        if iShape == 1010 then
            oItem:Reward(oPlayer, sReason, mArgs)
        elseif iShape == 1016 then
            oItem:Reward(oPlayer, sReason, mArgs)
        else
            table.insert(lRemoteItem, m)
        end
        if not mArgs.cancel_show then
            local mShowInfo = oItem:GetShowInfo()
            global.oUIMgr:AddKeepItem(iPid, mShowInfo)
        end
    end
    if next(lRemoteItem) then
        oPlayer:SetRemoteItemData({
            cmd = "GiveItem",
            reason = sReason,
            data = lRemoteItem,
            args = mArgs,
            })
    end
end

function CItemCtrl:AddItem(oSrcItem,sReason,mArgs)
    mArgs = mArgs or {}
    self:Dirty()
    local iType = oSrcItem:Type()
    local lItem = {{oSrcItem:SID(), oSrcItem:GetAmount(), oSrcItem:IsBind()}}
    if oSrcItem:ItemType() == "virtual" then
        self:GiveVirtualItem(lItem,sReason, mArgs)
        return
    end
    local iBagLimit = oSrcItem:GetBagLimit()
    if iBagLimit and self:GetItemAmount(oSrcItem:SID()) >= iBagLimit then
        local sOverFlowTips = oSrcItem:GetOverFlowTips()
        oSrcItem.overflow_tips = sOverFlowTips
        return oSrcItem
    end
    local oContainer = self.m_mContainer[iType]
    assert(oContainer, string.format("item type err, pid: %s, type:%s, sid:%s", self:GetInfo("pid"), iType, oSrcItem:SID()))
    return oContainer:AddItem(oSrcItem, sReason, mArgs)
end

function CItemCtrl:RemoveItem(oItem, sReason,bRefresh)
    self:Dirty()
    local iType = oItem:Type()
    local oContainer = self.m_mContainer[iType]
    assert(oContainer, string.format("item type err: %s, %s", self:GetInfo("pid"), iType))
    return oContainer:RemoveItem(oItem, sReason,bRefresh)
end

function CItemCtrl:Arrange()
    self:Dirty()
    for iType, oContainer in pairs(self.m_mContainer) do
        if iType ~= CONTAINER_TYPE.EQUIP then
            oContainer:Arrange()
        end
    end
end

--{{sid, amount}}
function CItemCtrl:ValidRemoveItemList(lItem, mArgs)
    mArgs = mArgs or {}
    local bSucc = true
    for _, m in ipairs(lItem) do
        local iShape,iNeed = table.unpack(m)
        local iHave = self:GetItemAmount(iShape)
        if iHave < iNeed then
            bSucc = false
            break
        end
    end
    if not bSucc and not mArgs.cancel_tip then
        local oAssistMgr = global.oAssistMgr
        oAssistMgr:Notify(self:GetPid(), "物品不足")
    end
    return bSucc
end

--{{sid, amount}}
function CItemCtrl:RemoveItemList(list, sReason, mArgs)
    mArgs = mArgs or {}
    local mShape = {}
    for _, m in ipairs(list) do
        local iShape,iNeed = table.unpack(m)
        mShape[iShape] = self:RemoveItemAmount(iShape,iNeed,sReason,mArgs)
    end
    return mShape
end

function CItemCtrl:RemoveItemAmount(sid, iAmount, sReason, mArgs)
    local oItem = loaditem.GetItem(sid)
    assert(oItem, string.format("item sid err: %s, %s", self:GetInfo("pid"), sid))
    local iType = oItem:Type()
    local oContainer = self.m_mContainer[iType]
    assert(oContainer, string.format("item type err: %s, %s", self:GetInfo("pid"), iType))
    return oContainer:RemoveItemAmount(sid, iAmount, sReason, mArgs)
end

function CItemCtrl:GetItemAmount(sid)
    local oItem = loaditem.GetItem(sid)
    assert(oItem, string.format("item sid err: %s, %s", self:GetInfo("pid"), sid))
    local iType = oItem:Type()
    local oContainer = self.m_mContainer[iType]
    assert(oContainer, string.format("item type err: %s, %s", self:GetInfo("pid"), iType))
    return oContainer:GetItemAmount(sid)
end

function CItemCtrl:AddShapeItem(oItem)
    local iType = oItem:Type()
    local oContainer = self.m_mContainer[iType]
    assert(oContainer, string.format("item type err: %s, %s", self:GetInfo("pid"), iType))
    return oContainer:AddShapeItem(oItem)
end

function CItemCtrl:RemoveShapeItem(oItem)
    local iType = oItem:Type()
    local oContainer = self.m_mContainer[iType]
    assert(oContainer, string.format("item type err: %s, %s", self:GetInfo("pid"), iType))
    return oContainer:RemoveShapeItem(oItem)
end

function CItemCtrl:PackItemShapeAmount()
    local mData = {}
    local mShapeAmount = {}
    local mSpace = {}
    for iType,oContainer in pairs(self.m_mContainer) do
        local mContainerData = oContainer:PackItemShapeAmount()
        mShapeAmount[iType] = mContainerData.shape_amount
        mSpace[iType] = mContainerData.space
    end
    return {
        shape_amount = mShapeAmount,
        space = mSpace
    }
end

--ItemList:{iSid, iAmount, bBind}
function CItemCtrl:ValidGive(ItemList,mArgs)
    mArgs = mArgs or {}
    local bValidGive = true
    local mContainerItem = {}
    local lVirtualItem = {}
    for _, m in ipairs(ItemList) do
        local iItemId, iAmount = table.unpack(m)
        if iAmount <= 0 then
            bValidGive =  false
        end
        local oItem = loaditem.GetItem(iItemId)
        local iType = oItem:Type()
        if oItem:ItemType() == "virtual" then
            table.insert(lVirtualItem, m)
        else
            mContainerItem[iType] = mContainerItem[iType] or {}
            table.insert(mContainerItem[iType], m)
        end
    end
    local oPlayer = self:GetOwner()
    if bValidGive and next(lVirtualItem) then
        if not self:ValidGiveVirtual(oPlayer,lVirtualItem,mArgs) then
            -- global.oNotifyMgr:Notify(oPlayer:GetPid(), "货币已满")
            bValidGive = false
        end
    end
    if bValidGive then
        for iType, lItem in pairs(mContainerItem) do
            local oContainer = self.m_mContainer[iType]
            assert(oContainer, string.format("item type err, pid:%s, type:%s, item;%s", self:GetInfo("pid"), iType, lItem))
            if oContainer:IsSingleItem() then
                bValidGive = oContainer:ValidGiveSingleItem(lItem, mArgs)
            else
                bValidGive = oContainer:ValidGive(lItem, mArgs)
            end
            if not bValidGive then
                break
            end
        end
    end
    return bValidGive
end

function CItemCtrl:ValidGiveVirtual(oPlayer, lItem,mRemoteData)
    lItem = lItem or {}
    local mItem = {}
    local lPartner = {}
    for _, m in ipairs(lItem) do
        local sid, iAmount = table.unpack(m)
        local oItem = loaditem.GetItem(sid)
        local iShape = oItem:SID()
        local iValue = oItem:GetData("value", 1) * iAmount
        if iShape == 1010 then
            table.insert(lPartner, {oItem:GetData("partner"), iValue})
        else
            mItem[iShape] = (mItem[iShape] or 0) + iValue
        end
    end
    local COIN_TYPE = gamedefines.COIN_FLAG
    for iSid, iAmount in pairs(mItem) do
        if iSid == 1002 then
            local iRemoteGold = mRemoteData.gold or 0
            local iSum = iRemoteGold + iAmount
            if not oPlayer:IsOverflowCoin(COIN_TYPE.COIN_COIN,iSum) then
                return false
            end
        elseif iSid == 1003 then
            local iRemoteGoldCoin = mRemoteData.gold_coin or 0
            local iSum = iRemoteGoldCoin + iAmount
            if not oPlayer:IsOverflowCoin(COIN_TYPE.COIN_GOLD,iSum) then
                return false
            end
        elseif iSid == 1014 then
            local iRemoteOrgOffer = mRemoteData.org_offer or 0
            local iSum = iRemoteOrgOffer + iAmount
            if not oPlayer:IsOverflowCoin(COIN_TYPE.COIN_ORG_OFFER, iSum) then
                return false
            end
        elseif iSid == 1017 then
            local iRemoteSkin = mRemoteData.skin or 0
            local iSum = iRemoteSkin + iAmount
            if not oPlayer:IsOverflowCoin(COIN_TYPE.COIN_SKIN, iSum) then
                return false
            end
        end
    end
    return oPlayer:ValidGivePartner(lPartner, mRemoteData)
end

--获取需要发往主world的道具信息
function CItemCtrl:PacketDifferentItem(ItemList)
    local mArgs = mArgs or {}

    local mContainerItem = {}
    local mRemoteItem = {}
    for _, lItem in ipairs(ItemList) do
        local oItem = loaditem.GetItem(lItem[1])
        if oItem:ItemType() == "virtual" then
            table.insert(mRemoteItem,lItem)
        else
            table.insert(mContainerItem, lItem)
        end
    end
    local mData = {
        remote_item = mRemoteItem,
        item = mContainerItem,
    }
    return mData
end

--ItemList:{iSid, iAmount, bBind}
function CItemCtrl:GiveItem(ItemList,sReason,mArgs)
    mArgs = mArgs or {}
    mArgs.cancel_achive = 1
    local cancel_tip = mArgs.cancel_tip
    local cancel_channel = mArgs.cancel_channel

    local mContainerItem = {}
    local lVirtualItem = {}
    for _, lItem in ipairs(ItemList) do
        local iItemId, iAmount = table.unpack(lItem)
        local oItem = loaditem.GetItem(iItemId)
        if oItem:ItemType() == "virtual" then
            table.insert(lVirtualItem,lItem)
        else
            local iType = oItem:Type()
            mContainerItem[iType] = mContainerItem[iType] or {}
            table.insert(mContainerItem[iType],lItem)
        end
    end
    local mData = {  }

    if next(lVirtualItem) then
        mData.virtual = lVirtualItem
        self:GiveVirtualItem(lVirtualItem, sReason, mArgs)
    end
    local lTips = {}
    for iType, lItem in pairs(mContainerItem) do
        local oContainer = self.m_mContainer[iType]
        assert(oContainer, string.format("item type err: %s, %s", self:GetInfo("pid"), iType))
        oContainer:GiveItem(lItem, sReason,mArgs, lTips)
    end
    if #lTips > 0 then
        local sMsg = string.format("获得%s", table.concat(lTips, "，"))
        if not cancel_tip then
            global.oNotifyMgr:Notify(self:GetPid(), sMsg)
        end
        if not cancel_channel then
            global.oChatMgr:HandleMsgChat(self:GetOwner(), sMsg)
        end
    end
    return mData
end

function CItemCtrl:OnLogin(oPlayer,bReEnter)
    local oAssistMgr = global.oAssistMgr
    local oNotifyMgr = global.oNotifyMgr
    local oCbMgr = global.oCbMgr
    self:CheckEquip(oPlayer)
    self:CheckBuffStone(oPlayer, bReEnter)
    self:CalApply(oPlayer, bReEnter)

    local iPage = 200
    local idx = 1
    local lItemData = {}
    for iType, oContainer in pairs(self.m_mContainer) do
        local mList = oContainer:ItemList()
        local lUnValid = {}
        for _, oItem in pairs(mList) do
            if oItem:Validate() then
                table.insert(lItemData, oItem:PackItemInfo())
                if idx % iPage == 0 then
                    oPlayer:Send("GS2CLoginItem",{itemdata = lItemData})
                    lItemData = {}
                end
                idx = idx + 1
            else
                table.insert(lUnValid, oItem)
            end
        end
        for _, oItem in ipairs(lUnValid) do
            local iHave = oItem:GetAmount()
            self:AddAmount(oItem,-iHave,"LoginValidate")
        end
    end
    for iPos, oItem in ipairs(self.m_mEquip) do
        table.insert(lItemData, oItem:PackItemInfo())
        if idx % iPage == 0 then
            oPlayer:Send("GS2CLoginItem",{itemdata = lItemData})
            lItemData = {}
        end
        idx = idx + 1
    end

    local lBuffStone = {}
    for iSid, o in pairs(self.m_mBuffStone) do
        table.insert(lBuffStone, o:PackItemInfo())
    end
    if next(lItemData) or next(lBuffStone) then
        local mNet = {
            itemdata = lItemData,
            buffitem = lBuffStone,
        }
        oPlayer:Send("GS2CLoginItem",mNet)
    end
    self:GS2CFuWenPlanName()
    self:ShareUpdate()
    oPlayer.m_oEquipMgr:ShareUpdate()
    oPlayer.m_oStoneMgr:ShareUpdate()

    local iPid = oPlayer:GetPid()
    for _, sMsg in ipairs(self.m_BuffMgs or {}) do
        oAssistMgr:BroadCastNotify(iPid, nil, sMsg)
    end
    self.m_BuffMgs = nil
end

function CItemCtrl:PackRemoteItemData()
    local mShape = {}
    for iType, oContainer in pairs(self.m_mContainer) do
        local mList = oContainer:ItemList()
        for _, oItem in pairs(mList) do
            local iShape = oItem:SID()
            if not mShape[iShape] then
                mShape[iShape] = 0
            end
            mShape[iShape] = mShape[iShape] + oItem:GetAmount()
        end
    end
    return mShape
end

function CItemCtrl:PackRemoteData()
    local mShape = self:PackRemoteItemData()
    return {
        shape = mShape,
    }
end

function CItemCtrl:OnLogout(oPlayer)
end

function CItemCtrl:OnDisconnected(oPlayer)
end

function CItemCtrl:CalApply(oPlayer,bReEnter)
    if not bReEnter then
        for iPos, oItem in pairs(self.m_mEquip) do
            if not (iPos == itemdefines.EQUIP_BACK_WEAPON) and not oItem:IsWield() then
                oItem:Wield(oPlayer)
            end
        end
        for iSid, oBuffStone in pairs(self.m_mBuffStone) do
            if not oBuffStone:IsWield() then
                oBuffStone:WieldStone(oPlayer)
            end
        end
    end
end

function CItemCtrl:GetEquipList()
    return self.m_mEquip
end

function CItemCtrl:GetEquip(iPos)
    return self.m_mEquip[iPos]
end

function CItemCtrl:GetEquipByID(iEquip)
    for iPos, oEquip in pairs(self.m_mEquip) do
        if oEquip:ID() == iEquip then
            return oEquip
        end
    end
end

function CItemCtrl:AddSecondWeapon(oEquip)
    self:Dirty()
    local iSecondPos = itemdefines.EQUIP_BACK_WEAPON
    oEquip.m_iPos = iSecondPos
    if not oEquip:GetData("TraceNo") then
        local iTraceNo = self:DispatchTraceNo()
        oEquip:SetData("TraceNo",{self:GetInfo("pid"), iTraceNo})
    end
    self:DispatchItemID(oEquip)
    self.m_mEquip[iSecondPos] = oEquip
    oEquip:Refresh()
end

function CItemCtrl:SwitchWeapon(oPlayer)
    self:Dirty()
    local iPos = itemdefines.EQUIP_WEAPON
    local iSecondPos = itemdefines.EQUIP_BACK_WEAPON
    local oWeapon = self.m_mEquip[iPos]
    local oSecondWeapon = self.m_mEquip[iSecondPos]
    oWeapon:UnWield(oPlayer)
    oWeapon.m_iPos = iSecondPos
    oWeapon:BackUp(oSecondWeapon)
    oSecondWeapon:Wield(oPlayer)
    oSecondWeapon.m_iPos = iPos
    self.m_mEquip[iPos] = oSecondWeapon
    self.m_mEquip[iSecondPos] = oWeapon
    oSecondWeapon:Refresh()
    oWeapon:Refresh()
    --oPlayer:ChangeWeapon()
end

function CItemCtrl:WieldEquip(iPos,oNewEquip)
    self:Dirty()
    local oEquip = self.m_mEquip[iPos]
    if not oNewEquip:GetData("TraceNo") then
        oNewEquip:SetData("TraceNo", {self:GetPid(), self:DispatchTraceNo()})
    end
    self.m_mEquip[iPos] = oNewEquip
end

function CItemCtrl:WieldBuffStone(oNew)
    self:Dirty()
    self:DelTimeCb(tostring(iSid))

    local iPid = self:GetPid()
    local iSid = oNew:SID()
    local oBuffStone = self:HasBuffStone(iSid)
    if oBuffStone then
        self:UnWieldBuffStone(iSid)
    end
    self.m_mBuffStone[iSid] = oNew
end

function CItemCtrl:StartBuffStoneTimer(iSid)
    local oBuffStone = self:HasBuffStone(iSid)
    if not oBuffStone then
        return
    end
    local iPid = self:GetPid()
    local iSid = oBuffStone:SID()
    local iSec = oBuffStone:EndTime() - get_time()
    if iSec > 0 then
        self:DelTimeCb(tostring(iSid))
        self:AddTimeCb(tostring(iSid), iSec * 1000, function()
            local oPlayer = global.oAssistMgr:GetPlayer(iPid)
            if oPlayer then
                oPlayer.m_oItemCtrl:BuffStoneTimeOut(iSid)
            end
        end)
    else
        self:UnWieldBuffStone(iSid)
    end
end

function CItemCtrl:BuffStoneTimeOut(iSid,mArgs)
    mArgs = mArgs or {}
    self:UnWieldBuffStone(iSid)

    local oBuffStone = loaditem.GetItem(iSid)
    local sMsg = string.format("%s的效果消失了", oBuffStone:Name())
    if not mArgs.cancel_tip then
        global.oAssistMgr:BroadCastNotify(self:GetPid(),nil, sMsg)
    else
        self.m_BuffMgs = self.m_BuffMgs or {}
        table.insert(self.m_BuffMgs, sMsg)
    end
end

function CItemCtrl:UnWieldBuffStone(iSid)
    local oBuffStone = self:HasBuffStone(iSid)
    if not oBuffStone then
        return
    end
    self:DelTimeCb(tostring(iSid))
    local oPlayer = self:GetOwner()
    oBuffStone:UnWieldStone(oPlayer)
    self.m_mBuffStone[iSid] = nil
    oPlayer:Send("GS2CRemoveBuffItem", {itemid=oBuffStone:ID()})
    oPlayer.m_oStoneMgr:ShareUpdate()
    oPlayer:SynShareObj({stone_share = 1})
    baseobj_delay_release(oBuffStone)
end

function CItemCtrl:HasBuffStone(iSid)
    return self.m_mBuffStone[iSid]
end

--test
function CItemCtrl:ClearEquip()
    self:Dirty()
    self.m_mEquip = {}
end

function CItemCtrl:InitEquip(oPlayer)
    self:CheckEquip(oPlayer)
    -- self:SetFuWenName(1, "方案1")
end

function CItemCtrl:CheckBuffStone(oPlayer, bReEnter)
    if not  bReEnter then
        for iSid, oBuffStone in pairs(self.m_mBuffStone) do
            if oBuffStone:IsTimeOut() then
                self:BuffStoneTimeOut(iSid, {cancel_tip = 1})
            else
                self:StartBuffStoneTimer(iSid)
            end
        end
    end
end

function CItemCtrl:CheckEquip(oPlayer)
    local iSchool = oPlayer:GetSchool()
    local iPid = oPlayer.m_iPid
    local mData = self:GetBornEquip(iSchool)
    for iPos = itemdefines.EQUIP_WEAPON, itemdefines.EQUIP_SHOE do
        local oEquip = self.m_mEquip[iPos]
        if not oEquip then
            local iShape
            for _,mShape in pairs(mData) do
                local iSid = mShape["sid"]
                local iWieldPos = mShape["pos"]
                if iPos == iWieldPos then
                    iShape = iSid
                end
            end
            if not iShape then
                iShape = itemdefines.GetEquipShape(oPlayer,iPos,0)
            end
            assert(iShape,string.format("newrole equip err:%s %s %s",iPid,iSchool,iPos))
            self:Dirty()
            local oEquip = self:MakeNewRoleEquip(iShape,iPos)
            local iLevel = 0
            local iQuality = 1
            local iWeapon = oEquip:WeaponType()
            local iStoneShape = itemdefines.GetEquipStoneShape(oPlayer, iPos, iLevel, iQuality, iWeapon)
            local oEquipStone = loaditem.Create(iStoneShape)
            local mApply = oEquipStone:PackApplyData(oPlayer:GetSchool())
            oEquip:UseEquipStone(mApply)
            oEquip:SetItemLevel(iQuality)
            oEquip:SetName(mApply["name"])
            oEquip:Wield(oPlayer)
            oEquip.m_iPos = iPos
            self.m_mEquip[iPos] = oEquip
            if not oEquip:GetData("TraceNo") then
                local iTraceNo = self:DispatchTraceNo()
                oEquip:SetData("TraceNo",{self:GetInfo("pid"), iTraceNo})
            end
            self:DispatchItemID(oEquip)
            if iPos == itemdefines.EQUIP_WEAPON then
                oPlayer:ChangeWeapon()
            end
        end
    end
    if oPlayer:GetGrade() >= global.oAssistMgr:QueryControl("switchschool", "open_grade") then
        local iSecondPos = itemdefines.EQUIP_BACK_WEAPON
        local oSecondWeapon = self.m_mEquip[iSecondPos]
        if not oSecondWeapon then
            self:GiveSecondEquip(oPlayer)
        end
    end
end

function CItemCtrl:GetNewRoleEquipData(iPos)
    local res = require "base.res"
    local mData = res["daobiao"]["newrole_equip"][iPos]
    assert(mData,string.format("newrole_equip err:%d",iPos))
    return mData
end

function CItemCtrl:GetSecondWeaponData(iPos)
    local res = require "base.res"
    local mData = res["daobiao"]["second_weapon"][iPos]
    assert(mData,string.format("second_equip err:%d",iPos))
    return mData
end

function CItemCtrl:GetBornEquip(iSchool)
    local res = require "base.res"
    local mData = res["daobiao"]["school_equip"][iSchool]
    assert(mData,string.format("born school equip err:%d",iSchool))
    return mData["sid_list"]
end

function CItemCtrl:GetSecondWeapon(iSchool)
    local res = require "base.res"
    local mData = res["daobiao"]["school_equip"][iSchool]
    assert(mData,string.format("born school equip err:%d",iSchool))
    return mData["back_list"]
end

function CItemCtrl:MakeNewRoleEquip(iShape,iPos)
    local oEquip = loaditem.Create(iShape)
    oEquip:ResetApply()
    return oEquip
end

function CItemCtrl:GiveSecondEquip(oPlayer)
    local iSchool = oPlayer:GetSchool()
    local mShape = self:GetSecondWeapon(iSchool)
    for _,m in pairs(mShape) do
        local oEquip = loaditem.Create(m.sid)
        if oEquip:ItemType() ~= "equip" then
            return
        end
        oEquip:ResetApply()
        local iPos = itemdefines.EQUIP_WEAPON
        local oOldEquip = self:GetEquip(iPos)
        local iLevel = oEquip:EquipLevel()
        local iQuality = m.quality or 1
        local iWeapon = oEquip:WeaponType()
        local iStoneShape = itemdefines.GetEquipStoneShape(oPlayer, iPos, iLevel, iQuality, iWeapon)
        local oEquipStone = loaditem.Create(iStoneShape)
        local mApply = oEquipStone:PackApplyData(oPlayer:GetSchool())
        oEquip:UseEquipStone(mApply)
        oEquip:SetItemLevel(iQuality)
        self:AddSecondWeapon(oEquip)
        local mLog = {
            pid = oPlayer:GetPid(),
            grade = oPlayer:GetGrade(),
            pos = itemdefines.EQUIP_BACK_WEAPON,
            trace = oEquip:TraceNo(),
            sid = oEquip:SID(),
        }
        record.user("equip", "second_equip", mLog)
        break
    end
end

function CItemCtrl:OpenFuWenPlan(oPlayer, iPlan)
    local sReason = string.format("开启淬灵方案％s", iPlan)
    for iPos = itemdefines.EQUIP_WEAPON, itemdefines.EQUIP_SHOE do
        local oEquip = self:GetEquip(iPos)
        if oEquip then
            local mData = self:GetNewRoleEquipData(iPos)
            local sFuWen = mData["fuwen"]
            local mPlan = {}
            local mAttr = formula_string(sFuWen,{})
            local mFuWen = {}
            for sAttr, iValue in pairs(mAttr) do
                mFuWen[sAttr] = {value = iValue, quality = 1}
            end
            mPlan["fuwen"] = mFuWen
            mPlan["level"] = oEquip:EquipLevel()
            oEquip:AddFuWenPlan(iPlan, mPlan)
            if iPlan == 1 then
                oEquip:UseFuWenPlan(oPlayer, iPlan, sReason)
            end
            oEquip:SendFuWen(oPlayer)
            self:GS2CFuWenPlanName()
            local mLog = {
                pid = oPlayer:GetPid(),
                pos = oEquip:EquipPos(),
                plan = iPlan,
                fuwen = ConvertTblToStr(mPlan),
                reason = sReason,
            }
            record.user("equip", "add_fuwen_plan", mLog)
        end
    end
end

function CItemCtrl:OpenSecondFuwen(oPlayer)
    for iPos = itemdefines.EQUIP_WEAPON, itemdefines.EQUIP_SHOE do
        local oEquip = self:GetEquip(iPos)
        if oEquip then
            local mData = self:GetNewRoleEquipData(iPos)
            local sFuWen = mData["fuwen"]
            local iPlan = 2
            local mPlan = {}
            local mAttr = formula_string(sFuWen,{})
            local mFuWen = {}
            for sAttr, iValue in pairs(mAttr) do
                mFuWen[sAttr] = {value = iValue, quality = 1}
            end
            mPlan["fuwen"] = mFuWen
            mPlan["level"] = oEquip:EquipLevel()
            oEquip:AddFuWenPlan(iPlan, mPlan)
            oEquip:SendFuWen(oPlayer)
            self:GS2CFuWenPlanName()
            local mLog = {
                pid = oPlayer:GetPid(),
                pos = oEquip:EquipPos(),
                plan = iPlan,
                fuwen = ConvertTblToStr(mPlan),
                reason = "第二套淬灵方案",
            }
            record.user("equip", "add_fuwen_plan", mLog)
        end
    end
end

function CItemCtrl:PromoteEquipLevel(oPlayer,iPos,oEquipStone)
    local oEquip = self:GetEquip(iPos)
    local iNowLevel = oEquip:EquipLevel()
    local oOldEquipStone = oEquip:CreateEquipStone()
    local iNewLevel = oEquipStone:Level()
    local iQuality = oEquipStone:Quality()
    local iEquipLock = oEquip:GetData("lock", 0)
    local iStoneLock = oEquipStone:GetData("lock", 0)

    local iNewShape = oEquip:SID() + (iNewLevel-iNowLevel) * 10
    local mArgs = {
        item_level = iQuality,
    }
    local mApply = oEquipStone:PackApplyData(oPlayer:GetSchool())
    local mTraceNo = oEquipStone:GetData("TraceNo")
    oPlayer.m_oItemCtrl:AddAmount(oEquipStone,-1,"装备强化")
    oEquip:UnWield(oPlayer)
    local oNewEquip = loaditem.Create(iNewShape,mArgs)
    self:DispatchItemID(oNewEquip)
    oNewEquip:SetData("TraceNo", mTraceNo)
    oNewEquip:UseEquipStone(mApply)
    oEquip:BackUp(oNewEquip)
    oNewEquip:Wield(oPlayer)
    self:WieldEquip(iPos,oNewEquip)

    oNewEquip:SetData("lock", iStoneLock)
    oNewEquip:Refresh()
    if itemdefines.EQUIP_WEAPON == 1 then
        oPlayer:ChangeWeapon()
    end

    --旧石头处理
    if oOldEquipStone then
        oOldEquipStone:SetData("lock", iEquipLock)
        oOldEquipStone:SetData("TraceNo", oEquip:GetData("TraceNo"))
        oPlayer:RewardItem(oOldEquipStone,"装备替换", {cancel_tip=1, cancel_channel = 1})
    end
    local iLevel
    for iPos, oEquip in pairs(self.m_mEquip) do
        iLevel = math.min(iLevel or oEquip:EquipLevel(), oEquip:EquipLevel())
    end
    if iLevel then
        if iLevel >= 30 then
            global.oAssistMgr:PushAchieve(oPlayer:GetPid(), "穿齐30级装备", {value = 1})
        end
    end
end

--获取穿戴
function CItemCtrl:GetWieldEquipSkill()
    local mSE = {}
    local mSetSkill = {}
    for iPos, oEquip in pairs(self.m_mEquip) do
        if iPos ~= itemdefines.EQUIP_BACK_WEAPON then
            local mSk = oEquip:GetSE()
            for iSk, oSk in pairs(mSk) do
                mSE[iSk] = oSk:Level()
            end
            local iSetType = oEquip:SetType()
            mSetSkill[iSetType] = mSetSkill[iSetType] or {}
            table.insert(mSetSkill[iSetType], oEquip:SkillLevel())
        end
    end

    --套装
    local mSetData = res["daobiao"]["equip_set"]
    for iType, l in pairs(mSetSkill) do
        local m = mSetData[iType]
        if m and #m.pos_list == #l then
            mSE[m.skill] = extend.Array.min(l)
        end
    end
    return mSE
end

function CItemCtrl:GetLevelGem(iPos)
    local iType = CONTAINER_TYPE.GEM
    local oContainer = self.m_mContainer[iType]
    local mItemList = oContainer:ItemList()
    local mGem = {}
    for iItemid,oGem in pairs(mItemList) do
        local iWieldPos = oGem:WieldPos()
        local iLevel = oGem:Level()
        if iWieldPos == iPos then
            if not mGem[iLevel] then
                mGem[iLevel] = {}
            end
            table.insert(mGem[iLevel],iItemid)
        end
    end
    return mGem
end

function CItemCtrl:GetMinLevelGem(iPos)
    local mLevelGem = self:GetLevelGem(iPos)
    local iMinLevel = 1000
    for iLevel,mItem in pairs(mLevelGem) do
        if iMinLevel > iLevel then
            iMinLevel = iLevel
        end
    end
    local mItem = mLevelGem[iMinLevel]
    if not mItem then
        return
    end
    local iItemid = mItem[math.random(#mItem)]
    local oGem = self:HasItem(iItemid)
    return oGem
end

function CItemCtrl:GetMaxLevelGem(iPos)
    local iType = CONTAINER_TYPE.GEM
    local oContainer = self.m_mContainer[iType]
    local lGems = oContainer:ItemList()
    local oGem
    for iGemId, o in pairs(lGems) do
        if iPos == o:WieldPos() then
            oGem = oGem or o
            if oGem:Level() < o:Level() then
                oGem = o
            end
        end
    end
    return oGem
end

function CItemCtrl:GetWieldEquipPower()
    local iPower = 0
    local mSetSkill = {}
    for iPos, oEquip in pairs(self.m_mEquip) do
        if iPos ~= itemdefines.EQUIP_BACK_WEAPON then
            iPower = iPower + oEquip:SEPower()

            local iSetType = oEquip:SetType()
            mSetSkill[iSetType] = mSetSkill[iSetType] or {}
            table.insert(mSetSkill[iSetType], oEquip:SkillLevel())
        end
    end

    --套装技能
    local mSetData = res["daobiao"]["equip_set"]
    for iType, l in pairs(mSetSkill) do
        local m = mSetData[iType]
        if m and #m.pos_list == #l then
            iPower = iPower + formula_string(m.power, {lv = extend.Array.min(l)})
        end
    end

    return iPower
end

function CItemCtrl:GS2CAddItem(oItem)
    local mArgs = mArgs or {}
    local mNet = {}
    local itemdata = oItem:PackItemInfo()
    mNet["itemdata"] = itemdata
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:Send("GS2CAddItem",mNet)
    end
end

function CItemCtrl:GS2CDelItem(oItem)
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:Send("GS2CDelItem",{
            id = oItem.m_ID,
            })
    end
end

function CItemCtrl:ValidItemUse(iItemid)
    local oItem = self:HasItem(iItemid)
    if not oItem then
        return false
    end
    if oItem:IsTimeOut() then
        local iHave = oItem:GetAmount()
        self:AddAmount(oItem,-iHave,"timeout")
        return false
    end
    return true
end

function CItemCtrl:ItemUse(iItemid,iTarget,iAmount, mArgs)
    iAmount = iAmount or 1
    local oAssistMgr = global.oAssistMgr
    if not self:ValidItemUse(iItemid) then
        return
    end
    local oItem = self:HasItem(iItemid)
    local iPid = self:GetInfo("pid")
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
    oItem:Use(oPlayer,iTarget, iAmount or 1, mArgs)
end

function CItemCtrl:ItemInfo(iItemid)
    local iPid = self:GetInfo("pid")
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local oItem = oPlayer.m_oItemCtrl:HasItem(iItemId)
    if not oItem then
        return
    end
    oItem:Refresh()
end

function CItemCtrl:AddAmount(oItem,iAmount,sReason,mArgs,bRefresh)
    local iType = oItem:Type()
    mArgs = mArgs or {}
    local oContainer = self.m_mContainer[iType]
    oContainer:AddAmount(oItem,iAmount,sReason,mArgs,bRefresh)
end

function CItemCtrl:ItemCount(iType)
    local oContainer = self.m_mContainer[iType]
    return oContainer:ItemCount()
end

function CItemCtrl:GetFuWenName(iPlan)
    local sName = self.m_mFuWenName[iPlan]
    if not sName then
        self:Dirty()
        if iPlan == 1 then
            sName = "默认方案"
        elseif iPlan == 2 then
            sName = "备选方案"
        else
            sName = string.format("方案%s", iPlan)
        end
        self:SetFuWenName(iPlan, sName)
    end
    return sName
end

function CItemCtrl:SetFuWenName(iPlan, sName)
    self:Dirty()
    if sName and sName ~= "" then
        self.m_mFuWenName[iPlan] = sName
    end
end

function CItemCtrl:GS2CFuWenPlanName()
    local oPlayer = self:GetOwner()
    if oPlayer then
        local oEquip = self:GetEquip(1)
        local mPlan = oEquip.m_mFuwenPlan
        local lNet = {}
        for iPlan, m in pairs(mPlan) do
            table.insert(lNet, {
                plan = iPlan,
                name = self:GetFuWenName(iPlan),
                })
        end
        oPlayer:Send("GS2CFuWenPlanName", {fuwen_name = lNet})
    end
end

function CItemCtrl:ValidComposePartnerEquip(lCost)
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local sTip = "熔炼失败，符文信息已更改"
    if #lCost ~= 2 then
        oAssistMgr:Notify(iPid, "参数有误")
        return false
    end
    local iWieldCount = 0
    local lItem = {}
    for _, iItemId in pairs(lCost) do
        local oItem = self:HasItem(iItemId)
        if not oItem then
            oAssistMgr:Notify(iPid,sTip)
            return false
        end
        if oItem:Type() ~= CONTAINER_TYPE.PARTNER_EQUIP then
            oAssistMgr:Notify(iPid, "非伙伴符文")
            return false
        end
        if oItem:IsExpEquip() then
            oAssistMgr:Notify(iPid, "经验符文不可合成")
            return false
        end
        if oItem:IsWield() then
            iWieldCount = iWieldCount + 1
        elseif oItem:IsLock() then
            oAssistMgr:Notify(iPid, "已上锁符文无法熔炼")
            return false
        end
        if iWieldCount == 2 then
            oAssistMgr:Notify(iPid, "已穿戴符文无法熔炼")
            return false
        end
        table.insert(lItem, oItem)
    end
    if lItem[1]:EquipPos() ~= lItem[2]:EquipPos() then
        oAssistMgr:Notify(iPid, "熔炼需要相同位置")
        return false
    end
    return true
end

function CItemCtrl:ComposePartnerEquip(iEquip1, iEquip2)
end

function CItemCtrl:DoComposePartnerEquip(m, iEquip1, iEquip2, iStar)
end

function CItemCtrl:ValidStrengthPartnerEquip(iItemId, mCostItem)
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local oItem = self:HasItem(iItemId)
    if not oItem then
        record.info(string.format("partner equip not exist, pid:%s,itemid:%s", iPid, iItemId))
        oAssistMgr:Notify(iPid, "符文不存在")
        return false
    end
    if not next(mCostItem) then
        record.info(string.format("partner equip costlist nil, pid:%s,itemid:%s", iPid, iItemId))
        oAssistMgr:Notify(iPid, "强化失败，消耗列表为空")
        return false
    end
    if oItem:Type() ~= CONTAINER_TYPE.PARTNER_EQUIP then
        record.info(string.format("not partner equip, pid:%s,itemid:%s,traceno:%s", iPid,iItemId,oItem:TraceNo()))
        oAssistMgr:Notify(iPid, "非伙伴符文")
        return false
    end
    if oItem:IsExpEquip() then
        oAssistMgr:Notify(iPid, "经验符文不可强化")
        return false
    end
    if oItem:IsMaxLevel() then
        oAssistMgr:Notify(iPid, "已达等级上限")
        return false
    end
    for iItemId, iAmount in pairs(mCostItem) do
        local oItem = self:HasItem(iItemId)
        if not oItem then
            record.info(string.format("cost partner equip not exist, pid:%s,itemid:%s", iPid, iItemId))
            -- oAssistMgr:Notify(iPid, "消耗的符文不存在")
            return false
        end
        if oItem:Type() ~= CONTAINER_TYPE.PARTNER_EQUIP then
            record.info(string.format("not partner equip, pid:%s,itemid:%s,traceno:%s", iPid, iItemId,oItem:TraceNo()))
            -- oAssistMgr:Notify(iPid, "消耗非伙伴符文")
            return false
        end
        if oItem:IsWield() then
            record.info(string.format("partner equip wielded, pid:%s,itemid:%s,traceno:%s", iPid, iItemId, oItem:TraceNo()))
            oAssistMgr:Notify(iPid, "穿戴不可消耗")
            return false
        end
        if oItem:IsLock() then
            record.info(string.format("partner equip locked, pid:%s,itemid:%s,traceno:%s", iPid, iItemId, oItem:TraceNo()))
            oAssistMgr:Notify(iPid, "消耗符文已上锁")
            return false
        end
        if oItem:GetAmount() < iAmount then
            record.info(string.format("partner equip locked, pid:%s,itemid:%s,traceno:%s", iPid, iItemId, oItem:TraceNo()))
            oAssistMgr:Notify(iPid, "符文数量不足")
            return false
        end
    end

    return true
end

function CItemCtrl:GetUpGradeCost(mCostItem)
    local iCostCoin = 0
    mCostItem = mCostItem or {}
    for iItemId, iAmount in pairs(mCostItem) do
        local oItem = self:HasItem(iItemId)
        if oItem then
            iCostCoin = iCostCoin + (oItem:GetUpGradeCost() * iAmount)
        end
    end
    return iCostCoin
end

function CItemCtrl:ValidWearPartnerEquips(iParId, lWear)
    local oPlayer = self:GetOwner()
    if not oPlayer then
        record.warning("ValidWearPartnerEquips, pid:%s, not exist!", self:GetPid())
        return false
    end
    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
    if not oPartner then
        record.warning("ValidWearPartnerEquips, parid:%s, not exist!", iParId)
        return false
    end
    if #lWear <= 0 or #lWear > 4 then
        record.warning("ValidWearPartnerEquips, param:%s, error!", #lWear)
        return false
    end
    for _, iItemId in ipairs(lWear) do
        local oItem = self:HasItem(iItemId)
        if not oItem then
            return false
        end
        if oItem:Type() ~= CONTAINER_TYPE.PARTNER_EQUIP then
            return false
        end
        if oItem:IsWield() then
            return false
        end
    end
    return true
end

function CItemCtrl:WearPartnerEquips(iParId,lWear)
    local mArgs = {}
    mArgs["cancel_tip"] = 1
    mArgs["cancel_channel"] = 1
    mArgs["cancel_show"] = 1
    for _, iItemId in ipairs(lWear) do
        self:ItemUse(iItemId, iParId, 1, mArgs)
    end
end

function CItemCtrl:StrengthBuffStone(oPlayer, oItem)
    self:Dirty()
    local oAssistMgr = global.oAssistMgr
    local iSid = oItem:SID()
    local oBuffStone = self:HasBuffStone(iSid)
    if not oBuffStone then
        return
    end
    if oBuffStone:IsStrength() then
        oAssistMgr:Notify(self:GetPid(), "该部位的神格已经加强过了")
        return
    end
    local sReason = "强化神格道具"
    self:AddAmount(oItem, -1, sReason, {cancel_show = 1}, true)
    oBuffStone:Strength(oPlayer)
    oPlayer.m_oStoneMgr:ShareUpdate()
    oPlayer:Send("GS2CUpdateBuffItem", {itemdata = oBuffStone:PackItemInfo()})
    oPlayer:SynShareObj({stone_share = 1})
    global.oAssistMgr:PushAchieve(oPlayer:GetPid(), "使用神格次数", {value = 1})
end

function CItemCtrl:CountGemLevel(iPos)
    local iCount = 0
    local oEquip = self:GetEquip(iPos)
    if oEquip then
        iCount = iCount + oEquip:CountGemLevel()
    else
        for iPos, oEquip in pairs(self.m_mEquip) do
            iCount = iCount + oEquip:CountGemLevel()
        end
    end
    return iCount
end

function CItemCtrl:MaxHistoryGemLv()
    return self.m_iMaxOldGemLv
end

function CItemCtrl:SetMaxHistoryGemLv(iLevel)
    self:Dirty()
    self.m_iMaxOldGemLv = iLevel
end

function CItemCtrl:CoverBuffStone(oPlayer, oItem)
    self:Dirty()
    local oAssistMgr = global.oAssistMgr
    local iSid = oItem:SID()
    local oBuffStone = self:HasBuffStone(iSid)
    if not oBuffStone then
        return
    end

    local iPid = oPlayer:GetPid()
    local sFunc = tostring(iSid)
    self:DelTimeCb(sFunc)
    local sReason = "覆盖神格道具"
    self:AddAmount(oItem, -1, sReason, {cancel_show = 1}, true)
    oBuffStone:ResetEndTime()
    local iSec = oBuffStone:EndTime() - get_time()
    if iSec > 0 then
        self:AddTimeCb(sFunc, iSec * 1000, function()
            local oPlayer = oAssistMgr:GetPlayer(iPid)
            if oPlayer then
                oPlayer.m_oItemCtrl:UnWieldBuffStone(iSid)
            end
        end)
    else
        self:UnWieldBuffStone(iSid)
    end
    oPlayer:Send("GS2CUpdateBuffItem", {itemdata = oBuffStone:PackItemInfo()})
    global.oAssistMgr:PushAchieve(iPid, "使用神格次数", {value = 1})
end


function CItemCtrl:BuyPartnerBaseEquip(iShape, iParId)
    local mData = {}
    local oItem = loaditem.GetItem(iShape)
    mData.pid = self:GetPid()
    mData.coin = oItem:BuyPrice()
    mData.reason = "购买伙伴符文"
    interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
        local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
        if oPlayer then
            oPlayer.m_oItemCtrl:DoBuyPartnerBaseEquip(oPlayer, m, iShape, iParId)
        end
    end)
end

function CItemCtrl:DoBuyPartnerBaseEquip(oPlayer, m, iShape, iParId)
    local bFlag = false
    if m.success then
        if self:ValidGive({{iShape, 1}}) then
            bFlag = true
            local oParEquip = loaditem.ExtCreate(iShape)
            local iItemId = self:DispatchItemID(oParEquip)
            self:AddItem(oParEquip, m.reason, {cancel_tip = 1, cancel_show = 1})
            self:ItemUse(iItemId, iParId, 1)
            -- self:GiveItem({{iShape, 1}}, m.reason, {cancel_tip = 1, cancel_show = 1})
        end
    end
    oPlayer:DoResultMoney(bFlag, m)
end

function CItemCtrl:StrengthPartnerEquip(iItemId, iNewShape, mData, mCostItem, iOneKey)
    interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
        local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
        if oPlayer then
            oPlayer.m_oItemCtrl:DoStrengthPartnerEquip(oPlayer, m, iItemId, iNewShape, mCostItem, iOneKey)
        end
    end)
end

function CItemCtrl:DoStrengthPartnerEquip(oPlayer, m, iItemId, iNewShape, mCostItem, iOneKey)
    local oParEquip = self:HasItem(iItemId)
    local bFlag = false
    if oParEquip then
        if m.success then
            bFlag = true
            for iSid, iAmount in pairs(mCostItem) do
                if self:GetItemAmount(iSid) < iAmount then
                    bFlag = false
                    break
                end
            end
            if bFlag then
                for iSid, iAmount in pairs(mCostItem) do
                    self:RemoveItemAmount(iSid, iAmount, m.reason)
                end
                local iOldLv = oParEquip:EquipLevel()
                self:RemoveShapeItem(oParEquip)
                oParEquip:OnStrength(oPlayer, iNewShape)
                self:AddShapeItem(oParEquip)

                local iPid = oPlayer:GetPid()
                if iOneKey == 1 then
                    global.oAssistMgr:BroadCastNotify(oPlayer:GetPid(), nil, "一键强化完毕")
                end
                local iNewLv = oParEquip:EquipLevel()
                if iOldLv < 3 and iNewLv >= 3 then
                    global.oAssistMgr:PushAchieve(iPid, "3级符文", {value = 1})
                end
            end
        end
    end
    oPlayer:DoResultMoney(bFlag, m)
end

function CItemCtrl:UpstarPartnerEquip(iItemId, mData)
    interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
        local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
        if oPlayer then
            oPlayer.m_oItemCtrl:DoUpstarPartnerEquip(oPlayer, m, iItemId)
        end
    end)
end

function CItemCtrl:DoUpstarPartnerEquip(oPlayer, m, iItemId)
    local bFlag = false
    local oParEquip = self:HasItem(iItemId)
    if oParEquip then
        if m.success then
            local mCostItem = oParEquip:UpstarItem()
            if self:RemoveItemAmount(mCostItem.sid, mCostItem.amount, m.reason, {}) then
                bFlag = true
                local iLevel = 1
                local iStar = oParEquip:Star() + 1
                local iPos = oParEquip:EquipPos()
                local iNewShape = itemdefines.GetPartnerEquipShape(iPos, iStar, iLevel)
                self:RemoveShapeItem(oParEquip)
                oParEquip:OnUpstar(oPlayer, iNewShape)
                self:AddShapeItem(oParEquip)
                local iStar = oParEquip:Star()
                if iStar >= 2 then
                    local sText =  string.format("%s星符文个数", iStar)
                    global.oAssistMgr:PushAchieve(self:GetPid(),sText, {value = 1})
                end
            end
        end
    end
    oPlayer:DoResultMoney(bFlag, m)
end

function CItemCtrl:ValidComposeEquip(oPlayer, iPos, iLevel)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    local mComData = itemdefines.GetComposeEquipData(iPos, iLevel)
    if not mComData then
        return false
    end
    local mCostItem = mComData.sid_item_list or {}
    for _, m in pairs(mCostItem) do
        if self:GetItemAmount(m.sid) < m.amount then
            oAssistMgr:BroadCastNotify(iPid, nil, "材料不足")
            return false
        end
    end
    return true
end

function CItemCtrl:ComposeEquip(oPlayer, iPos, iLevel)
    if not self:ValidComposeEquip(oPlayer, iPos, iLevel) then
        return
    end
    local mComData = itemdefines.GetComposeEquipData(iPos, iLevel)
    if mComData.cost > 0 then
        local mData = {}
        mData.pid = self:GetPid()
        mData.coin = mComData.cost
        mData.reason = "人物装备合成"
        -- mData.args = {cancel_tip = 1}
        interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
            local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
            if oPlayer then
                oPlayer.m_oItemCtrl:DoComposeEquip(oPlayer, m, iPos, iLevel)
            end
        end)
    end
end

function CItemCtrl:DoComposeEquip(oPlayer, m, iPos, iLevel)
    local bFlag = false
    if m.success then
        if self:ValidComposeEquip(oPlayer, iPos, iLevel) then
            bFlag = true
            local mComData = itemdefines.GetComposeEquipData(iPos, iLevel)
            local mCostItem = mComData.sid_item_list or {}
            for _, mItem in pairs(mCostItem) do
                self:RemoveItemAmount(mItem.sid, mItem.amount, m.reason, {cancel_tip = 1})
            end
            local iItemSid = self:RandomGiveEquip(oPlayer, mComData.compose_item)
            if iItemSid then
                self:GiveItem({{iItemSid, 1}}, m.reason, {cancel_tip = 1, cancel_channel = 1})
                global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
                local args = {
                    {"&role&", oPlayer:GetName()},
                    {"&item&", loaditem.ItemColorName(iItemSid)},
                }
                local sMsg= global.oAssistMgr:GetChuanWenTextData(10008, args)
                global.oNotifyMgr:SendSysChat(sMsg , 1, 1)
            end
        end
    end
    oPlayer:DoResultMoney(bFlag, m)
end

function CItemCtrl:RandomGiveEquip(oPlayer, lGive)
    local lFilter = {}
    for _, m in ipairs(lGive) do
        local oItem = loaditem.GetItem(m.sid)
        if oItem:WieldPos() == itemdefines.EQUIP_WEAPON then
            if oPlayer:ValidSchoolWeapon(oItem:WeaponType()) then
                table.insert(lFilter, table_deep_copy(m))
            end
        elseif oItem:Sex() == gamedefines.EQUIP_SEX_TYPE.COMMON then
            table.insert(lFilter, table_deep_copy(m))
        elseif oItem:Sex() == oPlayer:GetSex() then
            table.insert(lFilter, table_deep_copy(m))
        end
    end
    local mEquip
    if next(lFilter) then
        mEquip = extend.Array.weight_choose(lFilter, "weight")
    else
        local sMsg = string.format("gtxiedebug, RandomGiveEquip err, pid:%s, school:%s, ", oPlayer:GetPid(), oPlayer:GetSchool())
        print(sMsg, lGive)
    end
     return mEquip and mEquip.sid
end

function CItemCtrl:InlayPartnerStone(oParEquip, oParStone)
    local iStonePos = oParStone:StonePos()
    local iEquipPos = oParStone:EquipPos()
    local iStar = oParEquip:Star()
    local mStar = itemdefines.GetParEquipStarData(iStar)
    if not mStar then
        return
    end
    if not table_in_list(mStar.unlock_stone, iStonePos) then
        return
    end
    local iInlay = oParEquip:CountInlayStone(iStonePos)
    local mPosData = itemdefines.GetParStonePosData(iStonePos)
    if not mPosData then
        return
    end
    if iInlay >= mPosData.inlay_count then
        return
    end
    local iStoneShape = oParStone:SID()
    local iOldLv = oParEquip:CountStoneLevel()
    self:AddAmount(oParStone, -1, "吞食符石", {cancel_tip = 1})
    local bAdd = oParEquip:AddStone(iStonePos, iStoneShape)
    local iNewLv = oParEquip:CountStoneLevel()
    if iNewLv > iOldLv then
        global.oAssistMgr:PushAchieve(self:GetPid(),"伙伴符石等级", {value = iNewLv - iOldLv})
    end
    if bAdd then
        global.oAssistMgr:PushAchieve(self:GetPid(),"符石强化次数", {value = 1})
    end
    oParEquip:GS2CRefreshPartnerEquipInfo(self:GetOwner())
end

function CItemCtrl:ValidUpgradeParSoul(oPlayer, iSoulId, lCostItem)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    if #lCostItem <= 0 then
        return false
    end
    local oSoul = oPlayer:HasItem(iSoulId)
    if not oSoul then
        oAssistMgr:BroadCastNotify(iPid, nil, "强化御灵道具不存在")
        return false
    end
    if oSoul:ItemType() ~= "parsoul" then
        oAssistMgr:BroadCastNotify(iPid, nil, "非御灵道具")
        return false
    end
    if oSoul:IsMaxLevel() then
        oAssistMgr:BroadCastNotify(iPid, nil, "御灵达最大等级")
        return false
    end
    for _, iItemId in ipairs(lCostItem) do
        local oItem = oPlayer:HasItem(iItemId)
        if not oItem then
            oAssistMgr:BroadCastNotify(iPid, nil, "消耗御灵不存在")
            return false
        end
        if oItem:ItemType() ~= "parsoul" then
            oAssistMgr:BroadCastNotify(iPid, nil, "消耗非御灵")
            return false
        end
        if oItem:IsWield() then
            oAssistMgr:BroadCastNotify(iPid, nil, "消耗御灵已穿戴")
            return false
        end
        if oItem:IsLock() then
            oAssistMgr:BroadCastNotify(iPid, nil, "消耗御灵已上锁")
            return false
        end
        if oItem:IsPlan() then
            oAssistMgr:BroadCastNotify(iPid, nil, "御灵存在方案")
            return false
        end
    end
    return true
end

function CItemCtrl:UpgradePartnerSoul(oPlayer, iSoulId, lCostItem)
    local oAssistMgr = global.oAssistMgr
    local iAddExp = 0
    for _, iItemId in ipairs(lCostItem) do
        local oItem = oPlayer:HasItem(iItemId)
        iAddExp = iAddExp + oItem:EatExp()
    end
    local sCostCoin = oAssistMgr:QueryGlobalData("parsoul_upgrade_coin")
    local iCostCoin = formula_string(sCostCoin, {exp = iAddExp})
    if iCostCoin > 0 then
        local mData = {}
        mData.pid = self:GetPid()
        mData.coin = iCostCoin
        mData.reason = "御灵升级"
        -- mData.args = {cancel_tip = 1}
        interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
            local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
            if oPlayer then
                oPlayer.m_oItemCtrl:DoUpgradePartnerSoul(oPlayer, m, iSoulId, lCostItem)
            end
        end)
    end
end

function CItemCtrl:DoUpgradePartnerSoul(oPlayer, m, iSoulId, lCostItem)
    local bFlag = false
    if m.success then
        if self:ValidUpgradeParSoul(oPlayer, iSoulId, lCostItem) then
            bFlag = true
            local oSoul = oPlayer:HasItem(iSoulId)
            local iAddExp = 0
            for _, iItemId in ipairs(lCostItem) do
                local oItem = self:HasItem(iItemId)
                iAddExp = iAddExp + oItem:EatExp()
                oPlayer.m_oItemCtrl:AddAmount(oItem, -1, m.reason, {cancel_tip = 1})
            end
            if iAddExp > 0 then
                oSoul:AddExp(oPlayer, iAddExp, m.reason, {})
            end
        end
    end
    oPlayer:DoResultMoney(bFlag, m)
end

function CItemCtrl:GetItemShareReaderCopy()
    return self.m_oItemShareObj:GenReaderCopy()
end

function CItemCtrl:ShareUpdate()
    local mShapeAmount = self:PackItemShapeAmount()
    self.m_oItemShareObj:UpdateData(mShapeAmount)
end

function CItemCtrl:TestCmd(oPlayer, sCmd, mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local sReason = "gm"
    if sCmd == "clearall" then
        local mArgs = {cancel_tip = 1, cancel_channel = 1}
        for iType, oContainer in pairs(self.m_mContainer) do
            if iType ~= CONTAINER_TYPE.PARTNER_EQUIP then
                local mList = oContainer:GetList()
                for iItem, oItem in pairs(mList) do
                    self:AddAmount(oItem,-oItem:GetAmount(),sReason,mArgs, true)
                end
            else
                --伙伴符文暂时不可清除
            end
        end
    elseif sCmd == "debug_arrange" then
        local oContainer = self:GetContainer(CONTAINER_TYPE.COMMON)
        if oContainer then
            local mList = oContainer:GetList() or {}
            for iItemId, oItem in pairs (mList) do
                self:AddAmount(oItem,-1,sReason,mArgs, true)
            end
        end
    elseif sCmd == "addequipexp" then
        local iItemId, iAddExp = table.unpack(mData)
        local oEquip = self:HasItem(iItemId)
        if oEquip then
            if oEquip.AddExp then
               oEquip:AddExp(oPlayer, iAddExp, sReason, mArgs)
           else
                oNotifyMgr:Notify(iPid, "该道具不可添加经验")
            end
        else
            oNotifyMgr:Notify(iPid, "道具不存在")
        end
    elseif sCmd == "clearstonebuff" then
        for sid, oBuffStone in pairs(self.m_mBuffStone) do
            self:UnWieldBuffStone(sid)
        end
    elseif sCmd== "stonebufftime" then
        local iSec = table.unpack(mData)
        if iSec and type(iSec) ~= "number" then
            oNotifyMgr:Notify(iPid, "参数出错")
            return
        elseif type(iSec) == "number" and iSec <= 0 then
            oNotifyMgr:Notify(iPid, "参数出错")
            return
        end
        oPlayer:SetInfo("stonebufftime", iSec)
        oNotifyMgr:Notify(iPid, "设置成功")
    elseif sCmd == "fullitem" then
        local emptys = {}
        local mArgs = {cancel_tip = 1, cancel_show = 1, cancel_channel = 1}
        for iType, oContainer in pairs(self.m_mContainer) do
            local iEmpty = oContainer:SpaceGridSize()
            if iEmpty > 0 then
                local lGive = {}
                local sReason = "gm_fullitem"
                if iType == CONTAINER_TYPE.PARTNER_AWAKE then
                    local mData = res["daobiao"]["partner_item"]["awake_item"]
                    for iSid, m in pairs(mData) do
                        table.insert(lGive, {iSid, 1})
                    end
                elseif iType == CONTAINER_TYPE.PARTNER_CHIP then
                    local mData = res["daobiao"]["partner_item"]["partner_chip"]
                    for iSid, m in pairs(mData) do
                        table.insert(lGive, {iSid, 1})
                    end
                elseif iType == CONTAINER_TYPE.PARTNER_SKIN then
                    local mData = res["daobiao"]["partner_item"]["partner_skin"]
                    for iSid, m in pairs(mData) do
                        table.insert(lGive, {iSid, 1})
                    end
                elseif iType == CONTAINER_TYPE.PARTNER_TRAVEL then
                    local mData = res["daobiao"]["partner_item"]["travel"]
                    for iSid, m in pairs(mData) do
                        table.insert(lGive, {iSid, 1})
                    end
                else
                    local mData = res["daobiao"]["item"]
                    for iSid, m in pairs(mData) do
                        if m.type == iType then
                            table.insert(lGive, {iSid, m.max_overlay * iEmpty})
                            break
                        end
                    end
                end
                if next(lGive) then
                    if self:ValidGive(lGive,{cancel_tip = 1}) then
                        self:GiveItem(lGive, sReason, mArgs)
                    end
                end
                table.insert(emptys, string.format("container:%s, empty grid:%s", iType, oContainer:SpaceGridSize()))
            end
        end
        print("gtxiedbug:", emptys)
    elseif sCmd == "printitem" then
        local iItemId = mData[1]
        local oItem = self:HasItem(iItemId)
        if oItem then
            -- print(oItem)
            print("printitem:", oItem:GetApplys())
        end
    elseif sCmd == "printNotExist" then
        mData = mData or {}
    local res = require "base.res"
        for sid = 10001, 16000 do
            if global.oDerivedFileMgr:ExistFile("item","other","i"..sid) then
                mData[sid] = 1
            end
        end
        print(table_key_list(mData))
    elseif sCmd == "svndelete" then
       local lSid = {}
       local sPath
        for _, sid in ipairs(lSid) do
            if global.oDerivedFileMgr:ExistFile("item","other","i"..sid) then
                sPath = sPath ..  " service/assist/item/other/i" .. sid .. ".lua"
            end
        end
        print("gtxiedebug, delet item:", sPath)
        os.execute(string.format("svn del %s", sPath))
    end
end


CContainer = {}
CContainer.__index = CContainer
inherit(CContainer, datactrl.CDataCtrl)

function CContainer:New(iPid, iType, iMaxSize)
    local o = super(CContainer).New(self, {pid = iPid})
    o.m_iType = iType
    o.m_iMaxGridSize = iMaxSize
    o.m_mList = {}
    o.m_mShape = {}
    return o
end

function CContainer:Release()
    for _, oItem in pairs(self.m_mList) do
        baseobj_safe_release(oItem)
    end
    self.m_mList = {}
    super(CContainer).Release(self)
end

function CContainer:Load(mData)
    mData = mData or {}
    for _, mItem in pairs(mData) do
        local iSid = mItem["sid"]
        local oItem = loaditem.LoadItem(iSid, mItem)
        if oItem then
            self:DispatchItemID(oItem)
            self.m_mList[oItem.m_ID] = oItem
            self:AddShapeItem(oItem)
        else
            record.error(string.format("item sid error:%s,%s",self:GetInfo("pid"), iSid))
        end
    end
end

function CContainer:Save()
    local mData = {}
    for _, oItem in pairs(self.m_mList) do
        table.insert(mData, oItem:Save())
    end

    return mData
end

function CContainer:IsDirty()
    local bDirty = super(CContainer).IsDirty(self)
    if bDirty then
        return true
    end

    for _, oItem in pairs(self.m_mList) do
        if oItem:IsDirty() then
            return true
        end
    end

    return false
end

function CContainer:UnDirty()
    super(CContainer).UnDirty(self)
    for _, oItem in pairs(self.m_mList) do
        oItem:UnDirty()
    end
end

function CContainer:GetOwner()
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetInfo("pid")
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
    return oPlayer
end

function CContainer:GetList()
    return self.m_mList
end

function CContainer:AddItem(oSrcItem, sReason, mArgs)
    mArgs = mArgs or {}
    self:Dirty()
    local iLast = oSrcItem:GetAmount()
    local iQuality = oSrcItem:Quality()
    local iAddAmount = oSrcItem:GetAmount()
    local sName = oSrcItem:Name()
    local iMaxAmount = oSrcItem:GetMaxAmount()
    local iSid = oSrcItem:SID()
    local iColor = oSrcItem:Quality()
    local mShape = self:GetShapeItem(iSid)
    local mShowInfo = oSrcItem:GetShowInfo()
    for _,oItem in pairs(mShape) do
        if oItem:ValidCombine(oSrcItem) then
             local iHave = oItem:GetAmount()
             local iAdd = max(iMaxAmount - iHave,0)
            if iLast > 0 and iAdd > 0 then
                iAdd = min(iAdd,iLast)
                iLast = iLast - iAdd
                oSrcItem:SetAmount(iLast,sReason)
                self:AddAmount(oItem,iAdd,sReason,mArgs)
            end
        end
        if iLast <= 0 then
            break
        end
    end
    local iPid = self:GetInfo("pid")
    local sText = loaditem.FormatItemColor(iColor,"获得 %s")
    local sMsg = string.format(sText,string.format("[%s] x %s",sName, iAddAmount))
    if not mArgs.cancel_tip then
        global.oNotifyMgr:Notify(iPid,sMsg)
    end
    if not mArgs.cancel_channel then
        local oPlayer = self:GetOwner()
        global.oChatMgr:HandleMsgChat(oPlayer, sMsg)
    end
    --叠加大于１，弹窗不需要道具的服务器id
    if not mArgs.cancel_show and iMaxAmount > 1 then
        mArgs = table_copy(mArgs)
        mArgs.cancel_show = 1
        global.oUIMgr:AddKeepItem(iPid, mShowInfo)
    end
    if not mArgs.cancel_achive then
        if self.m_iType == CONTAINER_TYPE.PARTNER_SKIN then
            global.oAssistMgr:PushAchieve(self:GetPid(), "伙伴皮肤个数", {value = 1})
        elseif self.m_iType == CONTAINER_TYPE.PARTNER_SOUL then
            local iAmount = iAddAmount - oSrcItem:GetAmount()
            if iAmount > 0 then
                global.oAssistMgr:PushAchieve(self:GetPid(), "御灵散件个数", {value = iAmount})
                if iQuality == 4 then
                    global.oAssistMgr:PushAchieve(self:GetPid(), "橙色御灵散件个数", {value = iAmount})
                elseif iQuality == 6 then
                    global.oAssistMgr:PushAchieve(self:GetPid(), "红色御灵散件个数", {value = iAmount})
                end
            end
        end
    end

    if iLast <= 0 then
        return
    end
    if self:SpaceGridSize() <= 0 then
        return oSrcItem
    end
    self:AddToContainer(oSrcItem, sReason, mArgs)
end

function CContainer:AddToContainer(oItem, sReason, mArgs)
    mArgs = mArgs or {}
    if not oItem:GetData("TraceNo") then
        local iTraceNo = self:DispatchTraceNo()
        oItem:SetData("TraceNo",{self:GetInfo("pid"), iTraceNo})
    end
    if oItem:ID() <= 0 then
        self:DispatchItemID(oItem)
    end
    self.m_mList[oItem:ID()] = oItem
    oItem:OnAddToContainer()
    self:GS2CAddItem(oItem, mArgs)
    if oItem:IsQuickUse() then
        oItem:GS2CItemQuickUse()
    end
    self:AddShapeItem(oItem)
    self:OnAddToContainer(oItem, sReason, mArgs)
    local mLog = {
        sid = oItem:SID(),
        traceno = oItem:TraceNo(),
        amount = oItem:GetAmount(),
        old = 0,
        now = oItem:GetAmount(),
        reason = sReason,
    }
    self:LogItem("role_item_amount", mLog)
    self:LogAnaly(oItem:SID(),oItem:GetAmount(),sReason)
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetInfo("pid")
    oAssistMgr:SetPlayerPropChange(iPid,{"item"})
end

function CContainer:OnAddToContainer(oItem, sReason, mArgs)
    mArgs = mArgs or {}

    local oPlayer = self:GetOwner()
    if oPlayer then
        local iPid = oPlayer:GetPid()
        local iSid = oItem:SID()
        if self.m_iType == CONTAINER_TYPE.PARTNER_EQUIP then
            oPlayer.m_oPartnerCtrl:AddOwnedEquip(iSid)
        elseif self.m_iType == CONTAINER_TYPE.PARTNER_SKIN then
            if not mArgs.use_skin then
                oPlayer:Send("GS2CShowPartnerSkin", {itemid = iSid})
            end
        end
        if not mArgs.cancel_show then
            global.oUIMgr:AddKeepItem(iPid, oItem:GetShowInfo())
        end
    end
end

function CContainer:RemoveItem(oItem,sReason,bRefresh)
    self:Dirty()
    self.m_mList[oItem.m_ID] = nil
    if bRefresh then
        self:GS2CDelItem(oItem)
    end
    self:RemoveShapeItem(oItem)
    baseobj_delay_release(oItem)
    return true
end

function CContainer:Arrange()
    local measure = require "measure"
    -- measure.start()
    local mBind = {}
    local mUnBind = {}
    for iSid, mItem in pairs(self.m_mShape) do
        local m1 = {}
        local m2 = {}
        mBind[iSid] = {}
        mUnBind[iSid] = {}
        for id, _ in pairs(mItem) do
            local oItem = self:HasItem(id)
            if oItem then
                if oItem:IsBind() then
                    table.insert(m1, oItem)
                else
                    table.insert(m2, oItem)
                end
            end
        end
        if next(m1) then
            mBind[iSid] = m1
        end
        if next(m2) then
            mUnBind[iSid] = m2
        end
    end
    self:Arrange1(mUnBind)
end

function CContainer:Arrange1(mShapeItem)
    for iSid, lItem in pairs(mShapeItem) do
        local iLeft, iRight = 1, #lItem
        while iLeft < iRight do
            local oLeft = lItem[iLeft]
            local oRight = lItem[iRight]
            local iLeftAmount = oLeft:GetAmount()
            local iRightAmount = oRight:GetAmount()
            local bCombine = true
            if iLeftAmount >= oLeft:GetMaxAmount() then
                bCombine = false
                iLeft = iLeft + 1
            end
            if iRightAmount >= oRight:GetMaxAmount() then
                bCombine = false
                iRight = iRight - 1
            end
            if bCombine then
                local bLeft = self:Combine(oLeft, oRight)
                if bLeft then
                    iLeft = iLeft + 1
                else
                    iRight = iRight -1
                end
            end
        end
    end
end

function CContainer:Combine(oLeft, oRight)
    local measure = require "measure"
    -- measure.start()
    local iClock = os.clock()
    local iMax = oLeft:GetMaxAmount()
    local iLeftHave = oLeft:GetAmount()
    local iRightHave = oRight:GetAmount()
    local iLeftTime = oLeft:GetCreateTime()
    local iRightTime = oRight:GetCreateTime()
    if iRightTime < iLeftTime then
        local iLeftNeed = math.min(iRightHave, iMax - iLeftHave)
        self:AddAmount(oLeft,iLeftNeed,"arrange")
        self:AddAmount(oRight,-iLeftNeed,"arrange")
        if iLeftNeed == iRightHave then
            return false
        end
        if iLeftNeed + iLeftHave  == iMax then
            return true
        end
    else
        local iRightNeed = math.min(iLeftHave, iMax - iRightHave)
        self:AddAmount(oRight,iRightNeed,"arrange")
        self:AddAmount(oLeft,-iRightNeed,"arrange")
        if iRightNeed == iLeftHave then
            return true
        end
        if iRightNeed + iRightHave  == iMax then
            return false
        end
    end
end

function CContainer:ItemList()
    return self.m_mList
end

function CContainer:ItemCount()
    return table_count(self.m_mList)
end

function CContainer:AddShapeItem(oItem)
    local iSid = oItem:SID()
    local iItemid = oItem:ID()
    if not self.m_mShape[iSid] then
        self.m_mShape[iSid] = {}
    end
    local mItem = self.m_mShape[iSid] or {}
    mItem[iItemid] = 1
    self.m_mShape[iSid] = mItem
end

function CContainer:RemoveShapeItem(oItem)
    local iSid = oItem:SID()
    local iItemid = oItem:ID()
    local mShape = self.m_mShape[iSid]
    mShape[iItemid] = nil
    self.m_mShape[iSid] = mShape
end

function CContainer:GetShapeItem(iSid)
    local mShape = self.m_mShape[iSid] or {}
    local mItem = {}
    for iItemid,_ in pairs(mShape) do
        local oItem = self:HasItem(iItemid)
        if oItem then
            table.insert(mItem, oItem)
        end
    end
    return mItem
end

function CContainer:GetItemObj(iSid)
    local mShape = self.m_mShape[iSid] or {}
    for iItemid,_ in pairs(mShape) do
        local oItem = self:HasItem(iItemid)
        if oItem then
            return oItem
        end
    end
end

function CContainer:HasItem(itemid)
    return self.m_mList[itemid]
end

function CContainer:SpaceGridSize()
    local iUseGridSize = extend.Table.size(self.m_mList)
    return max(self.m_iMaxGridSize - iUseGridSize, 0)
end

function CContainer:RemoveItemAmount(iSid,iAmount,sReason, mArgs)
    mArgs = mArgs or {}
    local iHaveAmount = self:GetItemAmount(iSid)
    local iRecord = iAmount
    if iHaveAmount < iAmount then
        return false
    end
    local mItemList = self:GetShapeItem(iSid)
    local SortFunc = function (oItem1,oItem2)
        if oItem1:IsBind() ~= oItem2:IsBind() then
            if oItem1:IsBind() then
                return true
            elseif oItem2:IsBind() then
                return false
            end
        else
            if oItem1:GetAmount() ~= oItem2:GetAmount() then
                return oItem1:GetAmount() < oItem2:GetAmount()
            else
                return oItem1.m_ID < oItem2.m_ID
            end
        end
    end
    table.sort(mItemList, SortFunc)

    for _,oItem in pairs(mItemList) do
        local iSubAmount = oItem:GetAmount()
        iSubAmount = min(iSubAmount, iAmount)
        iAmount = iAmount - iSubAmount
        self:AddAmount(oItem,-iSubAmount,sReason,mArgs)
        if iAmount <= 0 then
            break
        end
    end
    if iAmount > 0 then
        return false
    end
    if not mArgs.cancel_channel then
        local oItem = loaditem.GetItem(iSid)
        local sText = loaditem.FormatItemColor(oItem:Quality(),"消耗 %s")
        local sMsg = string.format(sText,string.format("[%s] x %s",oItem:Name(), iRecord))
        global.oChatMgr:HandleMsgChat(self:GetOwner(), sMsg)
    end
    return true
end

function CContainer:PackItemShapeAmount()
    local mPackAmount = {}
    local mSpace = {}
    for iShape,mItem in pairs(self.m_mShape) do
        for iItemid,_ in pairs(mItem) do
            local oItem = self:HasItem(iItemid)
            if oItem then
                if not mPackAmount[iShape] then
                    mPackAmount[iShape] = 0
                end
                mPackAmount[iShape] = mPackAmount[iShape] + oItem:GetAmount()
                if not mSpace[iShape] then
                    mSpace[iShape] = 0
                end
                mSpace[iShape] = mSpace[iShape] + 1
            end
        end
    end
    return {
        shape_amount = mPackAmount,
        space = mSpace
    }
end

function CContainer:GetItemAmount(sid)
    local iAmount = 0
    for _,oItem in pairs(self.m_mList) do
        if oItem:SID() == sid then
            iAmount = iAmount + oItem:GetAmount()
        end
    end
    return iAmount
end

function CContainer:GetPid()
    return self:GetInfo("pid")
end

function CContainer:GetTips()
    if CONTAINER_TYPE.PARTNER_STONE then
        return "符石数量已满，超出数量上限的符石则消失，请及时清理背包"
    end
    return "背包已满，无法获得道具，请清理背包"
end

--ItemList:{sid, iAmount, bBind}
function CContainer:ValidGive(ItemList,mArgs)
    mArgs = mArgs or {}
    local iNeedSpace = 0
    for _, mItem in pairs(ItemList) do
        local sid, iAmount, bBind = table.unpack(mItem)
        bBind = bBind or false
        local oItem = loaditem.GetItem(sid)
        local iShape = oItem:SID()
        local lItem = self:GetShapeItem(iShape)
        local iCanAddAmount = 0
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
    local iHaveSpace = self:SpaceGridSize()
    if iHaveSpace < iNeedSpace then
        if not mArgs.cancel_tip then
            global.oAssistMgr:Notify(self:GetPid(), self:GetTips())
        end
        return false
    end
    return true
end

function CContainer:ValidGiveSingleItem(lItem,mArgs)
    lItem = lItem or {}
    local mGiveAmount = {}
    for _, m in ipairs(lItem) do
        local sid, iAmount, _ = table.unpack(m)
        local oItem = loaditem.GetItem(sid)
        local iShape = oItem:SID()
        local iHave = mGiveAmount[iShape] or 0
        mGiveAmount[iShape] = iHave + iAmount
    end
    for iShape, iAdd in pairs(mGiveAmount) do
        local iHave = 0
        local oItem = self:GetItemObj(iShape)
        if oItem then
            iHave = oItem:GetAmount()
        else
            oItem = loaditem.GetItem(iShape)
        end
        local iMaxAmount = oItem:GetMaxAmount()
        if iHave + iAdd > iMaxAmount then
            if not mArgs.cancel_tip then
                global.oNotifyMgr:Notify(self:GetPid(), self:GetTips())
            end
            return false
        end
    end
    return true
end

--占用一个格子
function CContainer:IsSingleItem()
    local lSingle = {
        CONTAINER_TYPE.PARTNER_SKIN,
        CONTAINER_TYPE.PARTNER_AWAKE,
        CONTAINER_TYPE.PARTNER_CHIP,
        CONTAINER_TYPE.PARTNER_TRAVEL,
        CONTAINER_TYPE.PARTNER_STONE,
    }
    if table_in_list(lSingle, self.m_iType) then
        return true
    end
    return false
end

--ItemList:{iSid, iAmount, bBind}
function CContainer:GiveItem(ItemList, sReason, mArgs, lTips)
    local oNotifyMgr = global.oNotifyMgr

    mArgs = table_deep_copy(mArgs)
    local cancel_tip = mArgs.cancel_tip
    local cancel_channel = mArgs.cancel_channel
    mArgs.cancel_tip = 1
    mArgs.cancel_channel = 1

    local iPid = self:GetInfo("pid")
    local mAmount = {}
    for _, mItem in pairs(ItemList) do
        local sid, iAmount, bBind = table.unpack(mItem)
        local iRecord = iAmount
        local iHaveAdd = mAmount[sid] or 0
        mAmount[sid] = iHaveAdd + iAmount
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

    local iParSkin = 0
    local iParSoul = 0
    local iYellowParSoul = 0
    local iRedParSoul = 0
    for sid, iAmount in pairs(mAmount) do
        local oItem = loaditem.GetItem(sid)
        local iColor = oItem:Quality()
        if not cancel_tip or not cancel_channel then
            local sText = loaditem.FormatItemColor(iColor,"%s")
            local sMsg = string.format(sText,string.format("[%s] x %s",oItem:Name(), iAmount))
            table.insert(lTips, sMsg)
        end
        if self.m_iType == CONTAINER_TYPE.PARTNER_SKIN then
            iParSkin = iParSkin + iAmount
        elseif self.m_iType == CONTAINER_TYPE.PARTNER_SOUL then
            iParSoul = iParSoul + iAmount
            if iColor == 4 then
                iYellowParSoul = iYellowParSoul + iAmount
            elseif iColor == 6 then
                iRedParSoul = iRedParSoul + iAmount
            end
        end
    end
    if iParSkin > 0 then
        global.oAssistMgr:PushAchieve(self:GetPid(), "伙伴皮肤个数", {value = iParSkin})
    end
    if iParSoul > 0 then
        global.oAssistMgr:PushAchieve(self:GetPid(), "御灵散件个数", {value = iParSoul})
    end
    if iYellowParSoul > 0 then
        global.oAssistMgr:PushAchieve(self:GetPid(), "橙色御灵散件个数", {value = iYellowParSoul})
    end
    if iRedParSoul > 0 then
        global.oAssistMgr:PushAchieve(self:GetPid(), "红色御灵散件个数", {value = iRedParSoul})
    end
end

function CContainer:DispatchTraceNo()
    local oPlayer = self:GetOwner()
    return oPlayer and oPlayer.m_oItemCtrl:DispatchTraceNo()
end

function CContainer:DispatchItemID(oItem)
    local oPlayer = self:GetOwner()
    return oPlayer and oPlayer.m_oItemCtrl:DispatchItemID(oItem)
end

function CContainer:GS2CAddItem(oItem, mArgs)
    mArgs = mArgs or {}
    local mNet = {}
    local itemdata = oItem:PackItemInfo()
    mNet["itemdata"] = itemdata
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:Send("GS2CAddItem",mNet)
    end
end

function CContainer:GS2CItemAmount(oItem,mArgs)
    mArgs = mArgs or {}
    local mNet = {}
    mNet["id"] = oItem.m_ID
    mNet["amount"] = oItem:GetAmount()
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:Send("GS2CItemAmount",mNet)
    end
end

function CContainer:GS2CDelItem(oItem)
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(self:GetInfo("pid"))
    if oPlayer then
        oPlayer:Send("GS2CDelItem",{
            id = oItem.m_ID,
            })
    end
end

function CContainer:AddAmount(oItem,iAmount,sReason,mArgs,bRefresh)
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
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetInfo("pid")
    oAssistMgr:SetPlayerPropChange(iPid,{"item"})
end

function CContainer:LogItem(sSubType,mLog,mArgs)
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

function CContainer:LogAnaly(SID,iAmount,sReason)
    local oPlayer = self:GetOwner()
    if oPlayer then
        local mLog = oPlayer:GetPubAnalyData()
        mLog["operation"] = iAmount > 0 and 1 or 2
        mLog["item_id"] = SID
        mLog["num"] = iAmount
        mLog["remain_num"] = self:GetItemAmount(SID)
        mLog["reason"] = sReason
        analy.log_data("BackpackChange",mLog)
    end
end

CItemShareObj = {}
CItemShareObj.__index = CItemShareObj
inherit(CItemShareObj, shareobj.CShareWriter)

function CItemShareObj:New(mShapeAmount)
    local o = super(CItemShareObj).New(self)
    o.m_mShapeAmount = mShapeAmount.amount or {}
    o.m_mSpace = mShapeAmount.space or {}
    return o
end

function CItemShareObj:UpdateData(mShapeAmount)
    self.m_mShapeAmount = mShapeAmount.shape_amount
    self.m_mSpace = mShapeAmount.space
    self:Update()
end

function CItemShareObj:Pack()
    local m = {}
    m.shape_amount = self.m_mShapeAmount
    m.space = self.m_mSpace
    return m
end
