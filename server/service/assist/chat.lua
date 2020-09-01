--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local res = require "base.res"
local extend = require "base/extend"

local gamedefines = import(lualib_path("public.gamedefines"))
local analy = import(lualib_path("public.dataanaly"))

function NewChatMgr(...)
    local o=CChatMgr:New(...)
    return o
end

CChatMgr = {}
CChatMgr.__index = CChatMgr
inherit(CChatMgr,logic_base_cls())

function CChatMgr:New()
    local o = super(CChatMgr).New(self)
    return o
end

--消息频道
function CChatMgr:HandleMsgChat(oPlayer, sMsg)
    local iType = gamedefines.CHANNEL_TYPE.MSG_TYPE
    if oPlayer then
        oPlayer:Send("GS2CConsumeMsg", {type = iType, content = sMsg})
    end
end