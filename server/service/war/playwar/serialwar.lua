--import module

local interactive = require "base.interactive"
local global = require "global"

local gamedefines = import(lualib_path("public.gamedefines"))
local basewar = import(service_path("warobj"))

CWar = {}
CWar.__index = CWar
inherit(CWar, basewar.CWar)

function NewWar(...)
    local o = CWar:New(...)
    o.m_sWarType = "serialwar"
    return o
end

function CWar:Init(mInit,mExtra)
    super(CWar).Init(self,mInit,mExtra)
    local iKeepTime = mInit.keep_time or 300
    self.m_iEndTime = iKeepTime + get_time()
end

function CWar:ValidRefresh()
    if self.m_iEndTime <= get_time() then
        return false
    end
    return true
end



function CWar:ActionProcess()
    super(CWar).ActionProcess(self)
    local iWarWin  = self:IsCanWarEnd()
    if iWarWin and iWarWin == 1 and self:ValidRefresh() then
        self:RemoteWorldEvent("remote_serial_war",{
                war_id = self:GetWarId(),
            })
    end
end


function CWar:StartSerialWar(mInfo)
    self.m_iBout = 0
    local iCurrentWave = self:CurrentEnemyWave()
    local iNextWave = iCurrentWave + 1
    self:SetCurrentEnemyWave(iNextWave)
    self:GS2CWarWave()

    local iCamp = 1
    local oCamp = self:GetCamp(iCamp)
    local mFriend = oCamp:GetWarriorList()
    for _,oFriend in pairs(mFriend) do
        oFriend.m_oBuffMgr:ClearBuff()
        if oFriend:IsCallNpc() then
            local mArgs = {
                del_type = 2,
            }
            self:KickOutWarrior(oFriend,mArgs)
        end
    end

    local iCamp = 2
    local oCamp = self:GetCamp(iCamp)
    local mEnemy = oCamp:GetWarriorList()
    for _,oEnemy in pairs(mEnemy) do
        self:KickOutWarrior(oEnemy)
    end
    self:PrepareNextWaveMonster(mInfo)
    self:WarStart()
end

function CWar:WarEndEffect()
    self.m_iWarResult = 1
    super(CWar).WarEndEffect(self)
end

function CWar:GetMaxWarWave()
    return 0
end

function CWar:OnLeavePlayer(obj, bEscape)
    if bEscape then
        obj:Send("GS2CWarResult", {
            war_id = self:GetWarId(),
            win_side = 1,
            })
    end
    super(CWar).OnLeavePlayer(self,obj,bEscape)
end