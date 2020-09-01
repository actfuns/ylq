local global = require "global"
local extend = require "base.extend"

function SyncPunish(mRecord, mData)
    mData = extend.Table.deserialize(mData)
    local oChatMgr = global.oChatMgr
    oChatMgr:SyncPunish(mData)
end