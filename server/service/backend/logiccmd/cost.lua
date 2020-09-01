--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function PostCostInfo(mRecord, mData)

    local oCostObj = global.oCostObj

    local br, m = safe_call(oCostObj.PostCostInfo, oCostObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end
