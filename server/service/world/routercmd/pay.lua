--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"

function TryPayCb(mRecord, mData)
    local oPayMgr = global.oPayMgr
    oPayMgr:TryPayCb(mData.pid, mData.pay_info)
end

function PaySuccessedCb(mRecord, mData)
    if global.oWorldMgr:IsClose() then
        print("CPayMgr:PaySuccessedCb--OnClose--", mData)
        return
    end

    local oPayMgr = global.oPayMgr
    oPayMgr:PaySuccessedCb(mData.pid, mData.order_infos)
end

function ClientQrpayScan(mRecord, mData)
    local oPayMgr = global.oPayMgr
    oPayMgr:ClientQrpayScan(mData.pid, mData.transfer_info)
end
function DealSucceedOrder(iPid, mOrders)
    local oPayMgr = global.oPayMgr
	print(mOrders)
    oPayMgr:DealSucceedOrder(mOrders.iPid, mOrders.mOrders)
end