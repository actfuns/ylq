--商店定义

local global = require "global"
local skynet = require "skynet"
local record = require "public.record"
local extend = require "base.extend"
local colorstring = require "public.colorstring"

local gamedefines = import(lualib_path("public.gamedefines"))

local analy = import(lualib_path("public.dataanaly"))
local defines = import(service_path("store.defines"))
local loaditem = import(service_path("item.loaditem"))
local loadpartner = import(service_path("partner/loadpartner"))
local itemdefines = import(service_path("item/itemdefines"))

CShop={}
CShop.__index=CShop
inherit(CShop,logic_base_cls())

function CShop:Amount(oPlayer,mItem,iPos)
    local sType = mItem.cycle_type
    local iAmount = mItem.item_count
    if #mItem.cycle_type==0 then
        return -1
    end
    if #sType > 0 then
        local sKey = "GoodsKey"
        iAmount = 0
        local oCtrl = oPlayer[defines.LIMIT_TYPE[sType]]
        if oCtrl then
            local iBuy = oCtrl:Query(sKey,{})[mItem["id"]] or 0
            iAmount= mItem.item_count - (oCtrl:Query(sKey,{})[mItem["id"]] or 0)
        end
        if iAmount < 0 then
            iAmount = 0
        end
    end
    return iAmount
end


function CShop:ResetShopAmount(oPlayer)
    local sKey = "GoodsKey"
    local oStore=global.oStoreMgr
    local mGoods= self:GetShopGoods(oPlayer)
    for _,iItem in pairs(mGoods) do
        local mItem = oStore:GetItem(iItem)
        if  mItem and mItem.cycle_type ~= "" then
            local oCtrl = oPlayer[defines.LIMIT_TYPE[mItem.cycle_type]]
            if oCtrl then
                local mShop = oCtrl:Query(sKey,{})
                mShop[mItem["id"]] = nil
                oCtrl:Set(sKey,mShop)
            end
        end
    end
    oPlayer:Send("GS2CNpcStoreInfo",self:PackShop(oPlayer))
end


function CShop:CallPrice(oPlayer,mItem)
    local iPrice=mItem.coin_count
    local sPrice=gamedefines.COIN_TYPE[mItem["coin_typ"]].type
    if self:InRebateTime(oPlayer,mItem) then
        iPrice=math.ceil(iPrice*self:GetRebate(oPlayer,mItem)/100)
    end
    return iPrice,sPrice
end



function CShop:InRebateTime(oPlayer,mItem)
    if mItem["rebate"] <= 0 then
        return false
    end
    local iStart,iEnd = mItem.rebate_time["start"],mItem.rebate_time["over"]
    if not (iStart and iEnd) then
        return false
    end
    local oWorldMgr = global.oWorldMgr
    local iNow = oWorldMgr:GetNowTime()
    return iNow >= iStart and iNow <= iEnd
end

function CShop:GetRebate(oPlayer,mItem)
    local iRebate=0
    if self:InRebateTime(oPlayer,mItem) then
        iRebate=mItem["rebate"]
    end
    return iRebate
end


function CShop:RMBPlay(oPlayer,sid,bNoRefresh)
    local mData = {
        pos = 1,
        buy_count = 1,
        buy_id = sid,
    }
    local iPos = mData.pos
    local mItem=global.oStoreMgr:GetItem(sid)
    local sReason = "充值购买"

    local fConsumeAmount= function (oPlayer,mItem,iConsume,iPos)
            local sType=mItem.cycle_type
            if #sType ==0 then
                return
            end
            local oCtrl = oPlayer[defines.LIMIT_TYPE[sType]]
            local sid = mItem["id"]
            --保存已购买的次数
            local sKey="GoodsKey"
            local mData = oCtrl:Query(sKey,{})

            local iUse = oCtrl:Query(sKey,{})[sid] or 0
            local iBuy = iUse+iConsume
            local mData = oCtrl:Query(sKey,{})
            mData[sid] = iBuy
            oCtrl:Set(sKey,mData)
    end

    fConsumeAmount(oPlayer,mItem,1,1)
    local lGive = {
        {mItem.item_id,1,false},
    }

    local mLog= {
        amount = 1,
        cost = 0,
        shop_id = self.m_ID,
        item = mData.buy_id,
        item_id = mItem.item_id,
        coin_type = "0",
        rebate = self:GetRebate(oPlayer,mItem),
        reason = sReason,
        pid = oPlayer:GetPid(),
    }
    record.user("shop","buy_item",mLog)

    self:OnGiveItem(oPlayer,lGive,mItem,mData,sReason)
    if not bNoRefresh then
        oPlayer:Send("GS2CNpcStoreInfo",self:PackShop(oPlayer))
    end
    --self:NotifyBuy(oPlayer,"",0,lGive,mItem)
    local oItem = loaditem.GetItem(mItem.item_id)
    local sText = loaditem.FormatItemColor(oItem:Quality(),"获得%s")
    local sMessage = string.format(sText,string.format("[%s] x %s",oItem:Name(), 1))
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(oPlayer:GetPid(),sMessage)
    global.oChatMgr:HandleMsgChat(oPlayer, sMessage)
end

function CShop:BuyItem(oPlayer,mData)
    local iPos = mData.pos
    local mItem=global.oStoreMgr:GetItem(mData.buy_id)
    local iNeed=mData.buy_count
    local iPrice,sPrice=self:CallPrice(oPlayer,mItem)
    local iCostVal=iPrice*iNeed
    self:CheckRefreshGoods(oPlayer,{cost_type=sPrice})
    if not self:ValidBuyItem(oPlayer,mItem,mData) then
        return false
    end
    local iOldGoldCoin = oPlayer:GoldCoin()
    local sReason = "npc商城购买"
    self:ConsumeAmount(oPlayer,mItem,iNeed,iPos)
    self:OnCostGoods(oPlayer,iCostVal,sPrice,sReason)

    local lGive = {
        {mItem.item_id,iNeed,false},
    }

    local mLog= {
        amount = iNeed,
        cost = iCostVal,
        shop_id = self.m_ID,
        item = mData.buy_id,
        item_id = mItem.item_id,
        coin_type = sPrice,
        rebate = self:GetRebate(oPlayer,mItem),
        reason = sReason,
        pid = oPlayer:GetPid(),
    }
    record.user("shop","buy_item",mLog)
    self:OnGiveItem(oPlayer,lGive,mItem,mData,sReason)
    local mNet = self:PackItem(oPlayer,mData.buy_id,iPos)
    if mNet then
        oPlayer:Send("GS2CStoreRefresh",{shop_id= self.m_ID,goodsInfo=mNet})
    end
    self:NotifyBuy(oPlayer,sPrice,iCostVal,lGive,mItem)
    oPlayer:PushAchieve("购买商品", {value = 1})

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
    mLog["remain_currency"] = self:GetCoinRest(oPlayer,sPrice)
    analy.log_data("MallBuy",mLog)
    return true
end

function CShop:OnGiveItem(oPlayer,lGive,mItem,mData,sReason)
    local mArgs = {
        cancel_tip = true,
        cancel_channel = true,
        cancel_show = true,
    }
    if mItem.item_id == 1010 then
        local iNeed = mData.buy_count
        local sItem = string.format("%d(%s,value=%d)",mItem.item_id,mItem.item_arg,iNeed)
        local oItem = loaditem.ExtCreate(sItem)
        oPlayer:RewardItem(oItem,sReason,mArgs)
    elseif mItem.item_id == 1017 then
        local iNeed = mData.buy_count
        local sItem = string.format("%d(value=%d)",mItem.item_id,iNeed)
        local oItem = loaditem.ExtCreate(sItem)
        oPlayer:RewardItem(oItem,sReason,mArgs)
    else
        oPlayer:GiveItem(lGive, sReason,mArgs)
    end
end

function CShop:IsPartnerItem(iSid)
    if iSid > 20001 and iSid < 29999 then
        return true
    end
    return false
end

function CShop:GetVipLevel(oPlayer)
    if oPlayer:IsZskVip() or oPlayer:IsMonthCardVip() then
        return 1
    end
    return 0
end

function CShop:ValidBuyItem(oPlayer,mItem,mData)
    local iNeed=mData.buy_count
    local iPos = mData.pos
    local iAmount=self:Amount(oPlayer,mItem,iPos)
    local iPrice,sPrice=self:CallPrice(oPlayer,mItem)
    local iCostVal=iPrice*iNeed
    local oNotifyMgr = global.oNotifyMgr
    if iNeed<=0 or ( iNeed>iAmount and  iAmount>=0 )then
        oNotifyMgr:Notify(oPlayer:GetPid(), "剩余数量不足!")
        return false
    end
    if self:GetVipLevel(oPlayer) < mItem.vip then
        oNotifyMgr:Notify(oPlayer:GetPid(), "该商品为会员专属,你不能购买")
        return false
    end
    local lGive = {}
    table.insert(lGive,{mItem.item_id,iNeed,false})
    if not self:ValidGiveItem(oPlayer,lGive,mItem,mData) then
        return false
    end

    local iType =mItem.coin_typ
    local mType = gamedefines.COIN_TYPE[iType]
    local sTip = string.format("%s不足，%s失败！",mType.name, mType.tips or "购买")
    if not self:ValidCost(oPlayer,sPrice,iCostVal,{tip=sTip}) then
        return false
    end
    return true
end

function CShop:ValidCost(oPlayer,sType,iCostVal,mArg)
    if sType=="coin" and not oPlayer:ValidCoin(iCostVal, mArg) then
        return false
    elseif sType=="gold" and not oPlayer:ValidGoldCoin(iCostVal,mArg) then
        return false
    elseif sType == "arenamedal" and not oPlayer:ValidArenaMedal(iCostVal,mArg) then
        return false
    elseif sType == "medal" and not oPlayer.m_oActiveCtrl:ValidMedal(iCostVal,mArg) then
        return false
    elseif sType == "orgoffer" and not oPlayer:ValidOrgOffer(iCostVal,{tip = sTip}) then
        return false
    elseif sType == "active" and not oPlayer:ValidActive(iCostVal,mArg) then
        return false
    elseif sType == "skin" and not oPlayer:ValidSkin(iCostVal,mArg) then
        return false
    elseif sType == "travel_score" and not oPlayer:ValidTravelScore(iCostVal, mArg) then
        return false
    end
    return true
end

function CShop:ValidGiveItem(oPlayer,lGive,mItem,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iItemID = mItem.item_id
    local iNeed = mData.buy_count
    if iItemID == 1010 then
        if oPlayer.m_oPartnerCtrl:EmptyPartnerSpace() < iNeed then
            oNotifyMgr:Notify(oPlayer:GetPid(), "已达伙伴数量上限")
            return false
        end
        return true
    else
        if not oPlayer:ValidGive(lGive,{cancel_tip = 1}) then
            oNotifyMgr:Notify(oPlayer:GetPid(), "背包已满！")
            return false
        end
        return true
    end
end

function CShop:ConsumeAmount(oPlayer,mItem,iConsume,iPos)
    local sType=mItem.cycle_type
    if #sType ==0 then
        return
    end
    local oCtrl = oPlayer[defines.LIMIT_TYPE[sType]]
    local sid = mItem["id"]
    --保存已购买的次数
    local sKey="GoodsKey"
    local mData = oCtrl:Query(sKey,{})

    local iUse = oCtrl:Query(sKey,{})[sid] or 0
    local iBuy = iUse+iConsume
    local mData = oCtrl:Query(sKey,{})
    mData[sid] = iBuy
    oCtrl:Set(sKey,mData)
end

function CShop:OnCostGoods(oPlayer,iCostVal,sPrice,sReason)
    local mArgs = {
        cancel_tip = true,
        cancel_channel = true,
    }
    self:ConsumeCoin(oPlayer,iCostVal,sPrice,sReason,mArgs)
end

function CShop:ConsumeCoin(oPlayer,iCostVal,sPrice,sReason,mArgs)
    if sPrice=="coin" then
        oPlayer:ResumeCoin(iCostVal , sReason,mArgs)
    elseif sPrice=="gold" then
        oPlayer:ResumeGoldCoin(iCostVal , sReason,mArgs)
    elseif sPrice == "arenamedal" then
        oPlayer:ResumeArenaMedal(iCostVal,sReason,mArgs)
    elseif sPrice == "medal" then
        oPlayer:ResumeMedal(iCostVal,sReason,mArgs)
    elseif sPrice == "active" then
        oPlayer:ResumeActive(iCostVal,sReason,mArgs)
    elseif sPrice == "orgoffer" then
        oPlayer:ResumeOrgOffer(iCostVal,sReason,mArgs)
    elseif sPrice == "skin" then
        oPlayer:ResumeSkin(iCostVal,sReason,mArgs)
    elseif sPrice == "travel_score" then
        oPlayer:AddTravelScore(-iCostVal,sReason,mArgs)
    else
        assert(false, string.format("shop ConsumeCoin err, type:%s not exist!", sPrice))
    end
end

function CShop:GetCoinRest(oPlayer,sPrice)
    if sPrice=="coin" then
        return oPlayer:Coin()
    elseif sPrice=="gold" then
        return oPlayer:GoldCoin()
    elseif sPrice == "arenamedal" then
        return oPlayer:ArenaMedal()
    elseif sPrice == "medal" then
        return oPlayer:Medal()
    elseif sPrice == "active" then
        return oPlayer:Active()
    elseif sPrice == "orgoffer" then
        return oPlayer:GetOffer()
    elseif sPrice == "skin" then
        return oPlayer:Skin()
    elseif sPrice == "travel_score" then
        return oPlayer:GetTravelScore()
    else
        record.error(string.format("shop GetCoinRest err, type:%s, not exist!", sPrice))
        return 0
    end
end

-- oPlayer can be nil
function CShop:GetShopGoods(oPlayer)
    local oStore=global.oStoreMgr
    return oStore:ShopGoods(self.m_ID) or {}
end

function CShop:PackShop(oPlayer)
    local mGoods= self:GetShopGoods(oPlayer)
    local mPackGoods={}
    for iPos,iItem in pairs(mGoods) do
        local mItemPack = self:PackItem(oPlayer,iItem,iPos)
        if mItemPack then
            table.insert(mPackGoods,mItemPack)
        end
    end
    local mRule = self:GetRule()
    local iRTime = 0
    local iCost = 0
    local iCoinType = 0
    local iCount = 0
    local iRule = 0
    if mRule  then
        if mRule["time"] >0 and #mRule["reset_time"] >0 then
            iRule = 3
        elseif mRule["time"] > 0 then
            iRule = 1
        elseif #mRule["reset_time"] > 0 then
            iRule = 2
        end
        local sKey = string.format("RShop_%d",self.m_ID)
        local iCnt = oPlayer.m_oToday:Query(sKey,0)
        iRTime = oPlayer.m_oThisTemp:QueryLeftTime(sKey)
        if iCnt >= mRule["free"] then
            local mEnv = {
            use = iCnt,
            }
            iCost = formula_string(mRule["cost"], mEnv)
        end
        iCoinType = mRule["coin_type"]
        iCount = math.max(mRule["count"] - iCnt,0)
    end


    local mNet ={
        shop_id = self.m_ID,
        goodslist = mPackGoods,
        refresh_time = iRTime,
        refresh_cost = iCost,
        refresh_coin_type =iCoinType,
        refresh_count = iCount,
        refresh_rule = iRule,
    }
    return mNet
end

function CShop:PackItem(oPlayer,iItem,iPos)
    local oStore=global.oStoreMgr
    local mItem = oStore:GetItem(iItem)
    local iLimit = 0
    if mItem.to_show ==0 then
        return
    end
    if #mItem.cycle_type>0 then
        iLimit = 1
    end
    local mPack={
        item_id = iItem,
        rebate = self:GetRebate(oPlayer,mItem),
        amount = self:Amount(oPlayer,mItem,iPos),
        limit = iLimit,
        pos = iPos,
    }
    return mPack
end

function CShop:NotifyBuy(oPlayer,sPrice,iPrice,lGive,mItem)
    local sMessage = ""

    for iCon,mData in pairs(gamedefines.COIN_TYPE) do
        if sPrice == mData["type"] then
            sMessage = string.format("%s %s",mData.icon or string.format("%s * ", mData.name),iPrice)
            sMessage = colorstring.FormatColorString("你消耗了#resume",{resume = sMessage})
            break
        end
    end

    local mItemData = {}
    for _,mInfo in pairs(lGive) do
        local iShape,iAmount,iBind = table.unpack(mInfo)
        -- local sName = ""
        local sMsg = ""
        if self:IsPartnerItem(iShape) then
            local mItemData = itemdefines.GetItemData(iShape)
            local sText = loaditem.FormatItemColor(mItemData.quality,",获得%s")
            sMsg = string.format(sText,string.format("[%s] x %s",mItemData.name, iAmount))
        else
            if iShape == 1010 then
                local sItem = string.format("%d(%s)",mItem.item_id,mItem.item_arg)
                local oItem = loaditem.GetItem(sItem)
                local iPartner = oItem:GetData("partner")
                local mData = loadpartner.GetPartnerData(iPartner)
                local sName = string.format("[%s] x %s",mData.name, iAmount)
                sMsg = colorstring.FormatColorString(",获得#partner_name", {partner_name = sName})
                -- sName = mData["name"]
            else
                local oItem = loaditem.GetItem(iShape)
                local sText = loaditem.FormatItemColor(oItem:Quality(),",获得%s")
                sMsg = string.format(sText,string.format("[%s] x %s",oItem:Name(), iAmount))
            end
        end
        table.insert(mItemData,sMsg)
    end
    sMessage = sMessage .. table.concat(mItemData,"和")
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(oPlayer:GetPid(),sMessage)
    global.oChatMgr:HandleMsgChat(oPlayer, sMessage)
end

function CShop:GetRule()
    local oStore  = global.oStoreMgr
    local mShop = oStore:GetShopInfo(self.m_ID)
    local iRule = mShop["refresh_rule"]
    local mRule = oStore:GetRuleData(iRule)
    return mRule
end


-- 消耗次数刷新
function CShop:RefreshShopByCountType(oPlayer)
    local oNotifyMgr = global.oNotifyMgr

    local mRule = self:GetRule()
    if not mRule then
        return
    end
    local sKey = string.format("RShop_%d",self.m_ID)
    local iCnt = oPlayer.m_oToday:Query(sKey,0)
    local iMax = mRule["count"]
    local bFree = true
    if iCnt > mRule["count"] then
        oNotifyMgr:Notify(oPlayer:GetPid(),"本日手动刷新次数已消耗完")
        return
    end

    if iCnt >= mRule["free"] then
        local mEnv = {
        use = iCnt,
        }
        local iCost = formula_string(mRule["cost"], mEnv)
        local iCoin = mRule["coin_type"]
        local mCoin = gamedefines.COIN_TYPE[iCoin]
        local sCoinType = mCoin["type"]
        local sTip = "货币不足，无法刷新"
        if not self:ValidCost(oPlayer,sCoinType,iCost,{tip = sTip}) then
            return
        end
        bFree = false
        local mArgs = {
            cancel_tip = true
        }
        self:ConsumeCoin(oPlayer,iCost,sCoinType,"商店刷新")
    end
    oPlayer.m_oToday:Add(sKey,1)

    if bFree then
        oPlayer.m_oThisTemp:Delete(string.format("RShop_%d",self.m_ID))
        if mRule["time"] >0 then
            oPlayer.m_oThisTemp:Set(string.format("RShop_%d",self.m_ID),1,mRule["time"])
        end
    end
    self:ResetShopAmount(oPlayer)
end

-- 定时刷新
function CShop:RefreshShopByClockType(oPlayer)
    local oWorldMgr = global.oWorldMgr
    local mRule = self:GetRule()
    if not mRule then
        return false
    end
    local mData = oPlayer.m_oHuodongCtrl:GetData("shop",{})
    mData[db_key(self.m_ID)] = mData[db_key(self.m_ID)] or {}
    local mShopData = mData[db_key(self.m_ID)]
    local iLastTime = mShopData["Clock_Time"] or 0
    local iTime = oWorldMgr:GetNowTime()
    local bRefresh = false
    if iTime - iLastTime >= 24 * 3600 then
        bRefresh = true
    else
        local iLastHour = os.date("*t",iLastTime).hour
        local iNowHour =  os.date("*t",iTime).hour
        for _,iHour in ipairs(mRule["reset_time"]) do
            if iNowHour >= iHour and iLastHour < iHour  then
                bRefresh = true
                break
            end
        end
    end
    if bRefresh then
        mShopData["Clock_Time"] = iTime
        oPlayer.m_oHuodongCtrl:SetData("shop",mData)
        self:ResetShopAmount(oPlayer)
    end
    return bRefresh
end

-- 刷新CD
function CShop:RefreshShopByCycleType(oPlayer,mArg)
    local mRule = self:GetRule()
    if not mRule then
        return false
    end
    local sKey = string.format("RShop_%d",self.m_ID)
    if oPlayer.m_oThisTemp:Query(sKey) then
        return false
    end
    local iReset = mRule["time"]
    if iReset <= 0 then
        return false
    end
    oPlayer.m_oThisTemp:Set(sKey,1,iReset)
    self:ResetShopAmount(oPlayer)
    return true
end

function CShop:CheckRefreshGoods(oPlayer,mArg)
    mArg = mArg or {}
    self:RefreshShopByCycleType(oPlayer,mArg)
    self:RefreshShopByClockType(oPlayer,mArg)
end


--个人商店,需存储数据,
CPlayerShop={}
CPlayerShop.__index=CPlayerShop
inherit(CPlayerShop,CShop)


function CPlayerShop:GetShopData(oPlayer)
    local mData = oPlayer.m_oHuodongCtrl:GetData("pshop",{})
    local mShopData = mData[self.m_ID]
    return mShopData
end

function CPlayerShop:SetShopData(oPlayer,mShopData)
    local mData = oPlayer.m_oHuodongCtrl:GetData("pshop",{})
    mData[self.m_ID] = mShopData
    oPlayer.m_oHuodongCtrl:SetData("pshop",mData)
end


function CPlayerShop:GetGoodsInfo(oPlayer,iGoods,iPos)
    local mData = self:GetShopData(oPlayer)
    return mData[iPos]
end

function CPlayerShop:SetGoodsInfo(oPlayer,iGoods,iPos,mItemInfo)
    local mData = self:GetShopData(oPlayer)
    mData[iPos] = mItemInfo
    self:SetShopData(oPlayer,mData)
end

function CPlayerShop:GetShopGoods(oPlayer)
    local mData = self:GetShopData(oPlayer)
    if not mData  or table_count(mData) <= 0 then
        self:ResetShopItem(oPlayer)
    end
    local mData = self:GetShopData(oPlayer)
    local t = {}
    for iPos,m in ipairs(mData) do
        t[iPos] = m["sid"]
    end
    return t
end


function CPlayerShop:ResetShopAmount(oPlayer)
    self:ResetShopItem(oPlayer)
    super(CPlayerShop).ResetShopAmount(self,oPlayer)
end

function CPlayerShop:ResetShopItem(oPlayer)
    local oStoreMgr=global.oStoreMgr
    self:SetShopData(oPlayer,{})
    local mData = {}
    local mShop = oStoreMgr:GetShopInfo(self.m_ID)
    local mShopGoods = oStoreMgr:ShopGoods(self.m_ID)
    local mItemList = self:FilterResetShopItem(oPlayer,mShopGoods)
    if self.m_SelectByWeight then
        mItemList = self:FilterResetByWeight(oPlayer,mItemList)
    end


    local keylist = extend.Random.sample_table(mItemList,mShop["select_item"])
    keylist = table_value_list(keylist)
    for iPos,iGoods in ipairs(keylist) do
        local mItemData = self:CreateItemData(oPlayer,iGoods)
        self:SetGoodsInfo(oPlayer,iGoods,iPos,mItemData)
    end
end



function CPlayerShop:FilterResetShopItem(oPlayer,mShopGoods)
    local oStoreMgr=global.oStoreMgr
    local mItemList = {}
    local iGrade = oPlayer:GetGrade()
    for c,iItem in pairs(mShopGoods) do
        local mItem = oStoreMgr:GetItem(iItem)
        local mGrade = mItem["grade_limit"]
        local iShow = mItem["to_show"]
        if iShow == 1 then
            if mGrade["max"] then
                if iGrade <= mGrade["max"] and iGrade >= mGrade["min"] then
                    table.insert(mItemList,iItem)
                end
            else
                table.insert(mItemList,iItem)
            end
        end
    end
    return mItemList
end


function CPlayerShop:FilterResetByWeight(oPlayer,mItemList)
    local oStoreMgr=global.oStoreMgr
    local mShop = oStoreMgr:GetShopInfo(self.m_ID)
    local mChoose = {}
    for _,iGoods in ipairs(mItemList) do
        local oStoreMgr=global.oStoreMgr
        local mItem = oStoreMgr:GetItem(iGoods)
        if mItem["weight"] > 0 then
            mChoose[iGoods] = mItem["weight"]
        end
    end
    local iLimit = mShop["select_item"]
    local mNewItemList = {}
    for i=1,iLimit do
        local iShop = table_choose_key(mChoose)
        table.insert(mNewItemList,iShop)
    end
    return mNewItemList
end


function CPlayerShop:CreateItemData(oPlayer,iGoods)
    local mData  = {
    sid = iGoods,
    }
    return mData
end

function CPlayerShop:Amount(oPlayer,mItem,iPos)
    local sid = mItem["id"]
    local mItemData = self:GetGoodsInfo(oPlayer,sid,iPos)
    local iAmount = mItemData["a"] or 0
    return math.max(mItem.item_count - iAmount,0)
end

function CPlayerShop:ConsumeAmount(oPlayer,mItem,iConsume,iPos)
    local sid = mItem["id"]
    local mItemData = self:GetGoodsInfo(oPlayer,sid,iPos)
    mItemData["a"] = (mItemData["a"] or 0) + iConsume
    self:SetGoodsInfo(oPlayer,sid,iPos,mItemData)
end

function CPlayerShop:PackItem(oPlayer,iItem,iPos)
    local mPack = super(CPlayerShop).PackItem(self,oPlayer,iItem,iPos)
    if mPack then
        mPack.limit = 1
    end
    return mPack
end




