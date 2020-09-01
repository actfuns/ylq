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
    o.m_sWarType = "msattack"
    return o
end

function CWar:NewNpcWarrior(iWid)
    return CNpcWarrior:New(iWid)
end

function CWar:Enter(obj,iCamp)
    if obj:GetData("boss") == 1 then
        self:SetExtData("bossfight",1)
    end
    super(CWar).Enter(self,obj,iCamp)
end

function CWar:SetWarResult(iWin)
    if self.m_bEndEffect then
        return
    end
    if iWin ~= 0 then
        self.m_iWarResult = 1
    else
        self.m_iWarResult = 2
    end
    self:WarEndEffect()
end


CNpcWarrior = {}
CNpcWarrior.__index = CNpcWarrior
inherit(CNpcWarrior, basewarrior.CNpcWarrior)

function CNpcWarrior:New(wid)
    local o = super(CNpcWarrior).New(self,wid)
    return o
end

function CNpcWarrior:SubHp(iDamage,mArgs)
    if self:GetData("boss") == 1 then
        mArgs = mArgs or {}
        local iAttack = mArgs["attack"]
        if iAttack then
            local oWar = self:GetWar()
            local oAttack = oWar:GetWarrior(iAttack)
            if oAttack and oAttack:GetCampId() == 1 then
                if oAttack:IsPartner() then
                    local oPlayer = oWar:GetWarrior(oAttack:GetData("owner"))
                    if oPlayer then
                        global.oMsattackObj:AddDamage(oPlayer:GetPid(),iDamage)
                    end
                elseif oAttack:IsPlayer() then
                    global.oMsattackObj:AddDamage(oAttack:GetPid(),iDamage)
                end
            end
        end
    end
    super(CNpcWarrior).SubHp(self,iDamage,mArgs)
end

function CNpcWarrior:KeepAlive()
    if self:GetData("boss", 0) == 1 then
        self:SetData("hp", math.max(1, self:GetData("hp", 0)))
    end
end

function CNewMsattackMgr()
    local o  = CMSAttackMgr:New()
    return o
end

CMSAttackMgr = {}
CMSAttackMgr.__index = CMSAttackMgr
inherit(CMSAttackMgr, logic_base_cls())

function CMSAttackMgr:New()
    local o = super(CMSAttackMgr).New(self)
    o:Init()
    return o
end

function CMSAttackMgr:Init()
    self.m_IsDead = nil
    self.m_SyncTime = 5000
    self.m_NeedSync = false
    self.m_SumDamage = {}
end

function CMSAttackMgr:AddDamage(iPid,iDamage)
    local mSum = self.m_SumDamage
    mSum[iPid] = mSum[iPid] or 0
    mSum[iPid] = mSum[iPid] + iDamage
    self.m_NeedSync = true
end

function CMSAttackMgr:IsDead()
    return self.m_IsDead
end

function CMSAttackMgr:SetDead()
    self:DelTimeCb("SyncBossStatus")
    self.m_IsDead = true
end

function CMSAttackMgr:SyncBossStatus()
    self:DelTimeCb("SyncBossStatus")
    if self:IsDead() then
        return
    end
    self:AddTimeCb("SyncBossStatus",self.m_SyncTime,function ()
        self:SyncBossStatus()
    end)
    if self.m_NeedSync then
        interactive.Send(".world","msattack","DamageBoss",{damage = self.m_SumDamage})
        self.m_SumDamage = {}
        self.m_NeedSync = false
    end
end

function CMSAttackMgr:OnBossDie(iWin)
    -- if not self:IsDead() then
    --     self:SetDead()
    -- end
    -- self:DelTimeCb("SyncBossStatus")
    -- self:DelTimeCb("CleanBossWar")
    -- self:AddTimeCb("CleanBossWar",2000,function ()
    --     self:OnBossDie(iWin)
    --     end)
    -- local iCnt = 0
    -- local oWarMgr = global.oWarMgr
    -- for _,oWar in pairs(oWarMgr.m_mWars) do
    --         if oWar.m_sWarType and oWar.m_sWarType == "msattack" and oWar:GetExtData("bossfight") == 1 then
    --             oWar:SetWarResult(iWin)
    --             iCnt = iCnt + 1
    --         end
    --         if iCnt > 300 then
    --             break
    --         end
    -- end

    -- if iCnt == 0 then
    --     self:DelTimeCb("CleanBossWar")
    -- end
end

function CMSAttackMgr:StopAllWar(iWin)
    self:DelTimeCb("SyncBossStatus")
    self:DelTimeCb("CleanBossWar")
    self:DelTimeCb("StopAllWar")
    self:AddTimeCb("StopAllWar",2000,function ()
        self:StopAllWar()
    end)
    local iCnt = 0
    local oWarMgr = global.oWarMgr
    for _,oWar in pairs(oWarMgr.m_mWars) do
            if oWar.m_sWarType and oWar.m_sWarType == "msattack" then
                oWar:SetWarResult(iWin)
                iCnt = iCnt + 1
            end
            if iCnt > 300 then
                break
            end
    end
    if iCnt == 0 then
        self:DelTimeCb("StopAllWar")
    end
end