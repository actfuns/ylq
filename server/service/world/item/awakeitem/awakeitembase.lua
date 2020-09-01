local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local itembase = import(service_path("item/itembase"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "awakeitem"

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end


function CItem:New(sid)
    local o = super(CItem).New(self, sid)
    return o
end

function CItem:Composable()
    local mData = self:GetItemData()
    return mData.composable
end