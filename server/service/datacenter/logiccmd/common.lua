--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function GetRoleList(mRecord, mData)
    local sAccount = mData.account
    local lChannel = mData.channel
    local iPlatform = mData.platform
    local lServer = mData.server
    local mArgs = mData.args or {}
    local sPublisher = mArgs.publisher or "kaopu"

    local oDataCenter = global.oDataCenter
    local mRoleList = oDataCenter:GetRoleList(sAccount, lChannel,iPlatform,lServer,sPublisher)
    if mRoleList then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
            roles = mRoleList,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function QueryRoleNowServer(mRecord, mData)
    local iPid = mData.pid

    local oDataCenter = global.oDataCenter
    local sServerTag = oDataCenter:GetRoleNowServer(iPid)
    if sServerTag then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
            server = sServerTag,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end