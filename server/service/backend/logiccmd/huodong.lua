--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local huodong = import(service_path("huodong"))


function SetHuodongOpen(mRecord, mData)
    local br, m = safe_call(huodong.SetHuodongOpen, mData, function(mRet)
        interactive.Response(mRecord.source, mRecord.session,mRet)
    end)
    if not br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
            errmsg = "backend call failed",
            data = {},
        })
    end
end

function QueryLimitHuodong(mRecord, mData)
    local br, m = safe_call(huodong.QueryLimitHuodong, mData, function(mRet)
        interactive.Response(mRecord.source, mRecord.session, mRet)
    end)
    if not br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
            errmsg = "backend call failed",
            data = {},
        })
    end
end

function QueryOpenHuodong(mRecord, mData)
    local br, m = safe_call(huodong.QueryOpenHuodong, mData, function(mRet)
        interactive.Response(mRecord.source, mRecord.session, mRet)
    end)
    if not br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
            errmsg = "backend call failed",
            data = {},
        })
    end
end