--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"

ForwardCmd = {}

function ForwardCmd.GetNoPassImages(mRecord, mData)
    local oImageMgr = global.oImageMgr
    local br, mRet = safe_call(oImageMgr.GetNoPassImages, oImageMgr, function(lImages)
        router.Response(mRecord.srcsk, mRecord.src, mRecord.session, {errcode = 0, data =  lImages})
    end)
    if not br then
        local sErr = "gs:" .. get_server_tag() .. ", image service call failed"
        router.Response(mRecord.srcsk, mRecord.src, mRecord.session, {errcode = 2, errmsg = sErr})
    end
end

function ForwardCmd.CheckImagePass(mRecord, mData)
    local oImageMgr = global.oImageMgr
    local br, mRet = safe_call(oImageMgr.CheckImagePass, oImageMgr, mData)
    local mData = {errcode = 0}
    if not br then
        mData["errcode"] = 2
        mData["errmsg"] = "gs:" .. get_server_tag() .. ", image service call failed"
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mData)
end

function Forward(mRecord, mData)
    local sCmd = mData["cmd"]
    local func = ForwardCmd[sCmd]

    if func then
        func(mRecord, mData["data"])
    else
        DoCallFail(mRecord, mData)
    end
end

function DoCallFail(mRecord, mData)
    local sErr = "gs:" .. get_server_tag() .. mData["cmd"] .. ",function not exist!"
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, {errcode=3, errmsg = sErr})
end