--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"


function GetServerList(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    local br, m = safe_call(oSetterMgr.GetServerList, oSetterMgr)
    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1, data={}}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function SaveOrUpdateServer(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    local br, m = safe_call(oSetterMgr.SaveOrUpdateServer, oSetterMgr, mData)
    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1, data={}}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function DeleteServer(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    local ids = mData["ids"]
    local br, m = safe_call(oSetterMgr.DeleteServer, oSetterMgr, ids)

    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1, data={}}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function GetServerIndex(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    local br, m = safe_call(oSetterMgr.GetServerIndex, oSetterMgr)
    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1, data={}}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function SaveOrUpdateIndex(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    local br, m = safe_call(oSetterMgr.SaveOrUpdateIndex, oSetterMgr, mData)
    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1, data={}}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function DeleteIndex(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    local ids = mData["ids"]
    local br, m = safe_call(oSetterMgr.DeleteIndex, oSetterMgr, ids)

    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1, data={}}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function GetWhiteAccountList(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    local br, m = safe_call(oSetterMgr.GetWhiteAccountList, oSetterMgr)

    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1, data={}}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function SaveWhiteAccount(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    local mArgs = mData["data"]
    local br, m = safe_call(oSetterMgr.SaveWhiteAccount, oSetterMgr, mArgs)

    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1, data={}}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function DeleteWhiteAccount(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    local ids = mData["ids"]
    local br, m = safe_call(oSetterMgr.DeleteWhiteAccount, oSetterMgr, ids)

    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1, data={}}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function SaveOrUpdateNotice(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    oSetterMgr:SaveOrUpdateNotice(mData)
end

function GetNoticeList(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    local br, m = safe_call(oSetterMgr.GetNoticeList, oSetterMgr)
    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1, data={}}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function DeleteNotice(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    oSetterMgr:DeleteNotice(mData["ids"])
end

function PublishNotice(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    oSetterMgr:PublishNotice(mData["ids"])
end

function GetChannelList(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    local br, m = safe_call(oSetterMgr.GetChannelList, oSetterMgr)
    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1, data={}}
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end