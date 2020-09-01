--import module

local global = require "global"
local skynet = require "skynet"
local playersend = require "base.playersend"
local interactive = require "base.interactive"
local record = require "public.record"

local bigpacket = import(lualib_path("public.bigpacket"))
local tinsert = table.insert

function NewProxy(...)
    local o = CProxy:New(...)
    return o
end

CProxy = {}
CProxy.__index = CProxy
inherit(CProxy, logic_base_cls())

function CProxy:New()
    local o = super(CProxy).New(self)
    return o
end

function CProxy:Init()
end