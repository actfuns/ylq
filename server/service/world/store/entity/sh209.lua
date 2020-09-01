--import module

local global = require "global"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

local analy = import(lualib_path("public.dataanaly"))
local baseshop = import(service_path("store.shop"))
local loaditem = import(service_path("item.loaditem"))

CShop = {}
CShop.__index = CShop
CShop.m_ID=209
inherit(CShop, baseshop.CShop)


function NewShop()
    return CShop:New()
end

function CShop:BuyItem(oPlayer,mData)
    local iPos = mData.pos
    local mItem=global.oStoreMgr:GetItem(mData.buy_id)
    local iNeed=mData.buy_count
    local iPrice,sPrice=self:CallPrice(oPlayer,mItem)
    local iCostVal=iPrice*iNeed
    local iPid = oPlayer:GetPid()
    if not self:ValidBuyItem(oPlayer,mItem,mData) then
        return false
    end
    self:CheckRefreshGoods(oPlayer,{cost_type=sPrice})
    local mArgs = {
        pid = oPlayer:GetPid(),
        cost = iCostVal,
        reason = "npc商城购买",
    }

    interactive.Request(".org", "common", "ResumeOrgCash", mArgs,function (mRecord, mData2)
        if mData2.suc then
            local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                self:BuyItem2(oPlayer,mData,iPrice,sPrice,iCostVal,mData2)
            end
        end
    end)
end

function CShop:BuyItem2(oPlayer,mData,iPrice,sPrice,iCostVal,mOrg)
    local iPos = mData.pos
    local mItem=global.oStoreMgr:GetItem(mData.buy_id)
    local iNeed=mData.buy_count
    local iOldGoldCoin = oPlayer:GoldCoin()

    local sReason = "npc商城购买"

    self:ConsumeAmount(oPlayer,mItem,iNeed,iPos)
    local lGive = {
        {mItem.item_id,iNeed,false},
    }
    local mLog= {
        pid = oPlayer:GetPid(),
        amount = iNeed,
        cost = iCostVal,
        shop_id = self.m_ID,
        item = mData.buy_id,
        item_id = mItem.item_id,
        coin_type = sPrice,
        reason = sReason,
        rebate = self:GetRebate(oPlayer,mItem),
    }
    record.user("shop","buy_item",mLog)

    local mMem = mOrg.memlist
    local iRemainCash = mOrg.remain_cash
    self:OnGiveItem(oPlayer,mMem,lGive,mItem,mData,sReason)

    local mNet = self:PackItem(oPlayer,mData.buy_id,iPos)
    if mNet then
        oPlayer:Send("GS2CStoreRefresh",{shop_id= self.m_ID,goodsInfo=mNet})
    end
    self:NotifyBuy(oPlayer,sPrice,iCostVal,lGive,mItem)

    local mLog = oPlayer:GetPubAnalyData()
    mLog["crystal_before"] = iOldGoldCoin
    if mItem.coin_typ == gamedefines.COIN_FLAG.COIN_GOLD then
        mLog["consume_crystal"] = iCostVal
    else
        mLog["consume_crystal"] = 0
    end
    mLog["crystal_bd_before"] = 0
    mLog["consume_crystal_bd"] = 0
    mLog["currency_type"] = mItem.coin_typ
    mLog["shop_id"] = self.m_ID
    mLog["shop_sub_id"] = 1
    mLog["item_id"] = mItem.item_id
    mLog["price"] = iPrice
    mLog["num"] = iNeed
    mLog["consume_count"] = iCostVal
    mLog["remain_currency"] = iRemainCash
    analy.log_data("MallBuy",mLog)
    return true
end

function CShop:OnGiveItem(oPlayer,mMem,lGive,mItem,mData,sReason)
    local oMailMgr = global.oMailMgr
    local oOrgMgr = global.oOrgMgr
    local mArgs = {}
    for _,iPid in pairs(mMem) do
        local mRewardItem = {}
        for _,mItem in pairs(lGive) do
            local iShape,iAmount,iBind = table.unpack(mItem)
            local oItem = loaditem.Create(iShape)
            oItem:SetAmount(iAmount)
            table.insert(mRewardItem,oItem)
            table.insert(mArgs,string.format("%s个%s",iAmount,oItem:Name()))
        end
        local mData,sName = oMailMgr:GetMailInfo(17)
        oMailMgr:SendMail(0,sName,iPid,mData,{},mRewardItem,{})
    end

    local mArgs = {}
    for _,mItem in pairs(lGive) do
        local iShape,iAmount,iBind = table.unpack(mItem)
        local oItem = loaditem.Create(iShape)
        table.insert(mArgs,string.format("%s个%s",iAmount,oItem:Name()))
    end
    local sLog = table.concat(mArgs,", ")
    local sText = oOrgMgr:GetOrgLog(1015,{rolename = oPlayer:GetName(),fuli = sLog})

    interactive.Send(".org", "common", "AddLog", {
        pid = oPlayer:GetPid(),
        text = sText,
    })
end

function CShop:GetCoinRest(oPlayer, sPrice)
end