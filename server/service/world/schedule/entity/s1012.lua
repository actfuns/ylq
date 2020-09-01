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
    local oHuoDong = self:HuoDong()
    return 1- oHuoDong:GetYJBuyCnt(oPlayer)
end

function CSchedule:GetSum(oPlayer)
    return self:HuoDong():GetYJFuBenLimit(oPlayer)
end

function CSchedule:GetCount(oPlayer)
    return self:HuoDong():GetYJFuBenCnt(oPlayer)
end

function CSchedule:ClickSchedule(oPlayer)
    local oSceneMgr = global.oSceneMgr
    local oNpcMgr = global.oNpcMgr
    local npcobj =  oNpcMgr:GetGlobalNpc(5008)
    local mPos = npcobj:PosInfo()
    oSceneMgr:SceneAutoFindPath(oPlayer:GetPid(),npcobj.m_iMapid,mPos.x,mPos.y,npcobj.m_ID,1,1)
end
