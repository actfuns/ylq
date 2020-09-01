local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local record = require "public.record"
local extend = require "base.extend"
local fstring = require "public.colorstring"

local gamedefines = import(lualib_path("public.gamedefines"))

local itembase = import(service_path("item/other/i13270"))
local loaditem = import(service_path("item/loaditem"))
local itemdefines = import(service_path("item/itemdefines"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    o.m_iStage = 3
    return o
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end