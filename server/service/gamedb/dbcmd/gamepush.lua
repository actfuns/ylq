local global = require "global"
local interactive = require "base.interactive"

local sTableName = "gamepush"

function SetXGToken(mCond,mData)
    local oGameDb = global.oGameDb
    local iPid = mData.pid
    local m = oGameDb:FindOne(sTableName, {pid = iPid}, {})
    if m and m.pid then
        oGameDb:Update(sTableName, {pid=iPid},{["$set"]=mData})
    else
        oGameDb:Insert(sTableName, mData)
    end
end

function GetXGToken(mCond,mData)
    local oGameDb = global.oGameDb
    local iPid = mData.pid
    local m = oGameDb:FindOne(sTableName, {pid = iPid}, {})
    return {
        data = m,
        pid = iPid,
    }
end

function DeleteXGToken(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Delete(sTableName, {pid = mData.pid})
end