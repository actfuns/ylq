local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local itembase = import(service_path("item/other/otherbase"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    return o
end

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

function CItem:TrueUse(who, target, iAmount)
    local sReason = "15000"
    who.m_oItemCtrl:AddAmount(self,-iAmount,sReason)
    local iRandom = math.random(100)
    if iRandom < 10 then
        local iExp = 10000 + math.random(5000)
        who:RewardExp(iExp,sReason)
    elseif iRandom < 20 then
        local iGold = 10000 + math.random(5000)
        who:RewardCoin(iGold,sReason)
    elseif iRandom < 30 then
        local iOffer = 10 + math.random(10)
        who:RewardOrgOffer(iOffer,sReason)
    elseif iRandom < 40 then
        local iMedal = 10 + math.random(10)
        who:RewardMedal(iMedal,sReason)
    elseif iRandom < 50 then
        local iActive = 20 + math.random(30)
        who:RewardActive(iActive,sReason)
    elseif iRandom < 60 then
        local iPoint = 20 + math.random(20)
        who:RewardTrapminePoint(iPoint,sReason)
    else
        local iVal = 30 + math.random(30)
        who:RewardArenaMedal(iVal,sReason)
    end
end