--import module
local global = require "global"
local skynet = require "skynet"

function RemoteEvent(mRecord, mData)
    local sEventName = mData.event
    local m = mData.data
    local oSceneMgr = global.oSceneMgr
    oSceneMgr:RemoteEvent(sEventName, m)
end
