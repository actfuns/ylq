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
    local oHuodong = oHuodongMgr:GetHuodong("dailytrain")
    oHuodong:do_look(oPlayer,self)
end

function NewNpc(npctype)
    local o = CNpc:New(npctype)
    return o
end