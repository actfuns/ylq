local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))
local itembase = import(service_path("item/other/i11501"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

