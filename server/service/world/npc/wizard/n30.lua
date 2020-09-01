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
    local sText = "#nQ战斗11023#nQ战斗11024"
    local oNpcMgr = global.oNpcMgr
    local iNpc = self.m_ID
    local fCallback = function (oPlayer,mData)
        local oNpc = oNpcMgr:GetObject(iNpc)
        if oNpc then
            oNpc:Respond(oPlayer,mData)
        end
    end
    self:SayRespond(oPlayer:GetPid(),sText,nil,fCallback)
end

function CNpc:Respond(oPlayer,mData)
    local iAnswer = mData["answer"]
    local oModule = import(service_path("templ"))
    local oTempl = oModule.CTempl:New()
    if iAnswer == 1 then
        oTempl:CreateWar(oPlayer:GetPid(),nil,11023)
    elseif iAnswer == 2 then
        oTempl:CreateWar(oPlayer:GetPid(),nil,11024)
    end
end

function NewNpc(npctype)
    local o = CNpc:New(npctype)
    return o
end