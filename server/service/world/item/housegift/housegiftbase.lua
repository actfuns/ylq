local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local itembase = import(service_path("item/itembase"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "housegift"

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

--亲密度
function CItem:GetLoveShip()
    return self:GetItemData()["loveship"]
end

function CItem:GS2CItemAmount(mArgs)
    mArgs = mArgs or {}
    local mNet = {}
    mNet["id"] = self.m_ID
    mNet["amount"] = self:GetAmount()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetOwner())
    if oPlayer then
        oPlayer:Send("GS2CHouseItemAmount",mNet)
    end
end