--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"


function ActivePlayer(mRecord,mData)
    local oPlayerStatObj = global.oPlayerStatObj

    local br,m = safe_call(oPlayerStatObj.ActivePlayer,oPlayerStatObj,mData)
    if br then
        interactive.Response(mRecord.source,mRecord.session,{
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source,mRecord.session,{
            errcode = 1,
        })
    end
end

function AccountRetention(mRecord,mData)
    local oPlayerStatObj = global.oPlayerStatObj

    local br,m = safe_call(oPlayerStatObj.AccountRetention,oPlayerStatObj,mData)
    if br then
        interactive.Response(mRecord.source,mRecord.session,{
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source,mRecord.session,{
            errcode = 1,
        })
    end
end

function RoleRetention(mRecord,mData)
    local oPlayerStatObj = global.oPlayerStatObj

    local br, m = safe_call(oPlayerStatObj.RoleRetention, oPlayerStatObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function DeviceRetention(mRecord,mData)
    local oPlayerStatObj = global.oPlayerStatObj

    local br, m = safe_call(oPlayerStatObj.DeviceRetention, oPlayerStatObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function OnlineDistribute(mRecord,mData)
    local oPlayerStatObj = global.oPlayerStatObj

    local br, m = safe_call(oPlayerStatObj.OnlineDistribute, oPlayerStatObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function levelDistribute(mRecord,mData)
    local oPlayerStatObj = global.oPlayerStatObj

    local br, m = safe_call(oPlayerStatObj.levelDistribute, oPlayerStatObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function ModelDistribute(mRecord,mData)
    local oPlayerStatObj = global.oPlayerStatObj

    local br, m = safe_call(oPlayerStatObj.ModelDistribute, oPlayerStatObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function DateLoss(mRecord,mData)
    local oPlayerStatObj = global.oPlayerStatObj

    local br, m = safe_call(oPlayerStatObj.DateLoss, oPlayerStatObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function LevelLoss(mRecord,mData)
    local oPlayerStatObj = global.oPlayerStatObj

    local br, m = safe_call(oPlayerStatObj.LevelLoss, oPlayerStatObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function createDayLoss(mRecord,mData)
    local oPlayerStatObj = global.oPlayerStatObj

    local br, m = safe_call(oPlayerStatObj.createDayLoss, oPlayerStatObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function missionLoss(mRecord,mData)
    local oPlayerStatObj = global.oPlayerStatObj

    local br, m = safe_call(oPlayerStatObj.missionLoss, oPlayerStatObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = m.errcode,
            data = m.data,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function RecordClientLog(mRecord, mData)
    if mData.operator then
        local mLogData = {}
        mLogData.operator = mData.operator
        mLogData.account = mData.account
        mLogData.channel = mData.channel
        mLogData.device = mData.device
        mLogData.error = mData.error
        mLogData.net = mData.net
        mLogData.pid = mData.pid
        mLogData.time = mData.time
        record.user("behavior", "behavior", mLogData)
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end