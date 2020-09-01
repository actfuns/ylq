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
    -- local oNpcMgr = global.oNpcMgr
    -- local iNpc = self.m_ID
    -- local fCallback = function (oPlayer,mData)
    --     local oNpc = oNpcMgr:GetObject(iNpc)
    --     if oNpc then
    --         oNpc:Respond(oPlayer,mData)
    --     end
    -- end
    -- self:SayRespond(oPlayer:GetPid(),sText,nil,fCallback)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:OpenTravelView(oPlayer, self)
    end
end

function NewNpc(npctype)
    local o = CNpc:New(npctype)
    return o
end