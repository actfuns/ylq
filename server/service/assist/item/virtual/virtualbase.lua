local global = require "global"
local skynet = require "skynet"

local itembase = import(service_path("item/itembase"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "virtual"

function CItem:RealObj()
    -- body
end

function CItem:Reward()
    -- body
end

function CItem:GetMaxAmount()
    return 1
end

function CItem:GetShowInfo()
    return {
        id = self:ID(),
        sid = self:SID(),
        virtual = self:SID(),
        amount = self:GetData("value", 1),
    }
end

function CItem:GetRwardSid()
    return string.format("%s(value=%s)", self:SID(), self:GetData("value", 1))
end

function CItem:LogInfo()
    return {
        ["物品编号"] = self:SID(),
        ["数量"] = self:GetData("value", 1),
    }
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end