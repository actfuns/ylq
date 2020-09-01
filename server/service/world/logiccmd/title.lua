--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local res = require "base.res"

function CheckTitleCondition(mRecord, mData)
    local iPid,sType = mData.pid,mData.type
    local oTitleMgr = global.oTitleMgr
    oTitleMgr:CheckTitleByType(iPid,sType)
end

function AddTitle(mRecord,mData)
    local iPid = mData.pid
    local iTid = mData.tid
    local sName = mData.name
    local oTitleMgr = global.oTitleMgr
    oTitleMgr:AddTitle(iPid,iTid,sName)
end

function RemoveTitles(mRecord,mData)
    local iPid = mData.pid
    local lTids = mData.tidlist
    local sName = mData.name
    local oTitleMgr = global.oTitleMgr
    oTitleMgr:RemoveTitles(iPid,lTids)
end