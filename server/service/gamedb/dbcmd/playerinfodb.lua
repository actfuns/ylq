--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sPlayerInfoTableName = "playerinfo"

function SavePlayerInfo(mCond, mData)
    local oGameDb = global.oGameDb

    oGameDb:Update(sPlayerInfoTableName, {pid = mData.pid}, {["$set"]=mData.data}, true)
end