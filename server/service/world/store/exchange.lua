--货币兑换

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"
local res = require "base.res"

local gamedefines = import(lualib_path("public.gamedefines"))

local defines = import(service_path("store.defines"))

function NewExchange()
    return CExchange:New()
end

CExchange={}
CExchange.__index=CExchange
inherit(CExchange,logic_base_cls())

function CExchange:New()
    local o = super(CExchange).New(self)
    return o
end

function CExchange:ExchangeMoney(oPlayer,mStoreItem,sType)
    if not mStoreItem then
        global.oNotifyMgr:Notify(oPlayer:GetPid(), "购买物品不存在")
        return
    end
    local iCoinCost = mStoreItem.gold_coin_cost
    if  not iCoinCost or iCoinCost<=0 then
        return
    end
    if sType=="gold" then
        self:ExchangeGold(oPlayer,mStoreItem)
    end
end

function CExchange:ExchangeGold(oPlayer,mStoreItem)
    local iCoinCost = mStoreItem.gold_coin_cost
    if not oPlayer:ValidGoldCoin(iCoinCost,"水晶不足")  then
        return
    end
    oPlayer:ResumeGoldCoin(iCoinCost, "金币商城兑换")
    oPlayer:RewardCoin(iCoinCost, "金币商城兑换")
 end


function CExchange:ExChangeGold2Coin(oPlayer,iUse,iGoldRatio)
    local iRatio = defines.GOLD_COIN_RATIO
    local oNotify = global.oNotifyMgr
    if iRatio ~= iGoldRatio then
        oNotify:Notify(oPlayer:GetPid(), "兑换比例发生变化")
        return
    end
    local iExchangeCoin = iUse * iRatio
    local iRemainExtra = self:GetRemainExtra(oPlayer, 1)
    if iRemainExtra > 0 then
        local iCnt = math.min(iRemainExtra, iUse)
        iExchangeCoin = iExchangeCoin + math.floor(iCnt * iRatio * 0.5)
        local m = self:GetGold2CoinDailyBuy(oPlayer)
        m.use_extra = m.use_extra + iCnt
        self:SetGold2CoinDailyBuy(oPlayer, m)
    end
    if not oPlayer:IsOverflowCoin(gamedefines.COIN_FLAG.COIN_COIN,oPlayer:Coin()+iExchangeCoin) then
        oNotify:Notify(oPlayer:GetPid(), "由于您所持金币超出了上限，兑换失败。")
        return
    elseif not oPlayer:ValidGoldCoin(iUse, "水晶不足") then
        return
    end
    local mLog = {
    source_type = "gold",
    target_type = "coin",
    ratio = iRatio,
    source_val = iUse,
    target_val = iExchangeCoin,
    pid = oPlayer:GetPid(),
    remain_extra = self:GetRemainExtra(oPlayer, 1),
    max_extra = self:GetMaxExtra(oPlayer, 1),
    }
    record.user("shop","exchange",mLog)
    oPlayer:ResumeGoldCoin(iUse,"金币兑换")
    oPlayer:RewardCoin(iExchangeCoin, "金币兑换")
    oPlayer:AddSchedule("buygoldcoin")
    self:OpenExchangeMain(oPlayer, 1)
end

function CExchange:ExChangeColor2Coin(oPlayer,iUse,iGoldRatio)
    local iRatio = defines.COLOR_COIN_RATIO
    local iExchangeCoin = iUse * iRatio
    local oNotify = global.oNotifyMgr
    if iRatio ~= iGoldRatio then
        oNotify:Notify(oPlayer:GetPid(), "兑换比例发生变化")
        return
    end
    if not oPlayer:IsOverflowCoin(gamedefines.COIN_FLAG.COIN_COIN,oPlayer:Coin()+iExchangeCoin) then
        oNotify:Notify(oPlayer:GetPid(), "由于您所持金币超出了上限，兑换失败。")
        return
    elseif not oPlayer:ValidColorCoin(iUse, "彩晶不足") then
        return
    end
    local mLog = {
    source_type = "color",
    target_type = "coin",
    ratio = iRatio,
    source_val = iUse,
    target_val = iExchangeCoin,
    remain_extra = 0,
    max_extra = 0,
    }
    record.user("shop","exchange",mLog)
    oPlayer:ResumeColorCoin(iUse,"金币兑换")
    oPlayer:RewardCoin(iExchangeCoin, "金币兑换")
    oPlayer:AddSchedule("buygoldcoin")
end

function CExchange:ExChangeColor2Gold(oPlayer,iUse,iGoldRatio)
    local iRatio = defines.COLOR_GOLD_RATIO
    local iExchangeCoin = iUse * iRatio
    local oNotify = global.oNotifyMgr
    if iRatio ~= iGoldRatio then
        oNotify:Notify(oPlayer:GetPid(), "兑换比例发生变化")
        return
    end
    if not oPlayer:IsOverflowCoin(gamedefines.COIN_FLAG.COIN_GOLD,oPlayer:GoldCoin()+iExchangeCoin) then
        oNotify:Notify(oPlayer:GetPid(), "由于您所持金币超出了上限，兑换失败。")
        return
    elseif not oPlayer:ValidColorCoin(iUse, "彩晶不足") then
        return
    end
    local mLog = {
    source_type = "color",
    target_type = "gold",
    ratio = iRatio,
    source_val = iUse,
    target_val = iExchangeCoin,
    remain_extra = 0,
    max_extra = 0,
    }
    record.user("shop","exchange",mLog)
    oPlayer:ResumeColorCoin(iUse,"水晶兑换")
    oPlayer:RewardGoldCoin(iExchangeCoin, "水晶兑换")
end

function CExchange:GetMaxEnergyBuyTime()
    local sValue = res["daobiao"]["global"]["buyenergy_maxtime"]["value"]
    return tonumber(sValue)
end

function CExchange:GetBuyEnergyBaseCost()
    local sValue = res["daobiao"]["global"]["buyenergy_cost"]["value"]
    return tonumber(sValue)
end

function CExchange:GetBuyEnergyTotalCost(iBuyTime,iDoneTime)
    local sValue = res["daobiao"]["global"]["buyenergy_rate"]["value"]
    local m = split_string(sValue,",")
    local iTotalCost = 0
    for i=1,iBuyTime do
        iTotalCost = iTotalCost + tonumber((m[iDoneTime+i] or m[#m]))
    end
    return iTotalCost
end

function CExchange:GetBuyEnergyValue()
    local sValue = res["daobiao"]["global"]["buyenergy_value"]["value"]
    return tonumber(sValue)
end

function CExchange:GetEnergyRatio()
    local iValue = self:GetBuyEnergyValue()
    local iCost = self:GetBuyEnergyBaseCost()
    if iValue == 0 or iCost == 0 then
        record.warning(string.format("liuwei-debug:GetEnergyRatio falied,%d,%d",iValue,iCost))
        return 1
    end
    return iCost/iValue
end

function CExchange:ExChangeGold2Energy(oPlayer,iUse,iGoldRatio)
    -- body
    local iRatio = defines.GLOD_ENERGY_RATIO
    local iPerCost = self:GetBuyEnergyBaseCost()
    local iBuyTime = math.floor(iUse/iPerCost)
    local iDoneTime = oPlayer.m_oToday:Query("energy_buytime",0)
    local iMaxBuyTime = self:GetMaxEnergyBuyTime()
    if (iDoneTime + iBuyTime) > iMaxBuyTime then
        global.oNotifyMgr:Notify(oPlayer.m_iPid,"今日兑换次数已达上限")
        return
    end
    if iBuyTime > 0 then
        local iTotalCost = self:GetBuyEnergyTotalCost(iBuyTime,iDoneTime)
        if not oPlayer:ValidGoldCoin(iTotalCost) then
            return
        end
        local iTotalAdd = self:GetBuyEnergyValue() * iBuyTime
        oPlayer:ResumeGoldCoin(iTotalCost,string.format("购买%d体力",iTotalAdd))
        oPlayer:RewardEnergy(iTotalAdd,"购买体力")
        oPlayer.m_oToday:Set("energy_buytime",iDoneTime + iBuyTime)
        oPlayer:GS2CTodayInfo({"energy_buytime"})
        oPlayer:Send("GS2CGold2Coin",{result = 1})
    end
end

function CExchange:GetRatioByType(iType)
    local iRatio = 0
    if iType == 1 then
        iRatio = defines.GOLD_COIN_RATIO
    elseif iType == 4 then
        iRatio = self:GetEnergyRatio()
    end
    return iRatio
end

function CExchange:GetGold2CoinDailyBuy(oPlayer)
    local m = oPlayer.m_oToday:Query("gold2coin")
    if not m then
        m = {}
        local mData = self:GetGold2CoinData(oPlayer:GetGrade())
        m.max_extra = mData.daily_amount
        m.use_extra = 0
        self:SetGold2CoinDailyBuy(oPlayer, m)
    end
    return m
end

function CExchange:GetGold2CoinData(iGrade)
    local mData = res["daobiao"]["gold2coin"]
    local iMinDist
    local l = table_key_list(mData)
    local iMaxGrade = math.max(table.unpack(l))
    if iGrade >= iMaxGrade then
        iMinDist = iMaxGrade
    else
        for _, m in pairs(mData) do
            if m.grade >= iGrade then
                iMinDist = iMinDist or m.grade
                if (m.grade - iGrade) < (iMinDist - iGrade)  then
                    iMinDist = m.grade
                end
            end
        end
    end
    return mData[iMinDist]
end

function CExchange:SetGold2CoinDailyBuy(oPlayer, mBuy)
    oPlayer.m_oToday:Set("gold2coin", mBuy)
end

function CExchange:GetMaxExtra(oPlayer, iType)
    local iMax = 0
    if iType == 1 then
        local m = self:GetGold2CoinDailyBuy(oPlayer)
        iMax = m.max_extra
    end
    return iMax
end

function CExchange:GetRemainExtra(oPlayer, iType)
    local iRemain = 0
    if iType == 1 then
        local m = self:GetGold2CoinDailyBuy(oPlayer)
        iRemain = math.max(0, m.max_extra - m.use_extra)
    end
    return iRemain
end

function CExchange:OpenExchangeMain(oPlayer, iType)
    local mNet = {}
    mNet.type = iType
    mNet.ratio = self:GetRatioByType(iType) * 100
    mNet.max_extra = self:GetMaxExtra(oPlayer, iType)
    mNet.remain_extra = self:GetRemainExtra(oPlayer, iType)
    oPlayer:Send("GS2COpenGold2Coin", mNet)
end



