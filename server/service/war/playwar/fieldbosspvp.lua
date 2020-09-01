--import module
local global = require "global"
local interactive = require "base.interactive"

local basewar = import(service_path("warobj"))
local basewarrior = import(service_path("npcwarrior"))

CWar = {}
CWar.__index = CWar
inherit(CWar, basewar.CWar)


function NewWar(...)
    local o = CWar:New(...)
    o.m_sWarType = "fieldbosspvp"
    return o
end

function CWar:Init(mInit,mExtra)
    super(CWar).Init(self,mInit,mExtra)
    self.m_iBossId = mInit.bossid
    self.m_iBossDead = 0
end

function CWar:SetBossDead()
    self.m_iBossDead = 1
end

function CWar:IsBossDead()

    return self.m_iBossDead == 1
end

function CWar:BoutStart()
    local iAliveCount1 = self.m_lCamps[1]:GetAliveCount()
    local iAliveCount2 = self.m_lCamps[2]:GetAliveCount()
    if iAliveCount1 > 0 and iAliveCount2 > 0 then
        if self:IsBossDead() then
            self:WarEndEffect()
            return
        end
    end
    super(CWar).BoutStart(self)
end

function CWar:OnWarEscape(oPlayer,iActionWid)
    if self.m_iWarResult ~= 0 then
        return
    end
    super(CWar).OnWarEscape(self,oPlayer,iActionWid)
end