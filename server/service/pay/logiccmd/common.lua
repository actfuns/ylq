--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function PayCallback(mRecord, mData)
    local oPayMgr = global.oPayMgr
    oPayMgr:PayCallback(mData)
    interactive.Response(mRecord.source, mRecord.session, {ret="SUCCESS"})
end
