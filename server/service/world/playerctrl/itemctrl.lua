local skynet = require "skynet"
local global = require "global"

local extend = require "base.extend"
local record = require "public.record"
local colorstring = require "public.colorstring"
local interactive = require "base.interactive"
local res = require "base.res"

local shareobj = import(lualib_path("base.shareobj"))
local datactrl = import(lualib_path("public.datactrl"))
local loaditem = import(service_path("item.loaditem"))
local handleitem = import(service_path("item/handleitem"))
local itemdefines = import(service_path("item/itemdefines"))
local assistuse = import(service_path("item/assistuse"))
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
    o.m_iPid = iPid
    o.m_mContainer = {}
    o.m_oItemShareObj = CItemShareObj:New()
    o:ConfirmRemote()
    o:Init(iPid)
    return o
end

function CItemCtrl:Release()
    baseobj_safe_release(self.m_oItemShareObj)
    super(CItemCtrl).Release(self)
end

function CItemCtrl:Init(iPid)
    for _, iType in pairs(CONTAINER_TYPE) do
        if iType ~= CONTAINER_TYPE.EQUIP then
            local oContainer = NewContainer(iPid, iType, self:MaxGridSize(iType))
            self.m_mContainer[iType] = oContainer
            oContainer.m_Container = self
        end
    end
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

function CItemCtrl:GetPid()
    return self.m_iPid
end

function CItemCtrl:GetOwner()
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetInfo("pid")
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
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

function CItemCtrl:ConfirmRemote()
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local iRemoteAddr = oAssistMgr:SelectRemoteAssist(iPid)
    self.m_iRemoteAddr = iRemoteAddr
end

function CItemCtrl:Forward(sCmd, iPid, mData)
    interactive.Send(self.m_iRemoteAddr, "item", "Forward", {
        pid = iPid,
        cmd = sCmd,
        data = mData,
    })
    return true
end

function CItemCtrl:TestCmd(iPid, sCmd, mData)
    interactive.Send(self.m_iRemoteAddr, "item", "TestCmd", {
        pid = iPid,
        cmd = sCmd,
        data = mData,
    })
end

--ItemList:{iSid, iAmount, bBind}
function CItemCtrl:ValidGive(ItemList, mArgs)
    mArgs = mArgs or {}
    local mContainerItem = {}
    local lVirtualItem = {}
    for _, m in ipairs(ItemList) do
        local oItem = loaditem.GetItem(m[1])
        local iType = oItem:Type()
        if oItem:ItemType() == "virtual" then
            table.insert(lVirtualItem, m)
        else
            mContainerItem[iType] = mContainerItem[iType] or {}
            table.insert(mContainerItem[iType], m)
        end
    end
    local bValidGive = true
    local oPlayer = self:GetOwner()
    if not oPlayer then
        bValidGive = false
    end
    if not self:ValidGiveVirtual(oPlayer,lVirtualItem) then
        -- global.oNotifyMgr:Notify(oPlayer:GetPid(), "货币已满")
        bValidGive = false
    end
    if bValidGive then
        for iType, lItem in pairs(mContainerItem) do
            local oContainer = self.m_mContainer[iType]
            assert(oContainer, string.format("item type err: %s, %s", self:GetInfo("pid"), iType))
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

function CItemCtrl:ValidGiveVirtual(oPlayer, lItem)
    lItem = lItem or {}
    local mItem = {}
    for _, m in ipairs(lItem) do
        local sid, iAmount = table.unpack(m)
        local oItem = loaditem.GetItem(sid)
        local iShape = oItem:SID()
        mItem[iShape] = (mItem[iShape] or 0) + oItem:GetData("value", 1) * iAmount
    end
    local COIN_TYPE = gamedefines.COIN_FLAG
    for iSid, iAmount in pairs(mItem) do
        if iSid == 1002 then
            local iSum = oPlayer:Coin() + iAmount
            if not oPlayer:IsOverflowCoin(COIN_TYPE.COIN_COIN,iSum) then
                return false
            end
        elseif iSid == 1003 then
            local iSum = oPlayer:GoldCoin() + iAmount
            if not oPlayer:IsOverflowCoin(COIN_TYPE.COIN_GOLD,iSum) then
                return false
            end
        elseif iSid == 1014 then
            local iSum = oPlayer:GetOffer() + iAmount
            if not oPlayer:IsOverflowCoin(COIN_TYPE.COIN_ORG_OFFER, iSum) then
                return false
            end
        elseif iSid == 1017 then
            local iSum = oPlayer:Skin() + iAmount
            if not oPlayer:IsOverflowCoin(COIN_TYPE.COIN_SKIN, iSum) then
                return false
            end
        end
    end
    return true
end

function CItemCtrl:AssistGiveItem(ItemList,sReason,mArgs)
    mArgs = mArgs or {}
    ItemList = ItemList or {}
    local mContainerItem = {}
    local lVirtualItem = {}
    for _, lItem in ipairs(ItemList) do
        local oItem = loaditem.GetItem(lItem[1])
        local iType = oItem:Type()
        if oItem:ItemType() == "virtual" then
            table.insert(lVirtualItem,lItem)
        else
            table.insert(mContainerItem,lItem)
        end
    end
    if next(lVirtualItem) then
        self:GiveVirtualItem(lVirtualItem,sReason,mArgs)
    end
    if #mContainerItem > 0 then
        record.error(string.format("item:%s reason%s pid:%s",mContainerItem,sReason,self:GetPid()))
    end
end

--ItemList:{iSid, iAmount, bBind}
function CItemCtrl:GiveItem(ItemList,sReason,mArgs,fCallback)
    mArgs = mArgs or {}
    local iPid = self:GetInfo("pid")
    local mContainerItem = {}
    local lVirtualItem = {}
    for _, lItem in ipairs(ItemList) do
        local iShape,iAmount = table.unpack(lItem)
        local oItem = loaditem.GetItem(iShape)
        if oItem:ItemType() == "virtual" then
            table.insert(lVirtualItem,lItem)
        else
            -- local mShowInfo = {
            --     id = 0,
            --     sid = iShape,
            --     virtual = 0,
            --     amount = iAmount,
            -- }
            -- global.oUIMgr:AddKeepItem(iPid, mShowInfo)
            table.insert(mContainerItem,lItem)
        end
    end
    if next(lVirtualItem) then
        self:GiveVirtualItem(lVirtualItem,sReason,mArgs)
    end
    if table_count(mContainerItem) > 0 then
        self:RemoteGiveItem(mContainerItem,sReason,mArgs,fCallback)
    end
end

function CItemCtrl:GiveVirtualItem(lItem, sReason, mArgs)
    local iPid = self:GetInfo("pid")
    lItem = lItem or {}
    local oPlayer = self:GetOwner()
    assert(oPlayer,string.format("itemctrl error:%s,%s", self:GetInfo("pid"), sReason))
    for _,m in ipairs(lItem) do
        local iSid, iAmount = table.unpack(m)
        local oItem = loaditem.ExtCreate(iSid)
        if iAmount and iAmount > 0 then
            local iAmount = oItem:GetData("value", 1) * iAmount
            oItem:SetData("value", iAmount)
            oItem:Reward(oPlayer, sReason, mArgs)
        else
            record.error("GiveVirtualItem err:%s,%s,%s,%s", iPid, iSid, iAmount, sReason)
        end
    end
end

function CItemCtrl:SetEquipSE(mSE)
    self.m_mSE = mSE
end

function CItemCtrl:GetEquipSEList()
    return self.m_mSE or {}
end

------------------------------------------------服务交互------------------------
function CItemCtrl:AddItem(oSrcItem, sReason, mArgs)
    mArgs = mArgs or {}
    local iPid = self:GetInfo("pid")
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
    local mItemData = oSrcItem:PackRemoteData()
    -- local mShowInfo = oSrcItem:GetShowInfo()
    -- mShowInfo.amount = oSrcItem:GetAmount()
    -- global.oUIMgr:AddKeepItem(iPid, mShowInfo)
    baseobj_safe_release(oSrcItem)
    interactive.Send(self.m_iRemoteAddr, "item", "RewardItem", {
        pid = iPid,
        item = mItemData,
        reason = sReason,
        args = mArgs,
    })
end

function CItemCtrl:InitEquip()
    local iPid = self:GetInfo("pid")
    interactive.Send(self.m_iRemoteAddr, "item", "InitEquip", {
        pid = iPid,
    })
end

function CItemCtrl:SyncItemAmount(mShape)
end

function CItemCtrl:GetItemAmount(iShape)
    return self.m_oItemShareObj:GetItemAmount(iShape)
end

function CItemCtrl:RemoveItemAmount(iShape,iAmount,sReason,mArgs,fCallback)
    local iPid = self:GetPid()
    mArgs = mArgs or {}

    interactive.Request(self.m_iRemoteAddr, "item", "RemoveItemAmount", {
        pid = iPid,
        shape = iShape,
        amount = iAmount,
        reason = sReason,
        args = mArgs
        }, fCallback)
end

function CItemCtrl:RemoveItemList(lItem,sReason,mArgs,fCallback)
    local iPid = self:GetPid()
    mArgs = mArgs or {}
    interactive.Request(self.m_iRemoteAddr,"item","RemoveItemList",{
        pid = iPid,
        items = lItem,
        reason = sReason,
        args = mArgs
    },fCallback)
end

function CItemCtrl:RemoteGiveItem(lItem,sReason,mArgs,fCallback)
    local iPid = self:GetPid()
    mArgs = mArgs or {}
    interactive.Request(self.m_iRemoteAddr,"item","GiveItem",{
        pid = iPid,
        items = lItem,
        reason = sReason,
        args = mArgs
    },fCallback)
end

function CItemCtrl:SwitchSchool(oPlayer,iSchoolBranch,fCallback)
    local iPid = self:GetInfo("pid")
    local mData = {
        pid = iPid,
        school_branch = iSchoolBranch,
    }
    interactive.Request(self.m_iRemoteAddr,"common","SwitchSchool",mData,fCallback)
end

function CItemCtrl:GiveSecondEquip(oPlayer)
    local iPid = oPlayer:GetPid()
    local mData = {
        pid = iPid
    }
    interactive.Send(self.m_iRemoteAddr,"common","GiveSecondEquip",mData)
end

function CItemCtrl:OpenSecondFuwen(oPlayer)
    local iPid = oPlayer:GetPid()
    local mData = {
        pid = iPid
    }
    interactive.Send(self.m_iRemoteAddr,"common","OpenSecondFuwen",mData)
end

function CItemCtrl:OpenFuWenPlan(oPlayer, iPlan)
    local iPid = oPlayer:GetPid()
    interactive.Send(self.m_iRemoteAddr, "item", "OpenFuWenPlan", {
        pid = iPid,
        plan = iPlan,
    })
end

function CItemCtrl:InitShareObj(oRemoteItemShare)
    self.m_oItemShareObj:Init(oRemoteItemShare)
end

------------------------------------------------------协议----------------------------------------

function CItemCtrl:C2GSItemUse(iItemId,target,iAmount, lItemSid)
    local iPid = self:GetInfo("pid")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mRemoteData = {
        itemid = iItemId,
        target = target,
        amount = iAmount or 1,
        remote_args = oPlayer:PackItemAssistData(),
    }
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:UseCallback(oPlayer,mData)
        end
    end

    interactive.Request(self.m_iRemoteAddr, "item", "C2GSItemUse", {
        pid = iPid,
        data = mRemoteData,
    },fCallback)
end

function CItemCtrl:UseCallback(oPlayer,mData)
    local bSuc = mData.success
    if not bSuc then
        return
    end
    local mArgs = mData.args
    local sCmd = mArgs.cmd
    if assistuse[sCmd] then
        assistuse[sCmd](oPlayer,mArgs)
    end
end

function CItemCtrl:C2GSResetFuWen(oPlayer,mData,mArgs)
    local iPid = self:GetInfo("pid")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iPos = mData["pos"]
    local iPrice = mData["price"]
    mArgs = mArgs or {}
    local mRemoteData = {
        pos = iPos,
        price = iPrice,
        args = mArgs,
    }
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            self:ResetFuwenCallback(oPlayer,iPos,mData)
        end
    end

    interactive.Request(self.m_iRemoteAddr, "item", "C2GSResetFuWen", {
        pid = iPid,
        data = mRemoteData,
    },fCallback)
end

function CItemCtrl:C2GSEquipStrength(oPlayer,mData,mArgs)
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    mArgs = mArgs or {}
    local mPacketData = {
        grade = oPlayer:GetGrade(),
        equip_strength = oPlayer.m_oActiveCtrl:GetData("equip_strength",{}),
        args = mArgs
    }
    local mRemoteData = {
        pid = iPid,
        pos = mData.pos,
        strength_info = mData.strength_info,
        args = mPacketData,
    }
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer.m_oItemCtrl:EquipStrengthCallback(oPlayer,mData,mRemoteData)
        end
    end
    interactive.Request(self.m_iRemoteAddr, "item", "C2GSEquipStrength",mRemoteData,fCallback)
end

function CItemCtrl:EquipStrengthCallback(oPlayer,mData,mInitData)
    local bSuc = mData.success
    if bSuc then
        local sReason = "装备强化"
        local mArgs = mData.args
        local iPos = mArgs.pos
        local iNewLevel = mArgs.level
        oPlayer:EquipStrength(iPos,iNewLevel, sReason)
        oPlayer:AddSchedule("promoted_equip")
        oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30019,1)
        oPlayer:UpdateEquipShare()
        oPlayer:ActivePropChange()
    else
        self:EquipStrengthFail(oPlayer,mData,mInitData)
    end
end

function CItemCtrl:EquipStrengthFail(oPlayer,mData,mInitData)
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local mArgs = mData.args or {}
    local lBuyItem = mArgs.buy_item
    if mArgs.fail then
        return
    end
    if not self:ValidBuyItem(oPlayer,lBuyItem,mArgs) then
        self:RefreshItemPrice(oPlayer,lBuyItem)
        return
    end
    local iGold = 0
    for _,lItem in ipairs(lBuyItem) do
        local iShape,iAmount,iPrice = table.unpack(lItem)
        local oItem = loaditem.GetItem(iShape)
        iGold = iGold + iAmount * iPrice
    end
    local iFrozenSession = oPlayer:FrozenMoney("goldcoin",iGold,"购买材料")
    local mBuyArgs = {
        frozen = iFrozenSession,
        gold = iGold,
        buy_item = lBuyItem,
    }
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer.m_oItemCtrl:BuyEquipStrength(oPlayer,mBuyArgs,mInitData,mData)
    end

    oPlayer:GiveItem(lBuyItem,"购买材料", {cancel_tip=1},fCallback)
end

function CItemCtrl:BuyEquipStrength(oPlayer,mBuyArgs,mInitData,mData)
    local oProfile = oPlayer:GetProfile()
    local bSuc = mData.success
    local iFrozenSession = mBuyArgs.frozen
    local iGold = mBuyArgs.gold
    local lItem = mBuyArgs.buy_item
    if not bSuc then
        oProfile:UnFrozenMoney(iFrozenSession)
    else
        oProfile:UnFrozenMoney(iFrozenSession)
        oPlayer:ResumeGoldCoin(iGold,"购买材料")
        self:RefreshItemPrice(oPlayer,lItem)
        local mArgs = {
            goldcoin = iGold,
        }
        local mData = {
            pos = mInitData.pos,
            strength_info = mInitData.strength_info,
            args = mArgs
        }
        self:C2GSEquipStrength(oPlayer,mData)
    end
end

function CItemCtrl:ResetFuwenCallback(oPlayer,iPos,mData)
    local bSuc = mData.success
    if bSuc then
        oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30018,1)
    else
        self:ResetFuWenFail(oPlayer,iPos,mData)
    end
end

function CItemCtrl:ResetFuWenFail(oPlayer,iPos,mData)
    local mArgs = mData.args or {}
    local lItem = mArgs.buy_item
    if mArgs.fail then
        return
    end
    if not self:ValidBuyItem(oPlayer,lItem,mArgs) then
        self:RefreshItemPrice(oPlayer,lItem)
        return
    end
    local lBuyItem = mData.buy_item
    local iGold = 0
    for _,lItem in ipairs(lBuyItem) do
        local iShape,iAmount,iPrice = table.unpack(lItem)
        local oItem = loaditem.GetItem(iShape)
        iGold = iGold + iAmount * iPrice
    end
    local iFrozenSession = oPlayer:FrozenMoney("goldcoin",iGold,"购买材料")
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer.m_oItemCtrl:BuyFuWen(oPlayer,iFrozenSession)
    end
    oPlayer:GiveItem(lItem,"购买材料", {cancel_tip=1},fCallback)
end

function CItemCtrl:BuyFuWen(oPlayer,iFrozenSession)
    local oProfile = oPlayer:GetProfile()
    local bSuc = mData.success
    if not bSuc then
        oProfile:UnFrozenMoney(iFrozenSession)
    else
        oProfile:UnFrozenMoney(iFrozenSession)
        oPlayer:ResumeGoldCoin(iGold,"购买材料")
        self:RefreshItemPrice(oPlayer,{iShape})
        local mArgs = {
            cost_goldcoin = iGold,
        }
        local mData = {
            price = iPrice,
            pos = iPos,
            args = mArgs
        }
        self:C2GSResetFuWen(oPlayer,mData)
    end
end

function CItemCtrl:RefreshItemPrice(oPlayer,lShape)
    local mPrice = {}
    for _,lItem in ipairs(lShape) do
        local iShape,iAmount,iPrice = table.unpack(lItem)
        local oItem = loaditem.GetItem(iShape)
        local iPrice = oItem:BuyPrice()
        table.insert(mPrice,{sid = iShape,price = iPrice})
    end
    oPlayer:Send("GS2CItemPrice",{
        item_info = mPrice
    })
end

function CItemCtrl:ValidBuyItem(oPlayer,lItemList,mArgs)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local iGold = 0
    for _,lItem in ipairs(lItemList) do
        local iShape,iAmount,iPrice = table.unpack(lItem)
        local oItem = loaditem.GetItem(iShape)
        local iSalePrice = oItem:BuyPrice()
        if iSalePrice ~= iPrice then
            oNotifyMgr:Notify(iPid,"材料价格发生波动")
            return false
        end
        iGold = iGold + iAmount * iPrice
    end
    if not oPlayer:ValidGoldCoin(iGold) then
        return false
    end
    return true
end

function CItemCtrl:C2GSItemInfo(iItemId)
    local iPid = self:GetInfo("pid")
    local mData = {
        itemid = iItemId
    }
    self:Forward("C2GSItemInfo",iPid,mData)
end

function CItemCtrl:C2GSDeComposeItem(iItemId,iAmount)
    local iPid = self:GetInfo("pid")
    local mData = {
        id = iItemId,
        amount = iAmount or 1
    }
    self:Forward("C2GSDeComposeItem",iPid,mData)
end

function CItemCtrl:C2GSComposeItem(iSid,iAmount)
    local iPid = self:GetInfo("pid")
    local mData = {
        sid = iSid,
        amount = iAmount or 1
    }
    self:Forward("C2GSComposeItem",iPid,mData)
end

function CItemCtrl:RecycleItem(iSaleId,iSaleAmount,fCallback)
    local iPid = self:GetInfo("pid")
    interactive.Request(self.m_iRemoteAddr,"item","RecycleItem",{
        pid = iPid,
        itemid = iSaleId,
        amount = iSaleAmount
    },fCallback)
end

function CItemCtrl:RecycleItemList(lSaleList,fCallback)
    local iPid = self:GetInfo("pid")
    interactive.Request(self.m_iRemoteAddr,"item","RecycleItemList",{
        pid = iPid,
        sale_list = lSaleList
    },fCallback)
end

function CItemCtrl:C2GSArrangeItem()
    local iPid = self:GetInfo("pid")
    local mData = {}
    self:Forward("C2GSArrangeItem",iPid,mData)
end

function CItemCtrl:C2GSPromoteEquipLevel(oPlayer,iPos,iItemId)
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetInfo("pid")
    local mArgs = {
        grade = oPlayer:GetGrade(),
    }
    local mData = {
        pos = iPos,
        itemid = iItemId,
        args = mArgs
    }
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer.m_oItemCtrl:PromoteEquipCallback(oPlayer,mData)
    end
    interactive.Request(self.m_iRemoteAddr,"item","C2GSPromoteEquipLevel",{
        pid = iPid,
        data = mData,
    },fCallback)
end

function CItemCtrl:PromoteEquipCallback(oPlayer,mData)
    local bSuc = mData.success
    if not bSuc then
        return
    end
    local mArgs = mData.args
    oPlayer:UpdateEquipShare()
    oPlayer:ActivePropChange()
    local iWeapon = mArgs.weapon or 0
    if iWeapon ~= oPlayer:GetWeapon() then
        oPlayer:ChangeWeapon(iWeapon)
    end
    if mArgs.equip then
        oPlayer:SyncEquipData(mArgs.equip)
    end
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30021,1)
end

function CItemCtrl:C2GSInlayGem(mData)
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetInfo("pid")
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mArgs = {
        grade = oPlayer:GetGrade(),
    }
    local mData = {
        pid = iPid,
        pos = mData["pos"],
        itemid = mData["itemid"],
        gem_pos = mData["gem_pos"],
        args = mArgs,
    }
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer.m_oItemCtrl:InlayGemCallback(oPlayer,mData)
    end
    interactive.Request(self.m_iRemoteAddr,"item","C2GSInlayGem",mData,fCallback)
end

function CItemCtrl:InlayGemCallback(oPlayer,mData)
    local bSuc = mData.success
    if not bSuc then
        return
    end
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30016,1)
    oPlayer:UpdateEquipShare()
    oPlayer:ActivePropChange()
end

function CItemCtrl:C2GSAddGemExp(mData)
    local iPid = self:GetInfo("pid")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mArgs = {
        grade = oPlayer:GetGrade(),
    }
    local mData = {
        pid = iPid,
        pos = mData["pos"],
        itemid = mData["itemid"],
        gem_pos = mData["gem_pos"],
        gem_list = mData["gem_list"],
        args = mArgs,
    }
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer.m_oItemCtrl:AddGemExpCallback(oPlayer,mData)
    end
    interactive.Request(self.m_iRemoteAddr,"item","C2GSAddGemExp",mData,fCallback)
end

function CItemCtrl:AddGemExpCallback(oPlayer,mData)
    local bSuc = mData.success
    if not bSuc then
        return
    end
    local mArgs = mData.args or {}
    oPlayer:UpdateEquipShare()
    oPlayer:ActivePropChange()
end

function CItemCtrl:C2GSFastStrength(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetInfo("pid")
    local mArgs = {
        grade = oPlayer:GetGrade(),
        equip_strength = oPlayer.m_oActiveCtrl:GetData("equip_strength",{}),
    }
   local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer.m_oItemCtrl:FastStrengthCallback(oPlayer,mData)
    end
    interactive.Request(self.m_iRemoteAddr,"item","C2GSFastStrength",{
        pid = iPid,
        args = mArgs,
    },fCallback)
end

function CItemCtrl:FastStrengthCallback(oPlayer,mData)
    local bSuc = mData.success
    if not bSuc then
        return
    end
    local sReason = "一键打造"
    local mArgs = mData.args
    local mEquipStrength = mArgs.equip_strength or {}
    for iPos,iLevel in pairs(mEquipStrength) do
        oPlayer:EquipStrength(iPos,iLevel,sReason)
    end
    oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30019,1)
    oPlayer:AddSchedule("promoted_equip")
    oPlayer:UpdateEquipShare()
    oPlayer:ActivePropChange()
end

function CItemCtrl:C2GSFastAddGemExp()
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetInfo("pid")
    local mData = {}
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer.m_oItemCtrl:FastAddGemExpCallback(oPlayer,mData)
    end
    interactive.Request(self.m_iRemoteAddr,"item","C2GSFastAddGemExp",{
        pid = iPid,
    },fCallback)
end

function CItemCtrl:FastAddGemExpCallback(oPlayer,mData)
    if mData.brefresh then
        oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30016,1)
        local mArgs = mData.args or {}
        local mEquipData = mArgs.equip
        if mEquipData then
            oPlayer:SyncEquipData(mEquipData)
        end
        oPlayer:UpdateEquipShare()
        oPlayer:ActivePropChange()
    end
end

function CItemCtrl:C2GSSaveFuWen(iPos)
    local iPid = self:GetInfo("pid")
    local oWorldMgr = global.oWorldMgr
    local mData = {
        pid = iPid,
        pos = iPos
    }

    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer.m_oItemCtrl:SaveFuWenCallback(oPlayer,mData)
    end
    interactive.Request(self.m_iRemoteAddr,"item","C2GSSaveFuWen",mData,fCallback)
end

function CItemCtrl:SaveFuWenCallback(oPlayer,mData)
    local mArgs = mData.args or {}
    local mEquipData = mArgs.equip
    if mEquipData then
        oPlayer:SyncEquipData(mEquipData)
    end
    oPlayer:UpdateEquipShare()
    oPlayer:ActivePropChange()
end

function CItemCtrl:C2GSUseFuWenPlan()
    local iPid = self:GetInfo("pid")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mData = {
        pid = iPid,
        pos = iPos,
        grade = oPlayer:GetGrade(),
    }

    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer.m_oItemCtrl:UseFuWenPlanCallback(oPlayer,mData)
    end
    interactive.Request(self.m_iRemoteAddr,"item","C2GSUseFuWenPlan",mData,fCallback)
end

function CItemCtrl:UseFuWenPlanCallback(oPlayer,mData)
    local bSuc = mData.success
    if not bSuc then
        return
    end
    oPlayer:UpdateEquipShare()
    oPlayer:ActivePropChange()
end

function CItemCtrl:GetItemCompoundCost(sid, iUpgrade)
    local res = require "base.res"
    local mUseTbl = res["daobiao"]["compound"]
    if iUpgrade > 0 then
        return mUseTbl[sid]["upgrade_coin"]
    end
    return mUseTbl[sid]["cost"]
end

function CItemCtrl:ValidCompoundItem(sid, iUpgrade)
    local oNotifyMgr = global.oNotifyMgr

    local iPid = self:GetPid()
    local res = require "base.res"
    local mData = res["daobiao"]["compound"][sid]
    if not mData then
        oNotifyMgr:Notify(iPid, "合成装备不存在")
        record.warning("ValidCompoundItem not exist, pid:%s, sid:%s, upgrade:%s", iPid, sid, iUpgrade)
        return false
    end
    if iUpgrade > 0 and mData.upgrade_coin <= 0 then
        oNotifyMgr:Notify(iPid, "装备升级失败")
        record.warning("ValidCompoundItem err, pid:%s, sid:%s, upgrade:%s", iPid, sid, iUpgrade)
        return false
    end
    return true
end

function CItemCtrl:C2GSCompoundItem(oPlayer,mData)
    local oWorldMgr = global.oWorldMgr
    local iShape = mData["sid"]
    local iUpgrade = mData["upgrade"]
    if not self:ValidCompoundItem(iShape, iUpgrade) then
        return
    end

    local iPid = self:GetInfo("pid")
    local mArgs = {
        grade = oPlayer:GetGrade()
    }
    local mData = {
        pid = iPid,
        sid = iShape,
        upgrade = iUpgrade,
        args = mArgs,
    }
    local iGold = self:GetItemCompoundCost(iShape, iUpgrade)
    if not oPlayer:ValidCoin(iGold) then
        return
    end
    local iFrozenSession = oPlayer:FrozenMoney("gold",iGold,"道具合成")
     local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        oPlayer.m_oItemCtrl:CompundItemCallback(oPlayer,mData,iFrozenSession)
    end
    interactive.Request(self.m_iRemoteAddr,"item","C2GSCompoundItem",mData,fCallback)
end

function CItemCtrl:CompundItemCallback(oPlayer,mData,iFrozenSession)
    local bSuc = mData.success
    local mArgs = mData.args or {}
    local oProfile = oPlayer:GetProfile()
    if not bSuc then
        oProfile:UnFrozenMoney(iFrozenSession)
    else
        local mData = oProfile:UnFrozenMoney(iFrozenSession)
        local sType,iGold,sReason = table.unpack(mData)
        oPlayer:ResumeCoin(iGold,sReason)
        oPlayer:UpdateEquipShare()
        oPlayer:SyncEquipData(mArgs.equip)
        oPlayer:ActivePropChange()
    end
end

function CItemCtrl:GetItemLink(oPlayer,iItemId,fCallback)
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetInfo("pid")
    local mData = {
        pid = iPid,
        itemid = iItemId,
    }
    interactive.Request(self.m_iRemoteAddr,"item","GetItemLink",mData,fCallback)
end

function CItemCtrl:C2GSDeCompose(oPlayer,mInfo)
    local iPid = self:GetInfo("pid")
    local mData = {
        info = mInfo,
    }
    self:Forward("C2GSDeCompose",iPid,mData)
end

function CItemCtrl:C2GSLockEquip(iItemId,iPos)
    local iPid = self:GetInfo("pid")
    local mData = {
        itemid= iItemId,
        pos = iPos
    }
    self:Forward("C2GSLockEquip",iPid,mData)
end

function CItemCtrl:C2GSReNameFuWen(lPlanName)
    local iPid = self:GetInfo("pid")
    local mData = {
        plan_name = lPlanName
    }
    self:Forward("C2GSReNameFuWen",iPid,mData)
end

function CItemCtrl:C2GSChooseItem(mData)
    local iPid = self:GetPid()
    self:Forward("C2GSChooseItem",iPid,mData)
end

function CItemCtrl:SetPlayerInfo(oPlayer,key,value)
    local iPid = self:GetInfo("pid")
    interactive.Send(self.m_iRemoteAddr, "common", "SetPlayerInfo", {
        pid = iPid,
        key = key,
        value = value
    })
end

function CItemCtrl:GetEquipList(oPlayer,fCallback)
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetInfo("pid")
    local mData = {
        pid = iPid,
    }
    interactive.Request(self.m_iRemoteAddr,"item","GetEquipList",mData,fCallback)
end

function CItemCtrl:GetEquipLinkList(oPlayer,fCallback)
    local oWorldMgr = global.oWorldMgr
    local iPid = self:GetInfo("pid")
    local mData = {
        pid = iPid,
    }
    interactive.Request(self.m_iRemoteAddr,"item","GetEquipLinkList",mData,fCallback)
end

function CItemCtrl:GetShapeGrid(iType,iShape)
    return self.m_oItemShareObj:GetShapeGrid(iType,iShape)
end

function CItemCtrl:SpaceGridSize(iType)
    -- local mGridSize = self.m_oItemShareObj:SpaceGridSize(iType)
    -- local iSize = 0
    -- for iShape,iGridSize in pairs(mGridSize) do
    --     iSize = iSize + iGridSize
    -- end
    -- return MAX_GRID_SIZE - iSize
end

function CItemCtrl:ShowWarEndUI(mData)
    interactive.Send(self.m_iRemoteAddr, "common", "ShowWarEndUI", {
        pid =self:GetPid(),
        data = mData,
        })
end

function CItemCtrl:GetShowItem(fCallback)
    local iPid = self:GetPid()
    local mShowInfo = global.oUIMgr:PackKeepItem(iPid)
    interactive.Request(self.m_iRemoteAddr, "common", "GetShowItem", {
        pid = iPid,
        data = mShowInfo
        }, fCallback)
end




CContainer = {}
CContainer.__index = CContainer
inherit(CContainer, datactrl.CDataCtrl)

function CContainer:New(iPid, iType, iMaxSize)
    local o = super(CContainer).New(self, {pid = iPid})
    o.m_iMaxGridSize = iMaxSize
    o.m_iType = iType
    return o
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

--ItemList:{iSid, iAmount, bBind}
function CContainer:ValidGive(ItemList,mArgs)
    local iType = self.m_iType
    local iNeedSpace = 0
    local oItemCtrl = self.m_Container

    for _, mItem in pairs(ItemList) do
        local sid, iAmount, bBind = table.unpack(mItem)
        local oItem = loaditem.GetItem(sid)
        local iShape = oItem:SID()
        local iHaveAmount = oItemCtrl:GetItemAmount(iShape)

        local iMaxAmount = oItem:GetMaxAmount()
        local iHaveSpace = oItemCtrl:GetShapeGrid(self.m_iType,iShape)
        local iCanAddAmount = iHaveSpace * iMaxAmount - iHaveAmount

        local iItemAmount = iAmount - iCanAddAmount
        if iItemAmount > 0 then
            local iSize = iItemAmount // iMaxAmount + 1
            if iItemAmount % iMaxAmount == 0 then
                iSize = iItemAmount // iMaxAmount
            end
            iNeedSpace = iNeedSpace + iSize
        end
    end
    if self:SpaceGridSize() < iNeedSpace then
        if not mArgs.cancel_tip then
            global.oNotifyMgr:Notify(self:GetPid(), self:GetTips())
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
        local iHave = self.m_Container:GetItemAmount(iShape)
        local oItem = loaditem.GetItem(iShape)
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

function CContainer:SpaceGridSize()
    local mGridSize = self.m_Container.m_oItemShareObj:SpaceGridSize(self.m_iType)
    local iSize = 0
    for iShape,iGridSize in pairs(mGridSize) do
        iSize = iSize + iGridSize
    end
    return math.max(0, self.m_iMaxGridSize - iSize)
end

CItemShareObj = {}
CItemShareObj.__index = CItemShareObj
inherit(CItemShareObj, shareobj.CShareReader)

function CItemShareObj:New()
    local o = super(CItemShareObj).New(self)
    o.m_mShapeAmount = {}
    o.m_mSpace = {}
    return o
end

function CItemShareObj:Unpack(m)
    self.m_mShapeAmount = m.shape_amount or {}
    self.m_mSpace = m.space or {}
end

function CItemShareObj:GetItemAmount(iShape)
    self:Update()
    local oItem = loaditem.GetItem(iShape)
    assert(oItem, string.format("item sid err:%s", iShape))
    local iType = oItem:Type()
    local mContainerItem = self.m_mShapeAmount[iType] or {}
    return mContainerItem[iShape] or 0
end

function CItemShareObj:GetShapeGrid(iType,iShape)
    local mContainerSpace = self.m_mSpace[iType] or {}
    return mContainerSpace[iShape] or 0
end

function CItemShareObj:SpaceGridSize(iType)
    return self.m_mSpace[iType] or {}
end

function CItemShareObj:GetAllItemAmount()
    local mShape = {}
    self:Update()
    for iType,mContainerShape in pairs(self.m_mShapeAmount) do
        for iShape,iAmount in pairs(mContainerShape) do
            mShape[iShape] = iAmount
        end
    end
    return mShape
end