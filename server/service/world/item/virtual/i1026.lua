local global = require "global"
local skynet = require "skynet"

local virtualbase = import(service_path("item/virtual/virtualbase"))

CItem = {}
CItem.__index = CItem
inherit(CItem,virtualbase.CItem)

function CItem:Reward(oPlayer, sReason, mArgs)
    mArgs = mArgs or {}
    local iValue = self:GetData("value")
    if not iValue then
        return
    end
    local iOrgID = mArgs.orgid or oPlayer:GetOrgID()
    local oOrgMgr = global.oOrgMgr
    oOrgMgr:AddPrestige(iOrgID,iValue,sReason, mArgs)
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end