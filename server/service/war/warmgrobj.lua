--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))

local warobj = import(service_path("warobj"))

function NewWarMgr(...)
    local o = CWarMgr:New(...)
    return o
end

CWarMgr = {}
CWarMgr.__index = CWarMgr
inherit(CWarMgr, logic_base_cls())


PLAY_WAR = list_key_table({
    "arenagame","equalarena","equipfuben","orgfuben","pata","serialwar","warfilm","worldboss","terrawars","fieldboss",
    "fieldbosspvp","chapterfb","teampvp","msattack","orgwar","clubarena","pefuben",
},true)

KF_PLAY_WAR = list_key_table({
    "kfequalarena",
    "kfarenagame",
},true)

function CWarMgr:New()
    local o = super(CWarMgr).New(self)
    o.m_mWars = {}
    return o
end

function CWarMgr:Release()
    for _, v in pairs(self.m_mWars) do
        baseobj_safe_release(v)
    end
    self.m_mWars = {}
    super(CWarMgr).Release(self)
end

function CWarMgr:ConfirmRemote(iWarId,sType,mArgs,mExtra)
    assert(not self.m_mWars[iWarId], string.format("ConfirmRemote error %d", iWarId))
    local oWar = self:NewWar(sType,iWarId)
    oWar:Init(mArgs,mExtra)
    self.m_mWars[iWarId] = oWar
end

function CWarMgr:NewWar(sType,iWarId)
    local oWar
    if sType and PLAY_WAR[sType] then
        local sPath = string.format("playwar.%s",sType)
        local oModule = import(service_path(sPath))
        oWar = oModule.NewWar(iWarId)
    elseif sType and KF_PLAY_WAR[sType] then
        local sPath = string.format("kuafuwar.%s",sType)

        local oModule = import(service_path(sPath))
        oWar = oModule.NewWar(iWarId)
    else
        oWar = warobj.NewWar(iWarId,sType)
    end
    return oWar
end

function CWarMgr:GetWar(iWarId)
    return self.m_mWars[iWarId]
end

function CWarMgr:RemoveWar(iWarId)
    local oWar = self.m_mWars[iWarId]
    if oWar then
        self.m_mWars[iWarId] = nil
        baseobj_delay_release(oWar)
    end
end
