--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

function NewNotifyMgr(...)
    return CNotifyMgr:New(...)
end


CNotifyMgr = {}
CNotifyMgr.__index = CNotifyMgr
inherit(CNotifyMgr,logic_base_cls())

function CNotifyMgr:New()
    local o = super(CNotifyMgr).New(self)
    return o
end

function CNotifyMgr:Notify(iPid, sMsg)
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CNotify", {
            cmd = sMsg,
        })
    end
end

--iTag 0-公告 1-传闻 2-帮助
function CNotifyMgr:SendSysChat(sMsg, iTag, iHorse, mExclude)
    local mNet = {
        content = sMsg,
        tag_type = iTag,
        horse_race = iHorse,
    }
    local mData = {
        message = "GS2CSysChat",
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        data = mNet,
        exclude = mExclude,
    }
    interactive.Send(".broadcast", "channel", "SendChannel", mData)
end
