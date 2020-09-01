--import module
local global = require "global"
local skynet = require "skynet"
local record = require "public.record"
local interactive = require "base.interactive"

function StartOfflineTrapmine(mRecord,mData)
    local oAIMgr = global.oAIMgr
    local iPid = mData.pid
    oAIMgr:StartOfflineTrapmine(iPid,mData)
end

function StopOfflineTrapmine(mRecord,mData)
    local oAIMgr = global.oAIMgr
    local iPid = mData.pid
    oAIMgr:StopOfflineTrapmine(iPid)
end

function NotifyEnterWar(mRecord,mData)
    local oAIMgr = global.oAIMgr
    local iPid = mData.pid
    oAIMgr:NotifyEnterWar(iPid)
end

function NotifyLeaveWar(mRecord,mData)
    local oAIMgr = global.oAIMgr
    local iPid = mData.pid
    oAIMgr:NotifyLeaveWar(iPid)
end