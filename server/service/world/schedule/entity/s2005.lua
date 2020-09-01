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

function CSchedule:GameStart(oPlayer)
    local iOrgId = oPlayer:GetOrgID()
    if iOrgId == 0 then
        return
    end
    local oHuodong = global.oHuodongMgr:GetHuodong("orgwar")
    if not oHuodong or not oHuodong:GetOrgName(iOrgId) then
        return
    end
    local oOrgMgr = global.oOrgMgr
    local iJoinTime = oOrgMgr:GetPlayerOrgInfo(oPlayer:GetPid(),"jointime",0)
    if iJoinTime ~= 0 and  (get_time() - iJoinTime) < 60*60*24 then
        return
    end
    oPlayer:Send("GS2COpenScheuleUI",{scheduleid = self:ID()})
end


function CSchedule:GetSum(oPlayer)
    return oPlayer.m_oActiveCtrl:GetMaxEnergy()
end

function CSchedule:GetCount(oPlayer)
    return oPlayer:GetEnergy()
end




function CSchedule:ClickSchedule(oPlayer)
    local oNotifyMgr = global.oNotifyMgr
    local oSceneMgr = global.oSceneMgr
    local oNpcMgr = global.oNpcMgr
    local npcobj =  oNpcMgr:GetGlobalNpc(5006)
    local mPos = npcobj:PosInfo()
    oSceneMgr:SceneAutoFindPath(oPlayer:GetPid(),npcobj.m_iMapid,mPos.x,mPos.y,npcobj.m_ID,1,1)
end

