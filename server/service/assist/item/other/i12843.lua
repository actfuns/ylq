local global = require "global"
local skynet = require "skynet"
local res = require "base.res"

local itembase = import(service_path("item/other/commonbox"))
local itemdefines = import(service_path("item/itemdefines"))
local loaditem = import(service_path("item/loaditem"))

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