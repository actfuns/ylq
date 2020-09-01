local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local itembase = import(service_path("item/itembase"))

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "parstone"

function CItem:EquipPos()
    return self:GetItemData()["equip_pos"]
end

function CItem:Level()
    return self:GetItemData()["level"]
end

function CItem:StonePos()
    return self:GetItemData()["level"]
end

function CItem:GetApplys()
    local mAttr = {}
    local sValue = self:GetItemData()["attr"]
    if sValue and sValue ~= "" then
        mAttr = formula_string(sValue, {})
    end
    return mAttr
end

function CItem:IsMaxLevel()
    return self:Level() == 7
end