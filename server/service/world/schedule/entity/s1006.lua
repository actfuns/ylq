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


function CSchedule:GetBuyTime(oPlayer)
    return self:HuoDong():GetLeftBuyTimes(oPlayer)
end


function CSchedule:GetSum(oPlayer)
    local oHuodong = self:HuoDong()
    return oHuodong:GetMingleiFightCnt() + oPlayer.m_oToday:Query("minglei_buytime",0)
end

function CSchedule:GetCount(oPlayer)
    return oPlayer.m_oToday:Query("minglei_fighttime",0)
end


