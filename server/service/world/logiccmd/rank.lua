--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function KeepUpvoteShowRank(mRecord, mData)
    local mShowRank = mData.show_rank or {}
    local sRankName = mData.rank_name or ""
    local oRankMgr = global.oRankMgr
    oRankMgr:SetUpvoteShowRank(sRankName, mShowRank)
end

function SendRankReward(mRecord, mData)
    local oRankMgr = global.oRankMgr
    local sRankName = mData.name
    local iMailId = mData.mailid
    oRankMgr:SendRankReward(sRankName, mData.data,iMailId)
end

function SendSimpleRankData(mRecord, mData)
    local oRankMgr = global.oRankMgr
    local iRankIdx = mData.idx
    oRankMgr:SetRankSimpleData(iRankIdx, mData.data)
end

function SendTerraServReward(mRecord,mData)
    local oRankMgr = global.oRankMgr
    local sRankName = mData.name
    oRankMgr:SendTerraServReward(sRankName, mData.data)
end

function SendRushRankReward(mRecord, mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:SendRushRankReward(mData.rank or {})
end

function SendRankBack(mRecord, mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:SendRankBack(mData.rank or {})
end