local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local itemdefines = import(service_path("item.itemdefines"))

local itembase = import(service_path("item/other/otherbase"))
local loaditem = import(service_path("item/loaditem"))

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

function CItem:TrueUse(who, target, iAmount)
    local sReason = "15001"
    who.m_oItemCtrl:AddAmount(self,-iAmount,sReason)
    local iRandom = math.random(100)
    if iRandom < 50 then
        local iGem = self:GetGem()
        local iAmount = 2
        local mItem = {{iGem,iAmount,false}}
        who:GiveItem(mItem,sReason)
    else
        self:RandomMakeEquipStone(who)
    end
end

function CItem:GetGem()
    local mGem = {}
    local iBaseShape = 18000
    for i=0,500,100 do
        local iShape = iBaseShape + i
        for iLevel =0,6 do
            local iGem = iShape + iLevel
            table.insert(mGem,iGem)
        end
    end
    local iGem = mGem[math.random(#mGem)]
    return iGem
end

function CItem:RandomMakeEquipStone(oPlayer)
    local sReason = "15001"
    local iPos = math.random(6)
    local iLevel = math.random(6) * 10
    local iQuality = math.random(4)
    local iWeaponType
    if iPos == 1 then
        local iSchool = oPlayer:GetSchool()
        local iBranch = oPlayer:GetSchoolBranch()
        iWeaponType = itemdefines.GetSchoolWeaponType(iSchool, iBranch)
    end
    local iStone = itemdefines.GetEquipStoneShape(oPlayer,iPos,iLevel,iQuality,iWeaponType)
    local oItem = loaditem.Create(iStone)
    oPlayer:RewardItem(oItem, sReason)
end