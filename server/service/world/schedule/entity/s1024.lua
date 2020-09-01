local global  = require "global"

local schedulebase=import(service_path("schedule/scheduleobj"))


function NewSchedule(id)
    return CSchedule:New(id)
end

CSchedule = {}
CSchedule.__index = CSchedule
inherit(CSchedule,schedulebase.CSchedule)

function CSchedule:New(scheduleid)
    local o = super(CSchedule).New(self,scheduleid)
    return o
end

function CSchedule:GetSum(oPlayer)
    local oHuoDong = self:HuoDong()
    return oHuoDong:TodayMaxTimes(oPlayer)
end


function CSchedule:GetCount(oPlayer)
    local oHuoDong = self:HuoDong()
    return oHuoDong:TodayUseTimes(oPlayer)
end






