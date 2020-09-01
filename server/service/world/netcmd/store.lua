local global = require "global"
local skynet = require "skynet"
local record = require "public.record"

local loaditem = import(service_path("item.loaditem"))
local gamedefines = import(lualib_path("public.gamedefines"))
local defines = import(service_path("store.defines"))
local COIN_FLAG = gamedefines.COIN_FLAG


function C2GSOpenShop(oPlayer,mData)
    local oStoreMgr = global.oStoreMgr
    local oNotifyMgr = global.oNotifyMgr
    if oStoreMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"玩法暂时关闭，敬请期待")
        return
    end

    local oShop= oStoreMgr:GetShop(mData.shop_id)

    if oShop then
        oShop:CheckRefreshGoods(oPlayer)
        oPlayer:Send("GS2CNpcStoreInfo",oShop:PackShop(oPlayer))
    else
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告")
    end
end

function C2GSExchangeGold(oPlayer, mData)
    local oStoreMgr = global.oStoreMgr
    local oNotifyMgr = global.oNotifyMgr
    if oStoreMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local iStoreItemID = mData["store_itemid"]
    local res = require "base.res"
    local mStoreItem = res["daobiao"]["goldstore"][iStoreItemID]
    if  mStoreItem then
        local oExchange= oStoreMgr:ExChange()
        oExchange:ExchangeMoney(oPlayer,mStoreItem,"gold")
    else
        global.oNotifyMgr:Notify(oPlayer:GetPid(), "购买物品不存在")
    end
end

function C2GSExchangeTrapminePoint(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    if global.oWorldMgr:IsClose("trapmine") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local res = require "base.res"
    local mGlobalData = res["daobiao"]["global"]["daily_buy_trapmine_point"]
    local iDailyMax = tonumber(mGlobalData.value)
    local iTodayBuy = oPlayer.m_oToday:Query("trapmine_point_bought", 0)
    if iTodayBuy >= iDailyMax then
        oNotifyMgr:Notify(oPlayer:GetPid(), "今日探索点购买已达上限，请明天再来尝试。")
        return
    end
    local iBuyAmount = mData.amount
    if iBuyAmount <= 0 then
        record.info("C2GSExchangeTrapminePoint err, pid:%s", oPlayer:GetPid())
        return
    end
    if iTodayBuy + iBuyAmount > iDailyMax then
        oNotifyMgr:Notify(oPlayer:GetPid(), "超出可购买上限。")
        return
    end
    local iAdd = math.min(iBuyAmount, math.max(0, 50 - iTodayBuy))
    local iCost = (iBuyAmount - iAdd) * 2 + iAdd * 1
    if oPlayer:ValidGoldCoin(iCost) then
        oPlayer:ResumeGoldCoin(iCost, "购买探索点", {cancel_tip = 1})
        oPlayer:RewardTrapminePoint(iBuyAmount, "购买探索点")
        oPlayer.m_oToday:Add("trapmine_point_bought", iBuyAmount)
        oPlayer:GS2CTodayInfo({"trapmine_point_bought"})
    end
end


function C2GSNpcStoreBuy(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local iStoreItemID = mData.buy_id
    local oStoreMgr = global.oStoreMgr
    local mStoreItem= oStoreMgr:GetItem(iStoreItemID)
    local oShop= oStoreMgr:GetShop(mStoreItem.shop_id)
    if not oShop then
        return
    end
    if oStoreMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    oShop:BuyItem(oPlayer,mData)
end

function C2GSOpenGold2Coin(oPlayer,mData)
    local oStoreMgr = global.oStoreMgr
    local oNotifyMgr = global.oNotifyMgr
    local iType = mData.type
    if oStoreMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local oExchange= oStoreMgr:ExChange()
    oExchange:OpenExchangeMain(oPlayer, iType)
end

function C2GSGold2Coin(oPlayer,mData)
    local iGold = mData.val
    local iRatio = mData.ratio
    local iType = mData.type
    local oStoreMgr = global.oStoreMgr
    local oNotifyMgr = global.oNotifyMgr
    if oStoreMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        oPlayer:Send("GS2CGold2Coin",{result  =1})
        return
    end
    local oExchange= oStoreMgr:ExChange()

    if iType == 1 then
        oExchange:ExChangeGold2Coin(oPlayer,iGold,iRatio)
    elseif iType == 4 then
        oExchange:ExChangeGold2Energy(oPlayer,iGold,iRatio)
    end
end

function C2GSRefreshShop(oPlayer,mData)
    local oStoreMgr = global.oStoreMgr
    local oNotifyMgr = global.oNotifyMgr
    if oStoreMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        oPlayer:Send("GS2CGold2Coin",{result  =1})
        return
    end
    local oShop= oStoreMgr:GetShop(mData.shop_id)
    if not oShop then
        return
    end
    oShop:RefreshShopByCountType(oPlayer)
end


function C2GSStoreBuyList(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local oStoreMgr = global.oStoreMgr
    if oStoreMgr:IsClose() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local lBuyItem = mData["buys"] or {}
    if next(lBuyItem) then
        for _, mBuy in ipairs(lBuyItem) do
            local iStoreItemID = mBuy.buy_id
            local mStoreItem= oStoreMgr:GetItem(iStoreItemID)
            local oShop= oStoreMgr:GetShop(mStoreItem.shop_id)
            if oShop then
                if not oShop:BuyItem(oPlayer,mBuy) then
                    record.warning("C2GSStoreBuyList, pid:%s , iteminfo:%s",oPlayer:GetPid(), ConvertTblToStr(mBuy))
                end
            end
        end
    end
end


function C2GSBuyItemByCoin(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local iCoinType = mData["coin_type"]
    local iItemSid = mData["item_sid"]
    local iAmount = mData["buy_amount"]

    local iPid = oPlayer:GetPid()
    if iAmount <= 0 then
        oNotifyMgr:Notify(iPid, "购买数量需大于0")
        return
    end
    local oItem = loaditem.GetItem(iItemSid)
    if not oItem then
        oNotifyMgr:Notify(iPid, "购买道具不存在")
        return
    end
    local lBuyCost = oItem:GetBuyInfo()
    if #lBuyCost <= 0 then
        oNotifyMgr:Notify(iPid, "道具不可购买")
        return
    end
    local mCost
    for _, m in ipairs(lBuyCost) do
        if iCoinType == m.coin then
            mCost = table_copy(m)
            break
        end
    end
    if not mCost then
        oNotifyMgr:Notify(iPid, "货币类型不存在")
        return
    end
    if mCost.limit < iAmount then
        oNotifyMgr:Notify(iPid, "超出可购买上限")
        return
    end
    local iCostCoin = mCost.cost
    assert(iCostCoin > 0, string.format("C2GSBuyItemByCoin err,item:%s", iItemSid))
    iCostCoin = iCostCoin * iAmount
    if ValidBuyItemByCoin(oPlayer, iCoinType, iCostCoin) then
        local lGive = {{iItemSid, iAmount}}
        local sReason = "购买道具"
        if oPlayer:ValidGive(lGive) and CostBuyItemCoin(oPlayer, iCoinType, iCostCoin, sReason) then
            oPlayer:GiveItem(lGive, sReason, {cancel_show=1})
        end
    end
end

function ValidBuyItemByCoin(oPlayer, iCoinType, iVal)
    if iCoinType == COIN_FLAG.COIN_COIN then
        return oPlayer:ValidCoin(iVal)
    elseif iCoinType == COIN_FLAG.COIN_GOLD then
        return oPlayer:ValidGoldCoin(iVal)
    end
    record.error("ValidBuyItemByCoin err, coin type:%s", iCoinType)
    return false
end

function CostBuyItemCoin(oPlayer, iCoinType, iVal, sReason)
    if iCoinType == COIN_FLAG.COIN_COIN then
        oPlayer:ResumeCoin(iVal, sReason, {})
        return true
    elseif iCoinType ==  COIN_FLAG.COIN_GOLD then
        oPlayer:ResumeGoldCoin(iVal, sReason, {})
        return true
    end
    record.error("CostBuyItemCoin err, coin type:%s", iCoinType)
    return false
end