--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local extend = require "base.extend"

local onlineobj = import(service_path("onlineobj"))

function realTimeOnlineData(mRecord, mData)
    local br, mRet = safe_call(onlineobj.realTimeOnlineData, mData)
    
    if br then
        interactive.Response(mRecord.source, mRecord.session, mRet)
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function intervalOnlineStat(mRecord, mData)
    local br, mRet = safe_call(onlineobj.intervalOnlineStat, mData)

    if br then
        interactive.Response(mRecord.source, mRecord.session, mRet)
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function onlineHistory(mRecord, mData)
    local br, mRet = safe_call(onlineobj.onlineHistory, mData)

    if br then
        interactive.Response(mRecord.source, mRecord.session, mRet)
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function getCreateSsoAccountCount(mRecord, mData)
    local br, mRet = safe_call(onlineobj.getCreateSsoAccountCount, mData)
    
    if br then
        interactive.Response(mRecord.source, mRecord.session, mRet)
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end
