local global = require "global"
local skynet = require "skynet"
local res = require "base.res"
local record = require "public.record"
local itembase = import(service_path("item.other.otherbase"))
local itemdefines = import(service_path("item/itemdefines"))
local HUODONG_TREASURE_NAME = "treasure"


function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end