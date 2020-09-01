--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local extend = require "base.extend"

local queryobj = import(service_path("queryobj"))

function PostQueryData(mRecord, mData)
    local br, mRet = safe_call(queryobj.PostQueryData, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, mRet)
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function PullData(mRecord,mData)
    local br, mRet = safe_call(queryobj.PullData, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, mRet)
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end