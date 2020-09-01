local global = require "global"
local skynet = require "skynet"

local virtualbase = import(service_path("item/virtual/virtualbase"))
local loaditem = import(service_path("item/loaditem"))
local itemdefines = import(service_path("item/itemdefines"))

CItem = {}
CItem.__index = CItem
inherit(CItem,virtualbase.CItem)


function CItem:Reward(oPlayer, sReason, mArgs)
    local res = require "base.res"
    local iType = self:GetData("type")
    local iQualitty = self:GetData("star")
    local iAttr = self:GetData("pos")
    local sid = itemdefines.RandomParSoulByQuality(iType,iQualitty,iAttr)
    oPlayer:GiveItem({{sid,1}},sReason,mArgs)
    local oItem = loaditem.GetItem(sid)
    return {iteminfo=oItem:GetBriefInfo()}
end


function NewItem(sid)
    local o = CItem:New(sid)
    return o
end
