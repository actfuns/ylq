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
    local iOpenGrade = tonumber(global.oWorldMgr:QueryControl("shimen","open_grade"))
    if oPlayer:GetGrade() < iOpenGrade then
        super(CNpc).do_look(self,oPlayer)
        return
    end
    local oHuodong = global.oHuodongMgr:GetHuodong("shimen")
    if oHuodong then
        oHuodong:do_look(oPlayer,self)
    end
end

function NewNpc(npctype)
    local o = CNpc:New(npctype)
    return o
end