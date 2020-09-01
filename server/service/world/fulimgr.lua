local global = require "global"
local extend = require "base.extend"
local router = require "base.router"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedb = import(lualib_path("public.gamedb"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item/loaditem"))
local datactrl = import(lualib_path("public.datactrl"))

function NewFuliMgr()
    return CFuliMgr:New()
end

local sTableName = "welfarecenter"

CFuliMgr = {}
CFuliMgr.__index = CFuliMgr
inherit(CFuliMgr, datactrl.CDataCtrl)

function CFuliMgr:New()
    local o = super(CFuliMgr).New(self)
    self.m_ConsumeInfo = {}
    return o
end

function CFuliMgr:InitData()
    local mData = {
        name = sTableName,
    }
    local mArgs = {
        module = "global",
        cmd = "LoadGlobal",
        data = mData
    }
    gamedb.LoadDb("fuli","common", "LoadDb",mArgs, function (mRecord, mData)
        if not is_release(self) then
            local m = mData.data
            self:Load(m)
            self:OnLoaded()
        end
    end)
    self:RefreshLuckItem()
end

function CFuliMgr:ConfigSaveFunc()
    self:ApplySave(function ()
        local oFuliMgr = global.oFuliMgr
        oFuliMgr:CheckSaveDb()
    end)
end

function CFuliMgr:CheckSaveDb()
    if self:IsDirty() then
        local mData = {
            name = sTableName,
            data = self:Save()
        }
        gamedb.SaveDb("fuli","common","SaveDb",{
            module = "global",
            cmd = "SaveGlobal",
            data = mData,
        })
        self:UnDirty()
    end
end

function CFuliMgr:Save()
    local mData = {}
    mData.consumeinfo = self.m_ConsumeInfo
    mData.luckitem = self.m_LuckItem
    return mData
end

function CFuliMgr:Load(mData)
    self.m_ConsumeInfo = mData.consumeinfo or {}
    self.m_LuckItem = mData.luckitem
end

function CFuliMgr:MergeFrom(mFromData)
    return false, "merge function is not implemented"
end

function CFuliMgr:NewHour(iDay,iHour)
    if iHour == 0 then
        self:RefreshLuckItem()
    end
end

function CFuliMgr:OnLogout(oPlayer)
end

function CFuliMgr:OnDisconnected(oPlayer)
end

function CFuliMgr:IsOpen(id)
    local res = require "base.res"
    return res["daobiao"]["welfare_control"][id]["open"] == 1
end

function CFuliMgr:IsOpenGrade(oPlayer, id)
    local res = require "base.res"
    return res["daobiao"]["welfare_control"][id]["grade"] <= oPlayer:GetGrade()
end

function CFuliMgr:TodayFirstLogin(oPlayer)
    self:AddLuckDrawCnt(oPlayer,1)
end

function CFuliMgr:OnLogin(oPlayer, bReEnter)
    self:CheckHistoryCharge(oPlayer)
    self:CheckBackPartner(oPlayer)
    self:TipFirstCharge(oPlayer)
    self:GS2CFuliPoint(oPlayer)
    self:GS2CLuckDrawCnt(oPlayer)
    self:OnConsumePointLogin(oPlayer)
end

function CFuliMgr:AfterChargeGold(oPlayer,iVal,sReason)
    self:CheckHistoryCharge(oPlayer)
    self:TipFirstCharge(oPlayer)
end

function CFuliMgr:OnUpGrade(oPlayer)
end

-----------------------累计充值--------------------------
function CFuliMgr:CheckHistoryCharge(oPlayer)
    local iDegree = oPlayer:HistoryCharge()
    local mGetlist = oPlayer:FuliQuery("charge_get",{})
    oPlayer:Send("GS2CHistoryCharge",{degree=iDegree,getlist=mGetlist})
end

function CFuliMgr:GetFuliChargeReward(id)
    local res = require "base.res"
    assert(res["daobiao"]["fulicharge"][id], "no fuli charge id "..id)
    local mReward = res["daobiao"]["fulicharge"][id]["reward"]
    local iTitle = res["daobiao"]["fulicharge"][id]["title"]
    local iText = res["daobiao"]["fulicharge"][id]["text"]
    return mReward,iTitle,iText
end

function CFuliMgr:ChargeReward(oPlayer,id)
    local mGetlist = oPlayer:FuliQuery("charge_get",{})
    if table_in_list(mGetlist,id) then return end
    table.insert(mGetlist,id)
    oPlayer:FuliSet("charge_get",mGetlist)
    local mReward,iTitle,iText = self:GetFuliChargeReward(id)
    local mItemList = {}
    for _,info in pairs(mReward) do
        table.insert(mItemList,{info["sid"],info["num"]})
    end
    if iTitle ~= 0 then
        local oTitleMgr = global.oTitleMgr
        oTitleMgr:AddTitle(oPlayer:GetPid(), iTitle)
    end
    if iText ~= 0 then
        local sMsg = self:GetTextData(iText)
        sMsg = string.gsub(sMsg,"$username",oPlayer:GetName())
        global.oChatMgr:HandleSysChat(sMsg,1,1)
    end
    oPlayer:GiveItem(mItemList,"充值奖励"..id,{cancel_tip=true})
    global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
    self:CheckHistoryCharge(oPlayer)
    record.log_db("fuli", "chargereward", {
        pid = oPlayer:GetPid(),
        iteminfo = ConvertTblToStr(mItemList),
        title = iTitle
    })
end

---------------招募保留------------------

function CFuliMgr:SetBackPartner(oPlayer,iSid)
    -- local sAccount = oPlayer:GetAccount()
    -- oPlayer:FuliSet("backsid",iSid)
    -- router.Send("cs", ".serversetter", "fuli", "SetBackPartner", {account=sAccount,sid=iSid})
    -- oPlayer:Send("GS2CSetBackResult",{})
end

function CFuliMgr:CheckBackPartner(oPlayer)
    -- local iPid = oPlayer:GetPid()
    -- local sAccount = oPlayer:GetAccount()
    -- router.Request("cs", ".serversetter", "fuli", "GetBackPartner", {account=sAccount}, function (r, d)
    --     if d.sid and d.sid ~= 0 then
    --         local iPartner = d.sid
    --         local oWorldMgr = global.oWorldMgr
    --         local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    --         if oPlayer then
    --             local oMailMgr = global.oMailMgr
    --             local mMail, sMail= oMailMgr:GetMailInfo(44)
    --             local oItem = loaditem.ExtCreate("1010(partner="..iPartner..")")
    --             oMailMgr:SendMail(0, sMail, oPlayer:GetPid(), mMail,nil,{oItem})
    --         end
    --     end
    -- end)
end

function CFuliMgr:GetBackPartnerInfo(oPlayer)
    -- local iRemoteAddr = oPlayer.m_oPartnerCtrl:GetRemoteAddr()
    -- interactive.Send(iRemoteAddr, "fuli", "GetBackPartnerInfo", {
    --     pid=oPlayer:GetPid(),
    --     sid=oPlayer:FuliQuery("backsid")
    -- })
end

--------------首充奖励----------------
function CFuliMgr:GetFuliFirstChargeReward(id)
    local res = require "base.res"
    assert(res["daobiao"]["first_charge"][id], "no fuli firstcharge id "..id)
    return res["daobiao"]["first_charge"][id]["reward"]
end

function CFuliMgr:GetItemRewardData(iItemReward)
    local res = require "base.res"
    local mData = res["daobiao"]["reward"]["welfare"]["itemreward"][iItemReward]
    if not mData then
        return
    end
    return mData[1][1]
end

function CFuliMgr:ReceiveFirstCharge(oPlayer)
    if oPlayer:IsFirstCharge() and oPlayer:FuliQuery("FirstChargeRw",0) == 0 then
        oPlayer:FuliSet("FirstChargeRw",1)
        oPlayer:Send("GS2CFirstChargeUI",{bOpen=false,bReceive=false})
        local mReward = self:GetFuliFirstChargeReward(100001)
        local mItemList = {}
        for _,id in pairs(mReward) do
            local mData = self:GetItemRewardData(tonumber(id))
            table.insert(mItemList,{mData["sid"],mData["amount"]})
        end
        oPlayer:GiveItem(mItemList,"首充奖励", {first_charge = 1})
        record.log_db("fuli", "firstcharge", {
            pid = oPlayer:GetPid(),
            iteminfo = ConvertTblToStr(mItemList),
        })
    end
end

function CFuliMgr:TipFirstCharge(oPlayer)
    local mNet = {bOpen=true,bReceive=false}
    if not oPlayer:IsFirstCharge() and oPlayer:FuliQuery("FirstChargeRw",0) == 0 then
        oPlayer:Send("GS2CFirstChargeUI",mNet)
    else
        if oPlayer:FuliQuery("FirstChargeRw",0) == 0 then
            mNet.bReceive = true
            oPlayer:Send("GS2CFirstChargeUI",mNet)
        end
    end
end

--------------消费积分----------------
function CFuliMgr:OnConsumePointLogin(oPlayer)
    local oHuodong = self:GetLimitOpenHD()
    if oHuodong then
        oPlayer:Send("GS2CFuliTime",{
            starttime=oHuodong:StartTime("consume_point"),
            endtime=oHuodong:EndTime("consume_point")
        })
    end
end

function CFuliMgr:AddConsumePoint(oPlayer,iPoint)
    if not self:IsOpen(11) then
        return
    end
    if not iPoint or iPoint <= 0 then
        iPoint = iPoint or type(iPoint)
        record.error("fuli error consume point "..iPoint)
        return
    end
    local oHuodong = self:GetLimitOpenHD()
    if not oHuodong:IsOpen("consume_point") then
        return
    end
    local iVersion = oHuodong:GetDispatchID("consume_point")
    if oPlayer:FuliQuery("FPointVersion",0) ~= iVersion then
        oPlayer:FuliSet("ConsumePoint",0)
        oPlayer:FuliSet("FPointVersion",iVersion)
    end
    oPlayer:FuliAdd("ConsumePoint",iPoint)
    self:GS2CFuliPoint(oPlayer)
    record.log_db("fuli", "addcspoint", {
        pid = oPlayer:GetPid(),
        now = oPlayer:FuliQuery("ConsumePoint",0),
        add = iPoint,
    })
end

function CFuliMgr:GS2CFuliPoint(oPlayer)
    oPlayer:Send("GS2CFuliPoint",{point=oPlayer:FuliQuery("ConsumePoint",0)})
end

function CFuliMgr:GetConsumeConfig()
    local res = require "base.res"
    return res["daobiao"]["consume_point"]
end

function CFuliMgr:GetConsumePlan()
    local res = require "base.res"
    return res["daobiao"]["consume_plan"]
end

function CFuliMgr:GetLimitOpenHD()
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("limitopen")
    if oHuodong then
        return oHuodong
    end
end

function CFuliMgr:GS2CFuliPointUI(oPlayer)
    if not self:IsOpen(11) then
        return
    end
    local oHuodong = self:GetLimitOpenHD()
    if not oHuodong:IsOpen("consume_point") then
        oPlayer:NotifyMessage("该活动已关闭")
        return
    end
    local iVersion = oHuodong:GetDispatchID("consume_point")
    if oPlayer:FuliQuery("FPointVersion",0) ~= iVersion then
        oPlayer:FuliSet("FPointVersion",iVersion)
        oPlayer:FuliSet("ConsumePoint",0)
        oPlayer:FuliSet("ConsumeInfo",{})
    end
    if oHuodong:CheckChange("consume_point") then
        oHuodong:ClearChange("consume_point")
    end
    local iPlan = oHuodong:GetUsePlan("consume_point")

    local mConsume = oPlayer:FuliQuery("ConsumeInfo",{})

    local mConfig = self:GetConsumeConfig()
    local mPlan = self:GetConsumePlan()
    local mList = mPlan[iPlan] or {}
    mList = mList.detail or {}
    local mInfo = {}
    for _,id in ipairs(mList) do
        local mUnit = mConfig[id]
        if mUnit and mUnit.buy_limit > 0 then
            table.insert(mInfo,{
                id=id,
                rest=mConsume[id] or mUnit.buy_limit,
            })
        end
    end
    oPlayer:Send("GS2CFuliPointUI",{
        point=oPlayer:FuliQuery("ConsumePoint",0),
        info=mInfo,
        version = oHuodong:GetDispatchID("consume_point"),
        plan = tonumber(iPlan),
        starttime = oHuodong:StartTime("consume_point"),
        endtime = oHuodong:EndTime("consume_point"),
    })
end

function CFuliMgr:FuliPointBuy(oPlayer,id,amount,iVersion)
    if not self:IsOpen(11) then
        return
    end
    local oHuodong = self:GetLimitOpenHD()
    if not oHuodong:IsOpen("consume_point") then
        oPlayer:NotifyMessage("该活动已关闭")
        return
    end

    if oHuodong:GetDispatchID("consume_point") ~= iVersion then
        oPlayer:NotifyMessage("数据有变动")
        self:GS2CFuliPointUI(oPlayer)
        return
    end
    if amount < 0 then
        record.error("fuli point buy error "..amount)
        return
    end
    local mConfig = self:GetConsumeConfig()
    local mUnit = mConfig[id]
    local iPoint = mUnit.point
    iPoint = iPoint * amount
    if oPlayer:FuliQuery("ConsumePoint",0) < iPoint then
        oPlayer:NotifyMessage("积分不足，无法兑换")
        return
    end
    local buy_limit = mUnit.buy_limit
    local mReward = mUnit.reward
    local num = mReward.num
    num = num * amount

    local mConsume = oPlayer:FuliQuery("ConsumeInfo",{})

    if buy_limit > 0 then
        mConsume[id] = mConsume[id] or buy_limit
        if mConsume[id] < num then
            oPlayer:NotifyMessage("兑换道具数量不足")
            self:GS2CFuliPointUI(oPlayer)
            return
        end
        mConsume[id] = mConsume[id] - num
        oPlayer:FuliSet("ConsumeInfo",mConsume)
    end

    oPlayer:FuliAdd("ConsumePoint",-iPoint)
    oPlayer:GiveItem({{mReward.sid,num}},"消费积分"..id)
    self:GS2CFuliPointUI(oPlayer)

    record.log_db("fuli", "resumecspoint", {
        pid = oPlayer:GetPid(),
        now = oPlayer:FuliQuery("ConsumePoint",0),
        sub = iPoint,
        id = id,
    })
end

--------------幸运转盘----------------
function CFuliMgr:AddLuckActive(oPlayer,iVal)
    if not self:IsOpen(11) then
        return
    end
    local iOld = oPlayer.m_oToday:Query("LuckActive",0)
    oPlayer.m_oToday:Add("LuckActive",iVal)
    local iNew = oPlayer.m_oToday:Query("LuckActive",0)
    if iOld < 100  and iNew >= 100 then
        self:AddLuckDrawCnt(oPlayer,1)
    end
end

function CFuliMgr:AddLuckDrawCnt(oPlayer,iCnt)
    if not self:IsOpen(11) then
        return
    end
    if not iCnt or iCnt <= 0 then
        iCnt = iCnt or type(iCnt)
        record.error("fuli error addluck cnt "..iCnt)
        return
    end
    oPlayer:FuliAdd("LuckDrawCnt",iCnt)
    self:GS2CLuckDrawCnt(oPlayer)
    record.log_db("fuli", "addluckdraw", {
        pid = oPlayer:GetPid(),
        now = oPlayer:FuliQuery("LuckDrawCnt",0),
        add = iCnt,
    })
end

function CFuliMgr:GS2CLuckDrawCnt(oPlayer)
    oPlayer:Send("GS2CLuckDrawCnt",{cnt=oPlayer:FuliQuery("LuckDrawCnt",0)})
end

function CFuliMgr:GetLuckDrawConfig()
    local res = require "base.res"
    return res["daobiao"]["luck_draw"]["luck_draw_main"]
end

function CFuliMgr:RefreshLuckItem()
    self:Dirty()
    local mConfig = self:GetLuckDrawConfig()
    local mResult = {}
    for iNo=1,8 do
        local mItem = mConfig[iNo].item
        local iRate = mConfig[iNo].rate
        local iNum = math.random(iRate)
        local iTotal = 0
        for _,info in pairs(mItem) do
            iTotal = iTotal + info.rate
            if iNum <= iTotal then
                table.insert(mResult,info.idx)
                break
            end
        end
    end
    self.m_LuckItem = mResult
end

function CFuliMgr:GS2CLuckDrawUI(oPlayer)
    if not self:IsOpen(11) then
        return
    end
    if not self.m_LuckItem then
        self:RefreshLuckItem()
    end
    oPlayer:Send("GS2CLuckDrawUI",{
        cnt=oPlayer:FuliQuery("LuckDrawCnt",0),
        idxlist=self.m_LuckItem,
        cost = self:GetPlayerLuckDrawGold(oPlayer)
    })
end

function CFuliMgr:GetLuckDrawRewardConfig()
    local res = require "base.res"
    return res["daobiao"]["luck_draw"]["luck_draw_reward"]
end

--随机大类
function CFuliMgr:RandomLuckItemPos()
    local mConfig = self:GetLuckDrawRewardConfig()
    local mLuckItem = self.m_LuckItem
    local iTotal = 0
    for _,idx in pairs(mLuckItem) do
        iTotal = iTotal + mConfig[idx].srate
    end
    local iNum = math.random(iTotal)
    iTotal = 0
    for iPos,idx in pairs(mLuckItem) do
        iTotal = iTotal + mConfig[idx].srate
        if iNum <= iTotal then
            return iPos,idx
        end
    end
end

--随机物品信息
function CFuliMgr:RandomLuckResult(idx)
    local mConfig = self:GetLuckDrawRewardConfig()
    mConfig = mConfig[idx].item
    local iTotal = 0
    for _,info in pairs(mConfig) do
        iTotal = iTotal + info.rate
    end
    local iNum = math.random(iTotal)
    iTotal = 0
    for _,info in pairs(mConfig) do
        iTotal = iTotal + info.rate
        if iNum <= iTotal then
            return info.idx
        end
    end
end

function CFuliMgr:GetLuckDrawItemInfoConfig(iRewardItem)
    local res = require "base.res"
    return res["daobiao"]["luck_draw"]["luck_draw_item"][iRewardItem]
end

function CFuliMgr:GetPlayerLuckDrawGold(oPlayer)
    local iCostGold = 100
    iCostGold = iCostGold + 50 * oPlayer.m_oToday:Query("LuckDrawByGold",0)
    iCostGold = math.min(300,iCostGold)
    return iCostGold
end

function CFuliMgr:LuckDrawItem(oPlayer,iType)
    if not self:IsOpen(11) then
        return
    end
    if oPlayer.m_oThisTemp:Query("luckitem") then
        return
    end
    local iPos,idx = self:RandomLuckItemPos()
    local iRewardItem = self:RandomLuckResult(idx)
    local mItemInfo = self:GetLuckDrawItemInfoConfig(iRewardItem)
    if not mItemInfo then
        record.error("luck draw have no reward ".. iRewardItem)
        return
    end
    if iType == 1 then
        if oPlayer:FuliQuery("LuckDrawCnt",0) <= 0 then
            oPlayer:NotifyMessage("抽奖次数不足")
            return
        end
        oPlayer:FuliAdd("LuckDrawCnt",-1)
    elseif iType == 2 then
        local iCostGold = self:GetPlayerLuckDrawGold(oPlayer)
        if not oPlayer:ValidGoldCoin(iCostGold) then
            return
        end
        oPlayer.m_oToday:Add("LuckDrawByGold",1)
        oPlayer:ResumeGoldCoin(iCostGold,"幸运抽奖")
    else
        return
    end
    oPlayer.m_oThisTemp:Set("luckitem",{sid=mItemInfo.sid,amount=mItemInfo.amount,notify=mItemInfo.notify},30)
    oPlayer:Send("GS2CLuckDrawPos",{
            pos = iPos,
            cnt = oPlayer:FuliQuery("LuckDrawCnt",0),
            cost = self:GetPlayerLuckDrawGold(oPlayer)
    })
    if mItemInfo then
        local iPid = oPlayer:GetPid()
        local sTimeFlag = "GiveLuckDraw"..iPid
        self:DelTimeCb(sTimeFlag)
        self:AddTimeCb(sTimeFlag, 25 * 1000, function ()
            local oWorldMgr = global.oWorldMgr
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                self:GiveLuckDraw(oPlayer)
            end
        end)
    end
end

function CFuliMgr:GiveLuckDraw(oPlayer)
    local sTimeFlag = "GiveLuckDraw"..oPlayer:GetPid()
    self:DelTimeCb(sTimeFlag)
    local mItemInfo = oPlayer.m_oThisTemp:Query("luckitem")
    if mItemInfo then
        oPlayer:GiveItem({{mItemInfo.sid,mItemInfo.amount}},"幸运抽奖",{cancel_tip=true})
        record.log_db("fuli", "luckreward", {
            pid = oPlayer:GetPid(),
            sid = mItemInfo.sid,
            amount = mItemInfo.amount,
        })
        oPlayer.m_oThisTemp:Delete("luckitem")
        global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
        if mItemInfo.notify == 1 then
            self:LuckNotify(oPlayer,mItemInfo.sid,mItemInfo.amount)
        end
    end
end

function CFuliMgr:GetTextData(iText)
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"]["welfare"]["text"][iText]
    return mData["content"]
end

function CFuliMgr:LuckNotify(oPlayer,sid,amount)
    local oItem = loaditem.GetItem(sid)
    local sName = oItem:Name()
    if oItem:SID() < 10000 then
        sName = oItem:RealName()
    elseif oItem:ItemType() == "partner_equip" then
        sName = oItem:Star() .. "星".. sName
    end
    if not sName then
        record.error("luck notify no name ".. sid)
        return
    end
    local sMsg = self:GetTextData(1001)
    sMsg = string.gsub(sMsg,"$username",oPlayer:GetName())
    sMsg = string.gsub(sMsg,"$item",string.format("{link28,%d,%d}",sid,amount))
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendSysChat(sMsg,1,1)
end