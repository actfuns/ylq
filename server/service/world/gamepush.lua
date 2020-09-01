local global = require "global"
local httpuse = require "public.httpuse"
local record = require "public.record"
local md5 = require "md5"
local interactive = require "base.interactive"

local gamedb = import(lualib_path("public.gamedb"))
local urldefines = import(lualib_path("public.urldefines"))

function NewGamePushMgr(...)
    local o = CGamePushMgr:New(...)
    return o
end

CGamePushMgr = {}
CGamePushMgr.__index = CGamePushMgr
inherit(CGamePushMgr, logic_base_cls())

function CGamePushMgr:New()
    local o = super(CGamePushMgr).New(self)
    o.m_mData = {}
    return o
end

function CGamePushMgr:NewHour(iDay,iHour)
    local mData = {
        weekday = iDay,
        hour = iHour
    }
    interactive.Send(".gamepush","common","NewHour",mData)
end