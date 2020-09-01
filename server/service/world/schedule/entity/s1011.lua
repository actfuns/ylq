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
    local iOrg = oPlayer:GetOrgID()
    if not iOrg then
        return
    end
    local oHuoDong = self:HuoDong()
    return oHuoDong:GetConfigValue("play_times")
end

function CSchedule:GetCount(oPlayer)
    return oPlayer.m_oToday:Query("org_fb")
end

