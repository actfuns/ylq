--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function MergeAchieve(mRecord, mData)
    local oAchieveMgr = global.oAchieveMgr
    local r, msg = oAchieveMgr:MergeFrom(mData)
    local errmsg
    if not r then
        errmsg = "global achieve merge failed : "..msg
    end
    interactive.Response(mRecord.source, mRecord.session, {
        err = errmsg,
    })
end