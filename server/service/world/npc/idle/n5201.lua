--import module

local global = require "global"
local npcobj = import(service_path("npc/npcobj"))

CNpc = {}
CNpc.__index = CNpc
inherit(CNpc,npcobj.CNpc)

function CNpc:New(npcid)
    local o = super(CNpc).New(self,npcid)
    return o
end

function NewNpc(npctype,npcid)
    local o = CNpc:New(npctype,npcid)
    return o
end