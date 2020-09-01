--import module

local global = require "global"
local npcobj = import(service_path("npc/npcobj"))

CNpc = {}
CNpc.__index = CNpc
inherit(CNpc,npcobj.CNpc)

function CNpc:New(npctype)
    local o = super(CNpc).New(self,npctype)
    return o
end

function CNpc:do_look(oPlayer)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("pefuben")
    local oWorldMgr = global.oWorldMgr
    local iGrade = oWorldMgr:QueryControl("pefuben","open_grade")
    if oPlayer:GetGrade() < iGrade then
        self:Say(oPlayer:GetPid(),string.format("御灵副本在%d级开放",iGrade))
    elseif oPlayer:GetNowWar() then
        return
    else
        oHuodong:OpenMainUI(oPlayer)
    end
end

function NewNpc(npctype)
    local o = CNpc:New(npctype)
    return o
end