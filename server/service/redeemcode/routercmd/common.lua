--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"


ForwardCmd = {}
function ForwardCmd.CommonTest(mRecord, mData)
    local mRet = {
        errcode = 0,
        errmsg = "success"
    }
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function ForwardCmd.SaveRedeemRuleInfo(mRecord, mData, fCallBack)
    local oRedeemMgr = global.oRedeemCodeMgr
    local br, m = safe_call(oRedeemMgr.SaveRedeemRuleInfo, oRedeemMgr, mData)
    if br then
        fCallBack({errcode=0, data=m})
    else
        fCallBack({errcode=1})
    end
end

function ForwardCmd.GetAllRedeemRuleInfo(mRecord, mData, fCallBack)
    local oRedeemMgr = global.oRedeemCodeMgr
    local br, m = safe_call(oRedeemMgr.GetAllRedeemRuleInfo, oRedeemMgr)
    if br then
        fCallBack({errcode=0, data=m})
    else
        fCallBack({errcode=1})
    end
end

function ForwardCmd.MakeRedeemCode(mRecord, mData, fCallBack)
    global.oRedeemCodeMgr:MakeRedeemCode(mData, fCallBack)
end

function ForwardCmd.GetBatchInfoByRedeemId(mRecord, mData, fCallBack)
    local iRedeem = mData["redeem_id"]
    local oRedeemMgr = global.oRedeemCodeMgr
    local br, m = safe_call(oRedeemMgr.GetBatchInfoByRedeemId, oRedeemMgr, iRedeem)
    if br then
        fCallBack({errcode=0, data=m})
    else
        fCallBack({errcode=1})
    end
end

function ForwardCmd.GetRedeemCodeByBatchId(mRecord, mData, fCallBack)
    local iBatch = mData["batch_id"]
    local oRedeemMgr = global.oRedeemCodeMgr
    local br, m = safe_call(oRedeemMgr.GetRedeemCodeByBatchId, oRedeemMgr, iBatch)
    if br then
        fCallBack({errcode=0, data=m})
    else
        fCallBack({errcode=1})
    end
end

function ForwardCmd.UseRedeemCode(mRecord, mData, fCallBack)
    global.oRedeemCodeMgr:UseRedeemCode(mData, fCallBack)
end

function ForwardCmd.FindCodeExchangeLog(mRecord, mData, fCallBack)
    local m = global.oRedeemCodeMgr:FindCodeExchangeLog(mData.code)
    fCallBack({data=m})
end

function ForwardCmd.FindPlayerExchangeLog(mRecord, mData, fCallBack)
    local m = global.oRedeemCodeMgr:FindPlayerExchangeLog(mData.pid)
    fCallBack({data=m})
end


function Forward(mRecord, mData)
    local sCmd = mData["cmd"]
    local mArgs = mData["data"]
    local func = ForwardCmd[sCmd]

    if not func then
        local mRet = {
            errcode = 1,
            errmsg = "world service call error"   
        }
        router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
        return
    end

    local fCallBack = function (mRet)
        router.Response(mRecord.srcsk, mRecord.src, mRecord.session, {
            errcode = mRet.errcode or 0,
            errmsg = mRet.errmsg or "",
            data = mRet.data or {}
        })    
    end
    func(mRecord, mArgs, fCallBack)
end
