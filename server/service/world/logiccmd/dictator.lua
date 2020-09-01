--import module
local global = require "global"
local skynet = require "skynet"

function CloseGS(mRecord, mData)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:CloseGS()
end
