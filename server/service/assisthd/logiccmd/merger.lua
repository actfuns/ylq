--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function MergeAssistHD(mRecord, mData)
    local sName = mData.name
    local mFromData = mData.rank_data

    local sErrMsg
    local oAssistDHMgr = global.oAssistDHMgr
    local oHuodong = oAssistDHMgr:GetHuodong(sName)
    if oHuodong then
        local r, msg = oHuodong:MergeFrom(mFromData)
        if not r then
            sErrMsg = string.format("assisthd %s merge failed : %s", sName, msg)
        end
    else
        sErrMsg = string.format("assisthd %s merge failed : no such assisthd", sName)
    end
    interactive.Response(mRecord.source, mRecord.session, {
        err = sErrMsg,
    })
end






