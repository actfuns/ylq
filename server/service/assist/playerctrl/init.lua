--import module
local skynet = require "skynet"
local itemctrl = import(service_path("playerctrl.itemctrl"))
local partnerctrl = import(service_path("playerctrl.partnerctrl"))
local skillctrl = import(service_path("playerctrl.skillctrl"))
local parsoulctrl = import(service_path("playerctrl.parsoulctrl"))


function NewItemCtrl( ... )
    return itemctrl.CItemCtrl:New(...)
end

function NewPartnerCtrl(...)
    return partnerctrl.NewPartnerCtrl(...)
end

function NewSkillCtrl( ... )
    return skillctrl.CSkillCtrl:New(...)
end

function NewParsoulCtrl( ... )
    return parsoulctrl.CParSoulCtrl:New(...)
end