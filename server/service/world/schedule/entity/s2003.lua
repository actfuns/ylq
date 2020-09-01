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
    local oHuodong = self:HuoDong()
    local mArena = {}
    local mArenaData =  oHuodong:ArenaData()
    local iLa = oHuodong:ArenaStage(oPlayer:ArenaScore())
    local mInfo = mArenaData[iLa]
    return mInfo.weeky_limit
end

function CSchedule:GetCount(oPlayer)
    return oPlayer.m_oThisWeek:Query("equalarenamedal",0)
end







