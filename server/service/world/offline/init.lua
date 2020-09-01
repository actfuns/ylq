local skynet = require "skynet"

local profilectrl = import(service_path("offline.profilectrl"))
local friendctrl = import(service_path("offline.friendctrl"))
local mailbox = import(service_path("offline.mailbox"))
local partnerctrl = import(service_path("offline.partnerctrl"))
local privyctrl = import(service_path("offline.privyctrl"))
local travelctrl = import(service_path("offline.travelctrl"))
local rom = import(service_path("offline.rom"))

function NewProfileCtrl(...)
    return profilectrl.CProfileCtrl:New(...)
end

function NewFriendCtrl(...)
    return friendctrl.CFriendCtrl:New(...)
end

function NewMailBox(...)
    return mailbox.CMailBox:New(...)
end

function NewPartnerCtrl( ... )
    return partnerctrl.CPartnerCtrl:New(...)
end

function NewPrivyCtrl( ... )
    return privyctrl.CPrivyCtrl:New(...)
end

function NewTravelCtrl( ... )
    return travelctrl.CTravelCtrl:New(...)
end

function NewRomCtrl(...)
    return rom.CRomCtrl:New(...)
end

