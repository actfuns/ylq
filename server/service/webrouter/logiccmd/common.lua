--import module
local global = require "global"
local skynet = require "skynet"
local httpc = require "http.httpc"
local interactive = require "base.interactive"
local record = require "public.record"

function HttpRequest(mRecord, mData)
    local br, rr1, rr2, rr3 = safe_call(function ()
        local sMethod = mData.method or "GET"
        local sHost = assert(mData.host, "HttpRequest no host")
        local sUrl = mData.url or "/"
        local mHeader = mData.header
        local sContent = mData.content
        local mRecvHeader = {}
        local iCode, sBody = httpc.request(sMethod, sHost, sUrl, mRecvHeader, mHeader, sContent)
        return iCode, sBody, mRecvHeader
    end)
    if not br then
        record.error(string.format("HttpRequest error:%s", rr1))
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
            statuscode = rr1,
            body = rr2,
            header = rr3,
        })
    end
end
