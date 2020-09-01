--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local extend = require "base.extend"

local overviewobj = import(service_path("overviewobj"))

function PostOverViewData(mRecord, mData)
    local br, mRet = safe_call(overviewobj.PostOverViewData, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, mRet)
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end