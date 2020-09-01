local global = require "global"
local extend = require "base.extend"

function SyncPunish(mRecord, mData)
    mData = extend.Table.deserialize(mData)
    local oPunishMgr = global.oPunishMgr
    oPunishMgr:SyncPunish(mData)
end