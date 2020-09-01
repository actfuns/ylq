--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local extend = require "base.extend"
local router = require "base.router"


function GetServerList(mRecord, mData)
    router.Request("cs", ".serversetter", "common", "GetServerList", {}, function (r, d)
        interactive.Response(mRecord.source, mRecord.session, d)
    end)
end

function SaveOrUpdateServer(mRecord, mData)
    router.Request("cs", ".serversetter", "common", "SaveOrUpdateServer", mData, function (r, d)
        interactive.Response(mRecord.source, mRecord.session, d)
    end)
end

function DeleteServer(mRecord, mData)
    router.Request("cs", ".serversetter", "common", "DeleteServer", mData, function (r, d)
        interactive.Response(mRecord.source, mRecord.session, d)
    end)
end

function GetServerIndex(mRecord, mData)
    router.Request("cs", ".serversetter", "common", "GetServerIndex", {}, function (r, d)
        interactive.Response(mRecord.source, mRecord.session, d)
    end)
end

function SaveOrUpdateIndex(mRecord, mData)
    router.Request("cs", ".serversetter", "common", "SaveOrUpdateIndex", mData, function (r, d)
        interactive.Response(mRecord.source, mRecord.session, d)
    end)
end

function DeleteIndex(mRecord, mData)
    router.Request("cs", ".serversetter", "common", "DeleteIndex", mData, function (r, d)
        interactive.Response(mRecord.source, mRecord.session, d)
    end)
end

function GetChannelList(mRecord, mData)
    router.Request("cs", ".serversetter", "common", "GetChannelList", mData, function (r, d)
        interactive.Response(mRecord.source, mRecord.session, d)
    end)
end

function SaveOrUpdateChannel(mRecord, mData)
    interactive.Response(mRecord.source, mRecord.session, {errcode=1, errmsg="close", data={}})
end

function DeleteChannel(mRecord, mData)
    interactive.Response(mRecord.source, mRecord.session, {errcode=1, errmsg="close", data={}})
end

function GetGmAccountList(mRecord, mData)
    router.Request("cs", ".serversetter", "common", "GetWhiteAccountList", mData, function (r, d)
        interactive.Response(mRecord.source, mRecord.session, d)
    end)
end

function SaveGmAccount(mRecord, mData)
    router.Request("cs", ".serversetter", "common", "SaveWhiteAccount", mData, function (r, d)
        interactive.Response(mRecord.source, mRecord.session, d)
    end)
end

function DeleteGmAccount(mRecord, mData)
    router.Request("cs", ".serversetter", "common", "DeleteWhiteAccount", mData, function (r, d)
        interactive.Response(mRecord.source, mRecord.session, d)
    end)
end

function GetResourceInfo(mRecord, mData)
    local oBackendInfoMgr = global.oBackendInfoMgr
    local sType = mData["type"]
    local br, m = safe_call(oBackendInfoMgr.GetResourceInfo, oBackendInfoMgr, sType)

    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1, data={}}
    end
    interactive.Response(mRecord.source, mRecord.session, mRet)
end