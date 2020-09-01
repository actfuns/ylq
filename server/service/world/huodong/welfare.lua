local global = require "global"
local res = require "base.res"
local interactive = require "base.interactive"
local record = require "public.record"
local extend = require "base.extend"
local net = require "base.net"
local colorstring = require "public.colorstring"
local router = require "base.router"

local loaditem = import(service_path("item/loaditem"))
local gamedefines = import(lualib_path("public.gamedefines"))
local huodongbase = import(service_path("huodong.huodongbase"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sName = "welfare"
CHuodong.m_sTempName = "新福利中心"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    return mData
end

function CHuodong:Load(m)
end

function CHuodong:MergeFrom(mFromData)
    return true
end

function CHuodong:AfterCharge(oPlayer,iRmb,sReason,mArgs)
    safe_call(self.AfterCharge2,self,oPlayer,iRmb,sReason,mArgs)
end

function CHuodong:AfterCharge2(oPlayer,iRmb,sReason,mArgs)
    self:UpdateChargeBack(oPlayer,iRmb,sReason,mArgs)
end

function CHuodong:OnLogin(oPlayer, bReEnter)
    if not bReEnter then
        -- self:ChargeBackNow(oPlayer)
        -- self:GiveOutZCFuli(oPlayer)
        -- self:CheckOneRmb(oPlayer)
        -- self:CheckSpecialGoods(oPlayer)
    end
    self:OnZCLogin(oPlayer)
end

function CHuodong:NewDayRefresh(oPlayer)
    self:OnZCLogin(oPlayer)
    -- self:CheckOneRmb(oPlayer)
    -- self:CheckSpecialGoods(oPlayer)
end

function CHuodong:OnUpGrade(oPlayer)
    safe_call(self.OnUpGrade2,self,oPlayer)
end

function CHuodong:OnUpGrade2(oPlayer)
    self:OnUpGradeZCCheck(oPlayer)
end

--------------充值返利开始----------------
function CHuodong:UpdateChargeBack(oPlayer,iRmb,sReason,mArgs)
    mArgs = mArgs or {}

    oPlayer:FuliAdd("BackRmb",iRmb)
    if sReason == "商店充值" then
        oPlayer:FuliAdd("BackGold",iRmb*20)
    else
        oPlayer:FuliAdd("BackGold",iRmb*10)
    end
    if sReason == "buymonth" then
        oPlayer:FuliAdd("BuyMonth",1)
    end

    if mArgs.goods_key == 212015 then
        oPlayer:FuliAdd("SkinCnt",1)
    end

    router.Send("cs", ".serversetter", "fuli", "UpdateChargeBack", {
        account = oPlayer:GetAccount(),
        info = {
            backrmb = oPlayer:FuliQuery("BackRmb",0),
            backgold = oPlayer:FuliQuery("BackGold",0),
            month = oPlayer:FuliQuery("BuyMonth",0),
            zsk = oPlayer:IsZskVip(),
            fund = (oPlayer:Query("grade_gift1",0) ~= 0),
            skin = oPlayer:FuliQuery("SkinCnt",0),
        }
    })
end

function CHuodong:AfterBuyGiftBag(oPlayer,iKey,sType)
    if sType == "gradegift" then
        local mGradeGift = oPlayer:FuliQuery("GradeGift",{})
        mGradeGift[iKey] = true
        oPlayer:FuliSet("GradeGift",mGradeGift)
        router.Send("cs", ".serversetter", "fuli", "UpdateChargeBack", {
            account = oPlayer:GetAccount(),
            info = {
                gradegift = mGradeGift,
            }
        })
    elseif sType == "onermb" then
        local iValue = oPlayer.m_oToday:Query("OneGift",0)
        local mOneRmb = oPlayer:FuliQuery("OneRmb",{})
        if iValue == 0 then
            iValue = iValue | (1<<iKey)
            table.insert(mOneRmb,iValue)
        else
            iValue = iValue | (1<<iKey)
            mOneRmb[#mOneRmb] = iValue
        end
        oPlayer.m_oToday:Set("OneGift",iValue)
        oPlayer:FuliSet("OneRmb",mOneRmb)
        router.Send("cs", ".serversetter", "fuli", "UpdateChargeBack", {
            account = oPlayer:GetAccount(),
            info = {
                onegift = mOneRmb,
            }
        })
    elseif sType == "goods" then
        local mGoods = oPlayer.m_oToday:Query("BkGoods",{})
        table.insert(mGoods,iKey)
        oPlayer.m_oToday:Set("BkGoods",mGoods)
        local mGoodsList = oPlayer:FuliQuery("BkGoods",{})
        if #mGoods == 1 then
            table.insert(mGoodsList,mGoods)
        else
            mGoodsList[#mGoodsList] = mGoods
        end
        oPlayer:FuliSet("BkGoods",mGoodsList)
        router.Send("cs", ".serversetter", "fuli", "UpdateChargeBack", {
            account = oPlayer:GetAccount(),
            info = {
                special = mGoodsList,
            }
        })
    end
end

function CHuodong:C2GSOpenChargeBackUI(oPlayer)
    oPlayer:Send("GS2CDoBackup",{
            type = 1,
            backup_info = {
                {
                    key = "rmbgold",
                    value = tostring(oPlayer:FuliQuery("BackGold",0)),
                },
            }
    })
    oPlayer:Send("GS2CChargeBackUI",{
            rmb = oPlayer:FuliQuery("BackRmb",0),
            month = oPlayer:FuliQuery("BuyMonth",0),
            zsk = oPlayer:IsZskVip(),
            fund = (oPlayer:Query("grade_gift1",0) ~= 0),
            gradegift = (oPlayer:FuliQuery("GradeGift",0) ~= 0),
            onermb = (oPlayer:FuliQuery("OneRmb",0) ~= 0),
            special = (oPlayer:FuliQuery("BkGoods",0)  ~= 0),
    })
end

function CHuodong:ChargeBackNow(oPlayer)
    -- if oPlayer:FuliQuery("bChargeBack",0) ~= 0 then
    --     return
    -- end
    -- oPlayer:FuliSet("bChargeBack",1)
    -- local iPid = oPlayer:GetPid()
    -- router.Request("cs", ".serversetter", "fuli", "QueryChargeBack", {account=oPlayer:GetAccount()}, function (r, d)
    --     local mInfo = d.info
    --     if mInfo then
    --         local iChargeValue = mInfo.backrmb or 0
    --         local iGoldCoin = mInfo.backgold or 0
    --         local oMailMgr = global.oMailMgr
    --         if iChargeValue > 0 then
    --             local mMail, sMail = oMailMgr:GetMailInfo(33)
    --             mMail.context = string.gsub(mMail.context,"$charge",tostring(iChargeValue))
    --             mMail.context = string.gsub(mMail.context,"$goldcoin",tostring(iGoldCoin))
    --             oMailMgr:SendMail(0, sMail, iPid, mMail,{
    --                 {sid = gamedefines.COIN_FLAG.COIN_GOLD, value = iGoldCoin},
    --             })
    --             oPlayer:AddHistoryCharge(iChargeValue)
    --             oPlayer:AfterChargeGold(iChargeValue,"充值")
    --         end

    --         local oWorldMgr = global.oWorldMgr
    --         local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)

    --         local month = mInfo.month or 0
    --         local zsk = mInfo.zsk
    --         local fund = mInfo.fund
    --         local mGradeGift = mInfo.gradegift
    --         local mOneRmb = mInfo.onegift
    --         local mBkSpecial = mInfo.special
    --         local iSkinCnt = mInfo.skin or 0

    --         local oHuodongMgr = global.oHuodongMgr
    --         local oHuodong = oHuodongMgr:GetHuodong("charge")

    --         local mMail, sMail = oMailMgr:GetMailInfo(34)
    --         local sEarn = ""

    --         if oHuodong and oPlayer then
    --             if month > 0 then
    --                 for iNo=1,month do
    --                     oHuodong:MonthCardChargeReward(oPlayer,"yk")
    --                 end
    --                 sEarn = sEarn .. "【".. month.."份月卡特权】"
    --                 local iRmb = month*30
    --                 oPlayer:AddHistoryCharge(iRmb)
    --                 oPlayer:AfterChargeGold(iRmb,"buymonth")
    --             end
    --             if zsk then
    --                 oHuodong:ZskCardChargeReward(oPlayer,"zsk")
    --                 sEarn = sEarn .. "【终身卡特权】"
    --                 local iRmb = 98
    --                 oPlayer:AddHistoryCharge(iRmb)
    --                 oPlayer:AfterChargeGold(iRmb,"buyforever")
    --             end
    --             if fund then
    --                 oPlayer:Set("grade_gift1", 1)
    --                 oHuodong:BuyGradeGift(oPlayer,"grade_gift1")
    --                 sEarn = sEarn .. "【成长基金】"
    --                 local iRmb = 98
    --                 oPlayer:AddHistoryCharge(iRmb)
    --                 oPlayer:AfterChargeGold(iRmb,"buyfund")
    --             end
    --             if mGradeGift then
    --                 sEarn = sEarn .. "【限时礼包】"
    --                 oPlayer:FuliSet("BackGradeGift",mGradeGift)
    --             end
    --             if mOneRmb then
    --                 sEarn = sEarn .. "【一元礼包】"
    --                 oPlayer:FuliSet("BackOneRmb",mOneRmb)
    --                 self:CheckOneRmb(oPlayer)
    --             end
    --             if mBkSpecial then
    --                 sEarn = sEarn .. "【每日特权礼包】"
    --                 oPlayer:FuliSet("BackSpecial",mBkSpecial)
    --                 self:CheckSpecialGoods(oPlayer)
    --             end
    --             if iSkinCnt > 0 then
    --                 sEarn = sEarn .. "【皮肤券礼包】"
    --                 for iNo=1,iSkinCnt do
    --                     global.oStoreMgr:RMBPlay(oPlayer,212,212015,true)
    --                 end
    --             end

    --             if #sEarn > 0 then
    --                 mMail.context = string.gsub(mMail.context,"$earn",sEarn)
    --                 oMailMgr:SendMail(0, sMail, iPid, mMail)
    --             end

    --         end
    --     end
    -- end)
end

function CHuodong:CheckGradeGift(oPlayer,iGradeKey)
    -- local iPid = oPlayer:GetPid()
    -- local sTimeFlag = "CheckGrade_"..iPid.."_"..iGradeKey
    -- self:DelTimeCb(sTimeFlag)
    -- self:AddTimeCb(sTimeFlag,1000,function ()
    --     self:CheckGradeGift2(oPlayer,iGradeKey)
    -- end)
end

function CHuodong:CheckGradeGift2(oPlayer,iGradeKey)
    -- local mGradeGift = oPlayer:FuliQuery("BackGradeGift",{})
    -- if mGradeGift[iGradeKey] then
    --     local oHuodongMgr = global.oHuodongMgr
    --     local oHuodong = oHuodongMgr:GetHuodong("gradegift")
    --     if oHuodong then
    --         oHuodong:BuyGradeGift(oPlayer,iGradeKey)
    --         oHuodong:ReceiveFreeGift(oPlayer,iGradeKey)
    --         mGradeGift[iGradeKey] = nil
    --         oPlayer:FuliSet("BackGradeGift",mGradeGift)
    --         local mData = oHuodong:GetGiftData(iGradeKey)
    --         local iRmb = mData.now_price or 0
    --         if iRmb > 0 then
    --             oPlayer:AddHistoryCharge(iRmb)
    --             oPlayer:AfterChargeGold(iRmb,string.format("giftbag_grade_%d",iGradeKey))
    --         end
    --     end
    -- end
end

function CHuodong:CheckOneRmb(oPlayer)
    -- local oHuodongMgr = global.oHuodongMgr
    -- local oHuodong = oHuodongMgr:GetHuodong("oneRMBgift")
    -- if not oHuodong:IsOpen() then
    --     return
    -- end
    -- if oPlayer.m_oToday:Query("CheckOneRmb",0) ~= 0 then
    --     return
    -- end
    -- oPlayer.m_oToday:Set("CheckOneRmb",1)
    -- local mOneRmb = oPlayer:FuliQuery("BackOneRmb",{})
    -- if  #mOneRmb > 0 then
    --     local iOneRMBKey = table.remove(mOneRmb,1)
    --     if oHuodong then
    --         for iNo=1,3 do
    --             if  ((1<<iNo) & iOneRMBKey) ~= 0 then
    --                 oHuodong:BuyGift(oPlayer, iNo, true)
    --                 local mData = oHuodong:GetBuyDaoBiao(iNo)
    --                 local iRmb = mData.price or 0
    --                 if iRmb > 0 then
    --                     oPlayer:AddHistoryCharge(iRmb)
    --                     oPlayer:AfterChargeGold(iRmb,string.format("one_RMB_%d",iNo))
    --                 end
    --             end
    --         end
    --         global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
    --         oPlayer:FuliSet("BackOneRmb",mOneRmb)
    --     end
    -- end
end

function CHuodong:CheckSpecialGoods(oPlayer)
    -- if oPlayer.m_oToday:Query("CheckSpecialG",0) ~= 0 then
    --     return
    -- end
    -- oPlayer.m_oToday:Set("CheckSpecialG",1)
    -- local mBkSpecial = oPlayer:FuliQuery("BackSpecial",{})
    -- if #mBkSpecial > 0 then
    --     local mList = table.remove(mBkSpecial,1)
    --     if mList then
    --         for _,iGoodsKey in ipairs(mList) do
    --             global.oStoreMgr:RMBPlay(oPlayer,212,iGoodsKey,true)
    --         end
    --     end
    --     oPlayer:FuliSet("BackSpecial",mBkSpecial)
    -- end
end

--------------充值返利结束----------------

-----------------------终测福利开始--------------------------
function CHuodong:OnUpGradeZCCheck(oPlayer)
    if oPlayer:GetGrade() == 55 then
        self:FuliPass(oPlayer)
    end
end

function CHuodong:GiveOutZCFuli(oPlayer)
    -- if oPlayer:FuliQuery("GiveOutZC",0) ~= 0 then
    --     return
    -- end
    -- oPlayer:FuliSet("GiveOutZC",1)
    -- local iPid = oPlayer:GetPid()
    -- local sAccount = oPlayer:GetAccount()
    -- router.Request("cs", ".serversetter", "fuli", "HasTestFuliAuth", {account=sAccount}, function (r, d)
    --     if d.pass then
    --         local oMailMgr = global.oMailMgr
    --         local mMail, sMail = oMailMgr:GetMailInfo(82)
    --         oMailMgr:SendMail(0, sMail, iPid, mMail, {},self:GetFuliItem())
    --         local iTitle = self:GetFuliRewardTitle(100001)
    --         if iTitle ~= 0 then
    --             local oTitleMgr = global.oTitleMgr
    --             oTitleMgr:AddTitle(iPid, iTitle)
    --         end
    --     end
    -- end)
end

function CHuodong:GetFuliRewardTitle(id)
    local res = require "base.res"
    assert(res["daobiao"]["huodong"][self.m_sName], "no welfare reward "..id)
    return res["daobiao"]["huodong"][self.m_sName]["fulireward"][id]["title_reward"]
end

function CHuodong:GetFuliReward(id)
    local res = require "base.res"
    assert(res["daobiao"]["huodong"][self.m_sName], "no welfare reward "..id)
    return res["daobiao"]["huodong"][self.m_sName]["fulireward"][id]["reward"]
end

function CHuodong:GetFuliItem()
    local mReward = self:GetFuliReward(100001)
    local mItem = {}
    for _,mInfo in pairs(mReward) do
        local sShape,iAmount = mInfo["sid"],mInfo["num"]
        local oItem = loaditem.ExtCreate(sShape)
        oItem:SetAmount(iAmount)
        table.insert(mItem,oItem)
    end
    return mItem
end

function CHuodong:OnZCLogin(oPlayer)
    local iDayNo = oPlayer:FuliQuery("FuliDay",0)
    local iNowDayNo = get_dayno()
    if iNowDayNo-1 == iDayNo then
        oPlayer:FuliAdd("FuliCnt",1)
        if oPlayer:FuliQuery("FuliCnt",0) == 6 then
            self:FuliPass(oPlayer)
        end
    elseif iNowDayNo ~= iDayNo then
        oPlayer:FuliSet("FuliCnt",0)
    end
    oPlayer:FuliSet("FuliDay",iNowDayNo)
    oPlayer:Send("GS2CFuliReddot",{flag=oPlayer:FuliQuery("fulipass",0),cday=oPlayer:FuliQuery("FuliCnt",0)+1})
end

function CHuodong:FuliPass(oPlayer)
    local sAccount = oPlayer:GetAccount()
    router.Send("cs", ".serversetter", "fuli", "FuliPass", {account=sAccount})
    oPlayer:FuliSet("fulipass",1)
    oPlayer:Send("GS2CFuliReddot",{flag=oPlayer:FuliQuery("fulipass",0),cday=oPlayer:FuliQuery("FuliCnt",0)+1})
    local oMailMgr = global.oMailMgr
    local mMail, sMail = oMailMgr:GetMailInfo(81)
    oMailMgr:SendMail(0, sMail, oPlayer:GetPid(), mMail)
end

-----------------------终测福利结束--------------------------

-----------------------招募返还开始--------------------------
function CHuodong:SetBackPartner(oPlayer,iSid,iStar)
    local iPid = oPlayer:GetPid()
    local sAccount = oPlayer:GetAccount()
    local sTimeFlag = "SetBackPartner"..iPid
    oPlayer:FuliSet("BKPartner",{iSid,iStar})
    oPlayer:Send("GS2CSetBackResult",{})
    self:GetBackPartnerInfo(oPlayer)
    self:DelTimeCb(sTimeFlag)
    self:AddTimeCb(sTimeFlag,10*1000,function ()
        self:SetBackPartner2(sAccount,iSid,iStar)
    end)
end

function CHuodong:SetBackPartner2(sAccount,iSid,iStar)
    router.Send("cs", ".serversetter", "fuli", "SetBackPartner", {account=sAccount,sid=iSid,star=iStar})
end

function CHuodong:CheckBackPartner(oPlayer)
    -- if oPlayer:FuliQuery("bBackPartner",0) ~= 0 then
    --     return
    -- end
    -- oPlayer:FuliSet("bBackPartner",1)
    -- local iPid = oPlayer:GetPid()
    -- local sAccount = oPlayer:GetAccount()
    -- router.Request("cs", ".serversetter", "fuli", "GetBackPartner", {account=sAccount}, function (r, d)
    --     local mInfo = d.info
    --     if mInfo then
    --         local iPartner,iStar = table.unpack(mInfo)
    --         local oWorldMgr = global.oWorldMgr
    --         local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    --         if oPlayer then
    --             local oMailMgr = global.oMailMgr
    --             local mMail, sMail= oMailMgr:GetMailInfo(44)
    --             local oItem = loaditem.ExtCreate("20"..iPartner)
    --             local iAmount = 10
    --             for iNo=1,iStar-1 do
    --                 local mStar = res["daobiao"]["partner"]["star"][iNo]
    --                 iAmount = iAmount + (mStar["cost_amount"] or 0)
    --             end
    --             oItem:SetAmount(iAmount)
    --             oMailMgr:SendMail(0, sMail, iPid, mMail, nil, {oItem})
    --         end
    --     end
    -- end)
end

function CHuodong:GetBackPartnerInfo(oPlayer)
    local iRemoteAddr = oPlayer.m_oPartnerCtrl:GetRemoteAddr()
    local mBkPartner = oPlayer:FuliQuery("BKPartner",{})
    local iPartner,iStar = table.unpack(mBkPartner)
    interactive.Send(iRemoteAddr, "fuli", "GetBackPartnerInfo", {
        pid=oPlayer:GetPid(),
        sid=iPartner,
        star=iStar,
    })
end

-----------------------招募返还结束--------------------------

function CHuodong:TestOP(oPlayer,iFlag,...)
    local mArgs = {...}
    if iFlag == 101 then
        router.Send("cs", ".serversetter", "fuli", "UpdateChargeBack", {
            account = "zlj3",
            info = {
                backrmb = 30,
                month = 2,
                zsk = true,
                fund = true,
            }
        })
    elseif iFlag == 102 then
        self:FuliPass(oPlayer)
    elseif iFlag == 103 then
        self:GiveOutZCFuli(oPlayer)
    elseif iFlag == 104 then
        local rmb,month,zsk,fund = table.unpack(mArgs)
        router.Send("cs", ".serversetter", "fuli", "UpdateChargeBack", {
            account = oPlayer:GetAccount(),
            info = {
                backrmb = rmb,
                month = month,
                zsk = (zsk==1),
                fund = (fund==1),
            }
        })
    elseif iFlag == 105 then
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("oneRMBgift")
        if oHuodong then
            oHuodong:SetOpen(1)
            oHuodong:ClearOnlineData()
            oHuodong:InitOnlineData()
        end
        oPlayer.m_oToday:Set("CheckOneRmb",0)
        oPlayer:FuliSet("bChargeBack",0)
        self:ChargeBackNow(oPlayer)
    elseif iFlag == 106 then
        oPlayer:FuliSet("bBackPartner",0)
        self:CheckBackPartner(oPlayer)
    elseif iFlag == 107 then
        local mGradeGift = {}
        for _,iGradeKey in pairs(mArgs) do
            mGradeGift[tonumber(iGradeKey)] = true
        end
        router.Send("cs", ".serversetter", "fuli", "UpdateChargeBack", {
            account = oPlayer:GetAccount(),
            info = {
                gradegift = mGradeGift,
            }
        })
    elseif iFlag == 108 then
        local mOneRmb = {}
        for _,iOneRMBKey in pairs(mArgs) do
            table.insert(mOneRmb,tonumber(iOneRMBKey))
        end
        router.Send("cs", ".serversetter", "fuli", "UpdateChargeBack", {
            account = oPlayer:GetAccount(),
            info = {
                onegift = mOneRmb,
            }
        })
    elseif iFlag == 109 then
        oPlayer.m_oToday:Set("CheckOneRmb",0)
        self:CheckOneRmb(oPlayer)
    elseif iFlag == 110 then
        oPlayer.m_oToday:Set("CheckSpecialG",0)
        self:CheckSpecialGoods(oPlayer)
    end
end