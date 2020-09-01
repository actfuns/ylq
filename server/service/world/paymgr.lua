-- import module

local global = require "global"
local res = require "base.res"
local cjson = require "cjson"
local crypt = require "crypt"
local record = require "public.record"
local router = require "base.router"
local serverdefines = require "public.serverdefines"

local serverinfo = import(lualib_path("public.serverinfo"))
local analy = import(lualib_path("public.dataanaly"))
local gamedb = import(lualib_path("public.gamedb"))

function NewPayMgr(...)
    return CPayMgr:New(...)
end

function NewPayCb(...)
    return CPayCb:New(...)
end

CPayMgr = {}
CPayMgr.__index = CPayMgr
inherit(CPayMgr, logic_base_cls())

function CPayMgr:New()
    local o = super(CPayMgr).New(self)
    o.m_oPayCb = NewPayCb()
    return o
end

function CPayMgr:GetCallBackUrl()
    return string.format("https://%s/demisdkcb/paycb", serverinfo.get_cs_domain())
end

function CPayMgr:ValidTryPay(oPlayer,sProductKey,mArgs)
    if is_production_env() and sProductKey == "com.kaopu.ylq.001" then
        global.oNotifyMgr:Notify(oPlayer:GetPid(),"非法充值项")
        return
    end
    local oHuodong = global.oHuodongMgr:GetHuodong("charge")
    local iPid = oPlayer:GetPid()
    if table_in_list({"com.kaopu.ylq.appstore.zsk","com.cilu.n1_zsk"},sProductKey) then
        if not oHuodong:CanBuyZskCard(iPid) then
            record.info("try pay error,pid:%s key:%s",iPid,sProductKey)
            return false
        end
    elseif table_in_list({"com.kaopu.ylq.appstore.yk","com.cilu.n1_yk"},sProductKey) then
        if not oHuodong:CanBuyMonthCard(iPid) then
            record.info("try pay error,pid:%s key:%s",iPid,sProductKey)
            return false
        end
    elseif table_in_list({"com.kaopu.ylq.appstore.czjj","com.cilu.n1_czjj"},sProductKey) then
        if not oHuodong:CanBuyGradeGift(oPlayer) then
            record.info("try pay error,pid:%s key:%s",iPid,sProductKey)
            return false
        end
        local sAccount = oPlayer:GetAccount()
        if global.oAccountMgr:AccountIsBuyCZJJ(sAccount) then
            global.oNotifyMgr:Notify(oPlayer:GetPid(),"同一个账号只能购买一次成长基金")
            return false
        end
    end
    local goods = mArgs.goods_key
    if goods and goods~=0 then
        local oStoreMgr = global.oStoreMgr
        local oShop = oStoreMgr:GetShop(212)
        local mItem=oStoreMgr:GetItem(goods)
        if oShop then
            local iAmount=oShop:Amount(oPlayer,mItem,1)
            if iAmount == 0 then
                global.oNotifyMgr:Notify(oPlayer:GetPid(),"商品已售罄")
                return false
            end
        end
    end
    local iGradeKey = mArgs.grade_key
    if iGradeKey and iGradeKey ~= 0 then
        local oHuodong = global.oHuodongMgr:GetHuodong("gradegift")
        if not oHuodong or not oHuodong:ValidBuyGift(oPlayer,iGradeKey,sProductKey) then
            return false
        end
    end
    local iOneRMBKey = mArgs.one_RMB_gift
    if iOneRMBKey and iOneRMBKey  ~= 0 then
        local oHuodong = global.oHuodongMgr:GetHuodong("oneRMBgift")
        if not oHuodong or not oHuodong:ValidBuyGift(oPlayer,iOneRMBKey,sProductKey) then
            return false
        end
    end
    return true
end
function CPayMgr:TryPay(oPlayer, sProductKey, iAmount, sPayWay, bIsDemi)
    if not serverinfo.get_cs_domain() then
        record.warning("try pay error: no callback url")
        return
    end
    if not is_gs_server() then
        record.warning("not gs couldn't pay")
        return
    end
    local mData = assert(res["daobiao"]["pay"][sProductKey], string.format("error product key %s %s", oPlayer:GetPid(),sProductKey))
    local sProductName = mData["name"]
    local sProductDesc = mData["desc"]
    local iValue = mData["value"]
    local iTotValue = iValue * iAmount

    local mExt = {
        account = oPlayer:GetAccount()
    }
    local mRequest = {
        appId = global.oDemiSdk:GetAppId(),
        p = oPlayer:GetChannel(),
        uid = oPlayer:GetChannelUuid(),
        roleId = oPlayer:GetPid(),
        serverId = get_server_id(oPlayer:GetBornServerKey()),
        productId = sProductKey,
        productName = sProductName,
        productDesc = sProductDesc,
        amount = iAmount,
        cent = iTotValue,
        ext = cjson.encode(mExt),
        callbackURL = self:GetCallBackUrl(),  
        imei = oPlayer:GetIMEI(),  
        mac = oPlayer:GetMac(),  
        platform = oPlayer:GetPlatform(), 
        accountType = 6,  
        age = 20,
        brand = oPlayer:GetDevice(),
        country = "",  
        province = "",
        gender = 1, 
        language = "",
        netType = 0, 
        operators = 0, 
        osVersion = oPlayer:GetClientOs(),  
        resolution = "", 
        currencyType = "", 
        roleClass = oPlayer:GetSchool(),
        roleRace = oPlayer:GetRace(),
        grade = oPlayer:GetGrade(),
        payWay = sPayWay,
        ip = oPlayer:GetIP(),
        is_demi = bIsDemi,
    }

    router.Send("cs", string.format(".pay%s", math.random(1, PAY_SERVICE_COUNT)), "common", "TryPay", {
        request = mRequest,
        req_server = get_server_tag()
    })
end

function CPayMgr:TryPayCb(pid, mInfo)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end
    oPlayer:Send("GS2CPayInfo", {
        order_id = tostring(mInfo.order_id),
        product_key = mInfo.product_key,
        product_amount = mInfo.product_amount,
        product_value = mInfo.product_value,
        callback_url = mInfo.callback_url
    })
end

function CPayMgr:PaySuccessedCb(iPid, lInfos)
    global.oWorldMgr:LoadPrivacy(iPid, function (o)
        self:_PaySuccessedCb1(o, lInfos)
    end)
end

function CPayMgr:_PaySuccessedCb1(o, lInfos)
    if not o then
        return
    end

    local iPid = o:GetPid()
    local lOrderIds = {}
    for _, mOrders in ipairs(lInfos) do
        local iOrderId = mOrders.orderid
        if not o:IsDealedOrder(iOrderId) then
            local br, m = safe_call(self.DealSucceedOrder, self, iPid, mOrders)
            if br then
                o:AddDealedOrder(iOrderId)
                table.insert(lOrderIds, iOrderId)
                safe_call(self.PaySuccessLog, self, iPid, mOrders)
            end
        else
            table.insert(lOrderIds, iOrderId)
        end
    end

    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        o:AddSaveMerge(oPlayer)
    end
    if lOrderIds and next(lOrderIds) then
        router.Send("cs", string.format(".pay%s", math.random(1, PAY_SERVICE_COUNT)), "common", "MarkOrderAsDealed", {
            orderids=lOrderIds,
        })
    end
end

function CPayMgr:DealSucceedOrder(iPid, mOrders)
    if mOrders.Type == 2 then
        local mData, sName = global.oMailMgr:GetMailInfo(9013)
        local itemId = mOrders.itemId
        local itemNum = mOrders.itemNum
        local iteminfo = {{sid = itemId,cnt = itemNum}}
        local sname = crypt.base64decode("57O757uf566h55CG5ZGY")
        local cnt = 1
        for i=1,cnt do
            local items = {}
            if iteminfo and next(iteminfo) then
                for _,info in ipairs(iteminfo) do
                    local oTmpItem = global.oItemLoader:ExtCreate(info["sid"])
                    if info["cnt"] then
                        oTmpItem:SetAmount(info["cnt"])
                    end
                    table.insert(items, oTmpItem)
                end
            end
        global.oMailMgr:SendMail(0, sname, iPid, mData,0,items)
        end
    elseif mOrders.Type == 1 then
        local sProductKey = mOrders.product_key
        local iAmount = tonumber(mOrders.product_amount)
        local mData = assert(res["daobiao"]["pay"][sProductKey], string.format("deal order error product key %s", sProductKey))
        local sFunc = mData["func"]
        local lArgs = mData["args"]
        local func = assert(self.m_oPayCb[sFunc], string.format("deal order error func %s", sFunc))
        func(self.m_oPayCb, iPid, iAmount, lArgs, sProductKey)
    elseif mOrders.Type == 3 then
        global.oWorldMgr:Logout(iPid)
    elseif mOrders.Type == 4 then
        BanPlayerLogin(iPid)
    elseif mOrders.Type == 5 then
        PlayerLogin(iPid)
    end
end

function CPayMgr:DealUntreatedOrder(oPlayer)
    router.Send("cs", string.format(".pay%s", math.random(1, PAY_SERVICE_COUNT)), "common", "DealUntreatedOrder", {
        pid=oPlayer:GetPid(),
        server=get_server_tag()
    })
end

function CPayMgr:PaySuccessLog(iPid, mOrders)
    safe_call(self.AnalyPayLog, self, iPid, mOrders)
end

-- 数据中心log
function CPayMgr:AnalyPayLog(iPid, mOrders)
    local mAnalyLog = {}
    mAnalyLog["recharge_num"] = mOrders["amount"] or 1
    mAnalyLog["product_id"] = mOrders["product_key"]
    mAnalyLog["product_cnt"] = mOrders["product_amount"]
    mAnalyLog["order_id"] = mOrders["orderid"]

    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        mAnalyLog = table_combine(mAnalyLog, oPlayer:BaseAnalyInfo())
        analy.log_data("Recharge_1", mAnalyLog)
    else
        oWorldMgr:LoadProfile(iPid, function (oProfile)
            if oProfile then
                mAnalyLog = table_combine(mAnalyLog, oProfile:BaseAnalyInfo())
                analy.log_data("Recharge_1", mAnalyLog)
            end
        end)
    end
end

function CPayMgr:ClientQrpayScan(iPid, sTransferInfo)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CQrpayScan", {transfer_info = sTransferInfo})
    end
end

CPayCb = {}
CPayCb.__index = CPayCb
inherit(CPayCb, logic_base_cls())

function CPayCb:New()
    local o = super(CPayCb).New(self)
    return o
end

function CPayCb:pay_for_gold(iPid, iAmount, lArgs, sProductKey)
    local oHuodong = global.oHuodongMgr:GetHuodong("charge")
    assert(oHuodong, "ERROR not charge object")

    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oHuodong:PayForGold(oPlayer, table.unpack(lArgs), sProductKey)
    else
        global.oPubMgr:OnlineExecute(iPid, "PayForGold", {iAmount, lArgs, sProductKey})
    end
end

function CPayCb:pay_for_huodong_charge(iPid, iAmount, lArgs, sProductKey)
    local oHuodong = global.oHuodongMgr:GetHuodong("charge")
    assert(oHuodong, "ERROR not charge object")

    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oHuodong:OnCharge(oPlayer, iAmount, table.unpack(lArgs), sProductKey)
    else
        global.oPubMgr:OnlineExecute(iPid, "PayForHuodongCharge", {iAmount, lArgs, sProductKey})
    end
end


function BanPlayerLogin(iPid, iSecond)
    local mData = {ban_time = get_time() + 9999999}
    local mInfo = {
        module = "playerdb",
        cmd = "SavePlayerMain",
        cond = {pid = iPid},
        data = {data = mData},
    }
    gamedb.SaveDb(iPid, "common", "DbOperate", mInfo)
end

function PlayerLogin(iPid, iSecond)
    local mData = {ban_time = get_time() - 1}
    local mInfo = {
        module = "playerdb",
        cmd = "SavePlayerMain",
        cond = {pid = iPid},
        data = {data = mData},
    }
    gamedb.SaveDb(iPid, "common", "DbOperate", mInfo)
end