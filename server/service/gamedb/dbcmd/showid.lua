local global = require "global"
local interactive = require "base.interactive"

local sTableName = "showid"

function SaveShowIdByIdx(mCond, mData)
    local oGameDb = global.oGameDb
    local mCondition = {show_id = mCond.show_id}
    local mOperation = {["$set"] = {data = mData.data}}
    local bUpsert = true
    oGameDb:Update(sTableName, mCondition, mOperation, bUpsert)
end

function LoadAllShowId(mCond, mData)
    local oGameDb = global.oGameDb
    local mCondition = {show_id = {["$exists"] = true}}
    local mOutput = {show_id = true, data = true}
    local m = oGameDb:Find(sTableName, mCondition, mOutput)
    local mResult = {}
    while m:hasNext() do
        local mInfo = m:next()
        mInfo._id = nil
        table.insert(mResult, mInfo)
    end
    return {data = mResult}
end