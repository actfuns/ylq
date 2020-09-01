local global = require "global"
local skynet = require "skynet"

local virtualbase = import(service_path("item/virtual/virtualbase"))
local itemdefines = import(service_path("item/itemdefines"))
local loaditem = import(service_path("item/loaditem"))

CItem = {}
CItem.__index = CItem
inherit(CItem,virtualbase.CItem)

function CItem:Reward(oPlayer, sReason, mArgs)
    local iLevel = self:GetData("level", 10)
    local iQuality = self:GetData("quality", 1)
    local iEquipPos = self:GetData("equippos", 1)
    local iWeaponType
    if iEquipPos == 1 then
        local iSchool = oPlayer:GetSchool()
        local iBranch = oPlayer:GetSchoolBranch()
        iWeaponType = itemdefines.GetSchoolWeaponType(iSchool, iBranch)
    end
    local iSid = itemdefines.GetEquipStoneShape(oPlayer, iEquipPos, iLevel, iQuality, iWeaponType)
    local mResult
    if iSid then
        local o = loaditem.Create(iSid)
        mResult = {iteminfo=o:GetBriefInfo()}
        oPlayer:RewardItem(o, sReason, mArgs)
    end
    return mResult
end

function CItem:GetRwardSid()
    local iLevel = self:GetData("level", 10)
    local iQuality = self:GetData("quality", 1)
    local iEquipPos = self:GetData("equippos", 1)
    return string.format("%s(level=%s,quality=%s,equippos=%s)",self:SID(),iLevel,iQuality,iEquipPos)
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end