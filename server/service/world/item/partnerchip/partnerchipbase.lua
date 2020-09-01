local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local itembase = import(service_path("item/itembase"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "partnerchip"

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

function CItem:New(sid)
    local o = super(CItem).New(self, sid)
    return o
end

function CItem:PartnerType()
    local mData = self:GetItemData()
    return mData.partner_type
end

function CItem:CoinCost()
    local mData = self:GetItemData()
    return mData.coin_cost
end