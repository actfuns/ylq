--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function MergeRank(mRecord, mData)
    local sRank = mData.name
    local sRank, sKey = string.match(mData.name, "(%a+)(%d+)")
    local mFromData = mData.rank_data
    local mArgs
    if sKey then
        mArgs = {key = tonumber(sKey)}
    end

    local sErrMsg
    local oRankMgr = global.oRankMgr
    local oRank = oRankMgr:GetRankObjByName(sRank)
    if oRank then
        local r, msg = oRank:MergeFrom(mFromData, mArgs)
        if not r then
            sErrMsg = string.format("rank %s merge failed : %s", sRank, msg)
        end
    else
        sErrMsg = string.format("rank %s merge failed : no such rank", sRank)
    end
    interactive.Response(mRecord.source, mRecord.session, {
        err = sErrMsg,
    })
end

function MergeFinish(mRecord,mData)
    local oRankMgr = global.oRankMgr
    for idx, oRank in pairs(oRankMgr.m_mRankObj) do
        safe_call(oRank.MergeFinish, oRank)
    end
end