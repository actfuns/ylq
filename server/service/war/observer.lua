
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local playersend = require "base.playersend"

local gamedefines = import(lualib_path("public.gamedefines"))

function NewObserver(...)
    return CObserver:New(...)
end


CObserver = {}
CObserver.__index = CObserver
inherit(CObserver, logic_base_cls())

function CObserver:New(iPid)
    local o = super(CObserver).New(self)
    o.m_iPid = iPid
    return o
end

function CObserver:Init(mInit)
    self.m_iWarId = mInit.war_id
    self.m_FakeWid = mInit.wid
end

function CObserver:GetWid()
    return self.m_FakeWid
end

function CObserver:GetPid()
    return self.m_iPid
end

function CObserver:GetWarId()
    return self.m_iWarId
end


function CObserver:IsObserver()
    return true
end

function CObserver:GetWar()
    local oWarMgr = global.oWarMgr
    return oWarMgr:GetWar(self:GetWarId())
end

function CObserver:Send(sMessage, mData)
    local oWar = self:GetWar()
    if oWar then
        oWar:Send(self.m_iPid,self:GetWid(),sMessage,mData)
    end
end

function CObserver:Disconnected()
end

function CObserver:SendRaw(sData)
    local oWar = self:GetWar()
    if oWar then
        oWar:SendRaw(self.m_iPid,self:GetWid(),sData)
    end
end

function CObserver:Notify(sMsg)
    self:Send("GS2CNotify",{cmd=sMsg})
end

function CObserver:Enter()
    self:Send("GS2CEnterWar", {})
    local oWar = self:GetWar()
    oWar:GS2CAddAllWarriors(self)

    local iStatus, iStatusTime = oWar.m_oBoutStatus:Get()
    if iStatus == gamedefines.WAR_BOUT_STATUS.OPERATE then
        self:Send("GS2CWarBoutStart", {
            war_id = oWar:GetWarId(),
            bout_id = oWar.m_iBout,
            left_time = math.max(0, math.floor((iStatusTime + oWar:GetOperateTime() - get_msecond())/1000)),
        })
    elseif iStatus == gamedefines.WAR_BOUT_STATUS.ANIMATION then
        self:Send("GS2CWarBoutEnd", {
            war_id = oWar:GetWarId(),
        })
    end
    for iPid,iWid in pairs(oWar.m_mPlayers) do
        local oPlayer = oWar:GetWarrior(iWid)
        local iSpeed = oPlayer:GetPlaySpeed()
        if oPlayer then
            self:Send("GS2CWarSetPlaySpeed",{
                war_id = oWar:GetWarId(),
                play_speed = iSpeed
            })
        end
        break
    end
    if oWar:IsConfig() then
        self:Send("GS2CWarConfig",{
            war_id = self.m_iWarId,
            secs = 0
        })
    end
end
