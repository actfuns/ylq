--import module
local global = require "global"
local skynet = require "skynet"

function UpdateRelationInfo(mRecord,mData)
    local oRelationMgr = global.oRelationMgr
    oRelationMgr:UpdateRelationInfo(mData.pid,mData.info)
end

function RecommendFriend(mRecord,mData)
    local oRelationMgr = global.oRelationMgr
    oRelationMgr:RecommendFriend(mData.pid,mData.arg,mRecord)
end

function ClearAllCache(mRecord, mData)
    local oRelationObj = global.oRelationObj
    oRelationObj:ClearAllCache()
end

