--import module
local global = require "global"
local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))
local colorstring = require "public.colorstring"

function ChannelNotify(mRecord,mData)
    local iType = mData.type
    local iId = mData.id
    local iPid = mData.pid
    local mNet = mData.data or {}
    local lMessage = mData.message or {}
    local sContent = mNet.content
    local mArgs = mNet.args
    local mExclude = mData.exclude or {}
    local sMsg
    if mArgs then
        sMsg = colorstring.FormatColorString(sContent, mArgs)
    else
        sMsg = sContent
    end
    local oChannel = global.mChannels[iType][iId]
    if not oChannel then
        return
    end
    if iPid then
        local oChannelMember = oChannel:Get(iPid)
        if not oChannelMember then
            return
        end
        ChannelSend(oChannelMember,lMessage,sMsg,mNet)
    else
        ChannelSend(oChannel,lMessage,sMsg,mNet,mExclude)
    end
end

function ChannelSend(oSend,lMessage,sContent,mNet,mExclude)
    for _,sMessage in pairs(lMessage) do
        local mData
        if sMessage == "GS2CNotify" then
            mData = NotifyData(sContent)
        elseif sMessage == "GS2CChat" then
            mData = ChatData(sContent,mNet)
        else
            mData = NotifyMessageData(sContent)
        end
        oSend:Send(sMessage,mData,mExclude)
    end
end

function NotifyData(sContent)
    return {
        cmd = sContent
    }
end

function NotifyMessageData(sContent)
    return {
        type = gamedefines.CHANNEL_TYPE.MSG_TYPE,
        content = sContent,
    }
end

function ChatData(sContent,mNet)
    return {
        type = gamedefines.CHANNEL_TYPE.TEAM_TYPE,
        cmd = sContent,
        role_info = mNet.role_info
    }
end