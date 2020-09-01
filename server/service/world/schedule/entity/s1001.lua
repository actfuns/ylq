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


function CSchedule:GetLeftTime(oPlayer)
    local oTask = oPlayer.m_oTaskCtrl:GetTask(500)
    if not oTask then
        return 0
    end
    return oPlayer.m_oTaskCtrl:GetLilianTimes()
end

function CSchedule:ClickSchedule(oPlayer)
    local oSceneMgr = global.oSceneMgr
    local oNpcMgr = global.oNpcMgr
    local npcobj =  oNpcMgr:GetGlobalNpc(5040)
    local mPos = npcobj:PosInfo()
    oSceneMgr:SceneAutoFindPath(oPlayer:GetPid(),npcobj.m_iMapid,mPos.x,mPos.y,npcobj.m_ID,1,1)
end
