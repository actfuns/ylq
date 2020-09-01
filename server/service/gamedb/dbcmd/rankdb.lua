--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sRankTableName = "rank"


function SaveRankByName(mCond, mData)
    local oGameDb = global.oGameDb
    local mCondition = {name = mData.rank_name}
    local mOperation = {["$set"] = {rank_data = mData.data}}
    local bUpsert = true
    oGameDb:Update(sRankTableName, mCondition, mOperation, bUpsert)
end

function LoadRankByName(mCond, mData)
    local oGameDb = global.oGameDb
    local mCondition = {name = mData.rank_name}
    local mOutput = {rank_data = true}
    local m = oGameDb:FindOne(sRankTableName, mCondition, mOutput)

    local mResult
    if m then
        mResult = {data = m.rank_data}
    else
        mResult = {data = {}}
    end
    return mResult
end

function SaveRushRankByName(mCond, mData)
    local oGameDb = global.oGameDb
    local mCondition = {name = mData.rank_name}
    local mOperation = {["$set"] = {rank_data = mData.data}}
    local bUpsert = true
    oGameDb:Update("rush_rank", mCondition, mOperation, bUpsert)
end

function LoadRushRankByName(mCond, mData)
    local oGameDb = global.oGameDb
    local mCondition = {name = mData.rank_name}
    local mOutput = {rank_data = true}
    local m = oGameDb:FindOne("rush_rank", mCondition, mOutput)
    local mResult
    if m then
        mResult = {data = m.rank_data}
    else
        mResult = {data = {}}
    end
    return mResult
end