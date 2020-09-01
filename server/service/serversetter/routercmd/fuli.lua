--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"
local record = require "public.record"

function FuliPass(mRecord, mData)
    local oFuliMgr = global.oFuliMgr
    local br, m = safe_call(oFuliMgr.FuliPass, oFuliMgr, mData.account)
    local mRet = {}
    if not br then
        record.error("FuliPass error "..mData.account)
    end
end

function HasTestFuliAuth(mRecord, mData)
    local oFuliMgr = global.oFuliMgr
    local br, pass = safe_call(oFuliMgr.HasTestFuliAuth, oFuliMgr, mData.account)
    local mRet = {}
    if not br then
        mRet = {pass=false}
    else
        mRet = {pass=pass}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function ChargeAct(mRecord, mData)
    local oFuliMgr = global.oFuliMgr
    local br, m = safe_call(oFuliMgr.ChargeAct, oFuliMgr, mData.account, mData.add)
    local mRet = {}
    if not br then
        record.error("ChargeAct error "..mData.account)
    end
end

function GetActCharge(mRecord, mData)
    local oFuliMgr = global.oFuliMgr
    local br, iAdd = safe_call(oFuliMgr.GetActCharge, oFuliMgr, mData.account)
    local mRet = {}
    if not br then
        mRet = {add=0}
    else
        mRet = {add=iAdd}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function SetBackPartner(mRecord, mData)
    local oFuliMgr = global.oFuliMgr
    local br, m = safe_call(oFuliMgr.SetBackPartner, oFuliMgr, mData.account, mData.sid, mData.star)
    local mRet = {}
    if not br then
        record.error("ChargeAct error "..mData.account)
    end
end

function GetBackPartner(mRecord, mData)
    local oFuliMgr = global.oFuliMgr
    local br, mInfo = safe_call(oFuliMgr.GetBackPartner, oFuliMgr, mData.account)
    local mRet = {}
    if not br then
        mRet = {}
    else
        mRet = {info=mInfo}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function UpdateChargeBack(mRecord, mData)
    local oFuliMgr = global.oFuliMgr
    local br, m = safe_call(oFuliMgr.UpdateChargeBack, oFuliMgr, mData.account, mData.info)
    local mRet = {}
    if not br then
        record.error("UpdateChargeBack error "..mData.account)
        print ("zljdebug----",mData.info)
    end
end

function QueryChargeBack(mRecord, mData)
    local oFuliMgr = global.oFuliMgr
    local br, mInfo = safe_call(oFuliMgr.QueryChargeBack, oFuliMgr, mData.account)
    local mRet = {}
    if not br then
        mRet = {info={}}
    else
        mRet = {info=mInfo}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function UpdateRushRankBack(mRecord, mData)
    mData = mData or {}
    local oFuliMgr = global.oFuliMgr
    oFuliMgr:UpdateRushRankBack(mData.data)
end

function QueryRushRank(mRecord, mData)
    local oFuliMgr = global.oFuliMgr
    local br, mInfo = safe_call(oFuliMgr.QueryRushRank, oFuliMgr, mData.account)
    local mRet = {}
    if not br then
        mRet = {info={}}
    else
        mRet = {info=mInfo}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end