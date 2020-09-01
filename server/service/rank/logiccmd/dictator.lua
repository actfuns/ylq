--import module

local global = require "global"
local skynet = require "skynet"

function CloseGS(mRecord, mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:CloseGS()
end
