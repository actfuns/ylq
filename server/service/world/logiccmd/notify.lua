--import module
local global = require "global"
local skynet = require "skynet"

function Notify(mRecord, mData)
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:Notify(mData.pid, mData.msg)
end
