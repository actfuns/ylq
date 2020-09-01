--import module
local global = require "global"
local skynet = require "skynet"

function ApplySendP2P(mRecord, mData)
    local oClientMgr = global.oClientMgr
    oClientMgr:SendP2P(mData.record, mData.data)
end
