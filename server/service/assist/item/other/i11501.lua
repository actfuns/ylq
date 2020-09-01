local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))

local itembase = import(service_path("item/other/otherbase"))



CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function CItem:GetHongBaoInfo()
    local res = require "base.res"
    return res["daobiao"]["hongbao"]["hb_config"][self:SID()]
end

function CItem:TrueUse(oPlayer, target, iAmount)
    local mData = {
        sid = self:SID(),
    }
    local mArgs = {
        cmd = "SendHongBao",
        reason = "公会频道红包",
        data = mData,
    }
    oPlayer:SetRemoteItemData(mArgs)
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

