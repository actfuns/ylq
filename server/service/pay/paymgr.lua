-- import module

local global = require "global"
local res = require "base.res"
local cjson = require "cjson"
local bson = require "bson"
local crypt = require "crypt"
local httpuse = require "public.httpuse"
local record = require "public.record"
local router = require "base.router"
local extend = require "base.extend"
local mongoop = require "base.mongoop"

local interactive = require "base.interactive"
local serverdefines = require "public.serverdefines"
local urldefines = import(lualib_path("public.urldefines"))



function NewPayMgr(...)
    return CPayMgr:New(...)
end

CPayMgr = {}
CPayMgr.__index = CPayMgr
inherit(CPayMgr, logic_base_cls())

CPayMgr.c_sRequestTableName = "requestpay"
CPayMgr.c_sPayTableName = "pay"

function CPayMgr:New()
    local o = super(CPayMgr).New(self)
    o.m_lRequest = {}
    return o
end

function CPayMgr:InsertRequestOrder(mOrder)
    mongoop.ChangeBeforeSave(mOrder)
    return global.oGameDb:Insert(self.c_sRequestTableName, mOrder)
end

function CPayMgr:QueryRequestOrder(iOrderId)
    local mData = global.oGameDb:FindOne(self.c_sRequestTableName, {orderId = iOrderId})
    if mData then
        mongoop.ChangeAfterLoad(mData)
    end
    return mData
end

function CPayMgr:DeleteRequestOrder(iOrderId)
    return global.oGameDb:Delete(self.c_sRequestTableName, {orderId = iOrderId})
end

function CPayMgr:InsertOrder(mOrder)
    mongoop.ChangeBeforeSave(mOrder)
    return global.oGameDb:Insert(self.c_sPayTableName, mOrder)
end

function CPayMgr:UpdateOrder(iOrderId, mInfo)
    mongoop.ChangeBeforeSave(mInfo)
    return global.oGameDb:Update(self.c_sPayTableName, {orderid = iOrderId}, {["$set"] = mInfo},true)
end

function CPayMgr:QueryUntreatedOrderByPid(iPid)
    local m = global.oGameDb:Find(self.c_sPayTableName, {pid = iPid, deal = 0})
    local mRet = {}
    while m:hasNext() do
        table.insert(mRet, m:next())
    end
    return mRet
end

function CPayMgr:HasPay(iPid)
    if not iPid then
        return false
    end
    local m = global.oGameDb:FindOne(self.c_sPayTableName, {pid = iPid})
    if m then
        return true
    else
        return false
    end
end

function CPayMgr:TryPay(sServerTag, mRequest)
    if not sServerTag or not mRequest then
        return
    end
    table.insert(self.m_lRequest, {sServerTag, mRequest})
    self:CallDealPay()
end

function CPayMgr:CallDealPay()
    local f
    f = function ()
        self:DelTimeCb("DealPay")
        self:DealPay()
        if next(self.m_lRequest) then
            self:AddTimeCb("DealPay", 1000, f)
        end
    end
    if not self:GetTimeCb("DealPay") then
        self:AddTimeCb("DealPay", 1000, f)
    end
end

function CPayMgr:DealPay()
    local oDemiSdk = global.oDemiSdk

    local sHost = urldefines.get_out_host()
    local sUrl = urldefines.get_demi_url("pre_pay")
    local mHeader = {}
    mHeader["Content-type"] = "application/x-www-form-urlencoded"

    local iDealCnt = math.min(oDemiSdk.m_oPayId:GetMaxSequence()/PAY_SERVICE_COUNT, #self.m_lRequest)
    for i = 1, iDealCnt do
        local sServerTag, mRequest = table.unpack(table.remove(self.m_lRequest, 1))
        mRequest.orderId = oDemiSdk:GeneratePayid()
        mRequest.sign = oDemiSdk:Sign(mRequest)
        local sParam = httpuse.mkcontent_kv(mRequest)
        httpuse.post(sHost, sUrl, sParam, function(body, header)
            self:_DealPay1(body, sServerTag, mRequest)
        end, mHeader)
    end
end

function CPayMgr:_DealPay1(sBody, sServerTag, mRequest)
    local iPid = mRequest.roleId
    local sProductKey = mRequest.productId
    local mRet = httpuse.content_json(sBody)
    if not next(mRet) then
        record.error("DealPay %s %s no response", iPid, sProductKey)
        return
    end
    if mRet.code ~= 0 then
        record.error("DealPay %s %s retcode:%s, msg:%s, reqeust:%s", iPid, sProductKey, mRet.code, mRet.msg, extend.Table.serialize(mRequest))
        return
    end
    if not mRet.item or not next(mRet.item) then
        record.error("DealPay %s %s item nil", iPid, sProductKey)
        return
    end

    -- 请求单存盘
    mRequest.create_time = bson.date(os.time())
    local bOk, sErr = self:InsertRequestOrder(mRequest)
    if not bOk then
        record.warning(sErr)
        return
    end

    local mCbInfo = mRet.item or {}
    local mPayInfo = {
        order_id = mRequest.orderId,
        itemId = mRequest.itemId,
        itemNum = mRequest.itemNum,
        product_key = mRequest.productId,
        product_amount = mRequest.amount,
        product_value = mRequest.cent,
        callback_url = mCbInfo.demiPayCallbackURL,
        cb_extra = mCbInfo.extraMap,
    }
    router.Send(sServerTag, ".world", "pay", "TryPayCb", {
        pid=iPid,
        pay_info=mPayInfo
    })
end

function CPayMgr:PayCallback(mCbInfo)
    local iPid = tonumber(mCbInfo.playerId)
    local product_key = mCbInfo.productId
    local itemID = tonumber(mCbInfo.itemId)
    local itmeNUM = tonumber(mCbInfo.itemNum)
    local times = tonumber(mCbInfo.times)
    local TYPe = tonumber(mCbInfo.TyPe)
    record.info(product_key)
    local mOrders = {
        orderid = 0,
        itemId = itemID,
        itemNum = itmeNUM,
        times = times,
        Type = TYPe,
        product_key = product_key,
        product_amount = 1,
        amount = 100,
    }
	interactive.Request(".datacenter", "common", "QueryRoleNowServer", {pid=iPid},
    function(mRecord, mData)
        --self:_PayCallback1(mData, iPid, mOrder)
		if not mData then
			record.error("PayCallback QueryRoleNowServer no data return: pid %d", iPid)
			return
		end
		if mData.errcode ~= 0 then
			record.error("PayCallback QueryRoleNowServer error %d: pid %d", mData.errcode, iPid)
			return
		end
		router.Send(mData.server, ".world", "pay", "DealSucceedOrder", {
			iPid=iPid,
			mOrders=mOrders
		})
    end)
end

function CPayMgr:_PayCallback1(mData, iPid, mOrder)
    if not mData then
        record.error("PayCallback QueryRoleNowServer no data return: pid %d", iPid)
        return
    end
    if mData.errcode ~= 0 then
        record.error("PayCallback QueryRoleNowServer error %d: pid %d", mData.errcode, iPid)
        return
    end
    self:SendOrder2GS(mData.server, iPid, {mOrder})
    self:PostInfo2Ad(iPid, mOrder)
end

function CPayMgr:SendOrder2GS(sServerTag, iPid, lOrders)
    router.Send(sServerTag, ".world", "pay", "PaySuccessedCb", {
        pid=iPid,
        order_infos=lOrders
    })
end

function CPayMgr:MarkOrderAsDealed(lOrderIds)
    for _, iOrderId in pairs(lOrderIds) do
        self:UpdateOrder(iOrderId, {deal=1})
    end
end

function CPayMgr:DealUntreatedOrder(iPid, sServer)
    local lOrders = self:QueryUntreatedOrderByPid(iPid)
    if lOrders and next(lOrders) then
        self:SendOrder2GS(sServer, iPid, lOrders)
    end
end

function CPayMgr:ClientQrpayScan(mData)
    local iPid = mData.pid
    local sServerKey = mData.server_key
    local sTransferInfo = httpuse.mkcontent_json(mData.transfer_info)

    router.Send(get_server_tag(sServerKey), ".world", "pay", "ClientQrpayScan", {
        pid=iPid,
        transfer_info=sTransferInfo,
    })
end

function CPayMgr:PostInfo2Ad(iPid, mOrder)
    --广告数据收集
    if mOrder and mOrder.request and mOrder.request.is_demi then
        local sHost = urldefines.get_out_host()
        local sUrl = urldefines.get_adapi_url("adapi")
        local mHeader = {}
        mHeader["Content-type"] = "application/x-www-form-urlencoded"
        local mAd = {
            ["do"] = "pay",
            app_id = mOrder.ext.ad_app_id,
            activity_id = mOrder.ext.active_id,
            system_id = mOrder.ext.system_id,
            user_name = mOrder.account,
            server_id = mOrder.serverkey,
            role_id = iPid,
            role_name = mOrder.ext.role_name,
            order_no = mOrder.orderid,
            amount = mOrder.amount,
            pay_time = get_time(),
        }
        local sParam = httpuse.mkcontent_kv(mAd)
        sParam = crypt.base64encode(sParam)
        local mPost = {
            data = sParam,
            sign = global.oDemiSdk:SignForAd(sParam),
        }
        local sPost = httpuse.mkcontent_kv(mPost)
        httpuse.post(sHost, sUrl, sPost, function(body, header)
            self:PostInfo2Ad1(body, iPid, mAd)
        end, mHeader)
    end
end

function CPayMgr:PostInfo2Ad1(sBody, iPid, mAd)
    local mBody = httpuse.content_json(sBody)
    if not next(mBody) then
        record.error("PostInfo2Ad1 %s %s no response", iPid, extend.Table.serialize(mAd))
        return
    end
    if mBody.code ~= 0 then
        record.error("PostInfo2Ad1 %s retcode:%s, msg:%s, reqeust:%s", iPid, mBody.code, mBody.message, extend.Table.serialize(mAd))
        return
    end
end

function Split(szFullString, szSeparator)  
local nFindStartIndex = 1  
local nSplitIndex = 1  
local nSplitArray = {}  
while true do  
   local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)  
   if not nFindLastIndex then  
    nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))  
    break  
   end  
   nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)  
   nFindStartIndex = nFindLastIndex + string.len(szSeparator)  
   nSplitIndex = nSplitIndex + 1  
end  
return nSplitArray  
end