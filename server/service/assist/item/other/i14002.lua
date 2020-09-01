local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local itembase = import(service_path("item/other/i13213"))

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

function CItem:GetUseReward()
    local lChip ={}
    local res = require "base.res"
    local mChipData = res["daobiao"]["partner_item"]["partner_chip"]
    for iChipSid, m in pairs(mChipData) do
        table.insert(lChip, {sid = tostring(iChipSid), amount = 1})
    end
    return lChip
end
