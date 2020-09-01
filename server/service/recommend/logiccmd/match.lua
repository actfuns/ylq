--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function EnterMatch(mRecord,mData)
    local oMgr = global.oMatchMgr
    local sName = mData.name
    local oMatch = oMgr:GetMatch(sName)
    if oMatch then
        local mRespond =oMatch:Enter(mData.id,mData.data or {})
        if mRespond and mData.respond then
            interactive.Response(mRecord.source, mRecord.session, mRespond)
        end
    end
end

function LeaveMatch(mRecord,mData)
    local oMgr = global.oMatchMgr
    local sName = mData.name
    local oMatch = oMgr:GetMatch(sName)
    if oMatch then
        local mRespond = oMatch:Leave(mData.id,mData.data or {})
        if mRespond and mData.respond then
            interactive.Response(mRecord.source, mRecord.session, mRespond)
        end
    end
end

function CleanCach(mRecord,mData)
    local oMgr = global.oMatchMgr
    local sName = mData.name
    local oMatch = oMgr:GetMatch(sName)
    if oMatch then
        oMatch:Clear(mData.data or {})
    end
end

function StartMatch(mRecord,mData)
    local oMgr = global.oMatchMgr
    local sName = mData.name
    local oMatch = oMgr:GetMatch(sName)
    if oMatch then
        oMatch:StartMatch(mData.data or {})
    end
end

function StopMatch(mRecord,mData)
    local oMgr = global.oMatchMgr
    local sName = mData.name
    local oMatch = oMgr:GetMatch(sName)
    if oMatch then
        oMatch:StopMatch(mData.data or {})
    end
end

function InMatch(mRecord,mData)
    local oMgr = global.oMatchMgr
    local sName = mData.name
    local oMatch = oMgr:GetMatch(sName)
    if oMatch then
        local mRespond = oMatch:InMatch(mData.pid,mData.data or {})
        interactive.Response(mRecord.source, mRecord.session, mRespond)
    end
end


