--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function GenPlayerId(mRecord, mData)
    local oPlayerIdMgr = global.oPlayerIdMgr
    local id = oPlayerIdMgr:GenPlayerId()
    interactive.Response(mRecord.source, mRecord.session, {
        id = id,
    })
end