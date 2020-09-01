local global = require "global"
local interactive = require "base.interactive"

local basewar = import(service_path("warobj"))
local basewarrior = import(service_path("npcwarrior"))

CFieldBossMgr = {}
CFieldBossMgr.__index = CFieldBossMgr
inherit(CFieldBossMgr, logic_base_cls())

function NewFieldBossMgr()
    return CFieldBossMgr:New()
end

function CFieldBossMgr:New()
    local o = super(CFieldBossMgr).New(self)
    o:Init()
    return o
end

function CFieldBossMgr:Init()
    self.m_mBoss = {}
end

function CFieldBossMgr:NewFieldBoss(iBossId,mArgs)
    if self.m_mBoss[iBossId] then
        self.m_mBoss[iBossId]:ReBirth(iBossId,mArgs)
    else
        local oBoss = NewFieldBoss(iBossId,mArgs)
        self.m_mBoss[iBossId] = oBoss
    end
end

function CFieldBossMgr:GetBoss(iBossId)
    return self.m_mBoss[iBossId]
end

function CFieldBossMgr:RemoveFieldBoss(iBossId)
    local oBoss = self.m_mBoss[iBossId]
    if oBoss then
        oBoss:OnBossDie()
        oBoss:Release()
        self.m_mBoss[iBossId] = nil
    end
end

CFieldBoss = {}
CFieldBoss.__index = CFieldBoss
inherit(CFieldBoss, logic_base_cls())

function NewFieldBoss(iBossId,mArgs)
    return CFieldBoss:New(iBossId,mArgs)
end

function CFieldBoss:New(iBossId,mArgs)
    local o = super(CFieldBoss).New(self)
    o:Init(iBossId,mArgs)
    return o
end

function CFieldBoss:Init(iBossId,mArgs)
    self.m_Max_HP = mArgs.maxhp or 0
    self.m_HP = mArgs.hp or 0 
    self.m_AttackList = {}
    self.m_Hit = 0
    self.m_Version = 0
    self.m_IsDead = nil
    self.m_SyncTime =2000
    self.m_iBossId = iBossId
end

function CFieldBoss:IsDead()
    return self.m_IsDead or self.m_HP<=0
end

function CFieldBoss:SetDead()
    self:DelTimeCb("SyncBossHit")
    self.m_IsDead = true
end

function CFieldBoss:ReBirth(iBossId,mArgs)
    self:Init(iBossId,mArgs)
end

function CFieldBoss:AddHit(mHit,warid)
    for pid,hit in pairs(mHit) do
        self.m_Hit = self.m_Hit + hit
        table.insert(self.m_AttackList,{pid,hit,warid})
    end

end

function CFieldBoss:SyncBossStatus()
    self:DelTimeCb("SyncBossHit")
    if self:IsDead() then
        return
    end
    self:AddTimeCb("SyncBossHit",self.m_SyncTime,function ()
        self:SyncBossStatus()
        end)
    if self.m_Hit ~= 0 then 
        interactive.Send(".world","fieldboss","HPNotify",{bossid = self.m_iBossId,damage = self.m_Hit,pidlist = self.m_AttackList})
    end
    self.m_AttackList = {}
    self.m_Hit = 0
end

function CFieldBoss:OnBossDie()
    if not self:IsDead() then
        self:SetDead()
    end
    self:DelTimeCb("CleanBossWar")
    self:AddTimeCb("CleanBossWar",1000,function ()
        self:SyncBossStatus()
        end)
    local iCnt = 0
    local oWarMgr = global.oWarMgr
    for _,oWar in pairs(oWarMgr.m_mWars) do
            if oWar.m_sWarType and oWar.m_sWarType == "fieldboss" and oWar.m_iBossId == self.m_iBossId then
                oWar:OnBossDie()
                iCnt = iCnt + 1
            elseif oWar.m_sWarType and oWar.m_sWarType == "fieldbosspvp" and oWar.m_iBossId == self.m_iBossId then
                oWar:SetBossDead()
            end
            if iCnt >300 then
                break
            end
    end
    
    if iCnt == 0 then
        self:DelTimeCb("CleanBossWar")
    end
end

function CFieldBoss:Release()
    self:DelTimeCb("CleanBossWar")
    self:DelTimeCb("SyncBossHit")
    super(CFieldBoss).Release(self)
end

CWar = {}
CWar.__index = CWar
inherit(CWar, basewar.CWar)

function NewWar(...)
    local o = CWar:New(...)
    o.m_sWarType = "fieldboss"
    return o
end

function CWar:Init(mInit,mExtra)
    super(CWar).Init(self,mInit,mExtra)
    self.m_lCamps[2].m_LimitCallNpc = 5
    self.m_iBossId = mInit.bossid
end

function CWar:OnBoutEnd()
    self:RecordDamage()
    local oBoss = global.oFieldBossMgr:GetBoss(self.m_iBossId)
    if not oBoss then
        return
    end
    oBoss:SyncBossStatus()
    super(CWar).OnBoutEnd(self)
    --BOSS固定位置
end

function CWar:RecordDamage()
    local oBossWarrior = self:GetBoss()
    if oBossWarrior then
        local mDamage = oBossWarrior.m_SumDamage or {}
        local oBoss = global.oFieldBossMgr:GetBoss(self.m_iBossId)
        if not oBoss then
            return
        end
        oBoss:AddHit(mDamage,self.m_iWarId)
        oBossWarrior.m_SumDamage = {}
    end
end

function CWar:GetBoss()
    return self:GetWarriorByPos(2,1)
end


function CWar:NewNpcWarrior(iWid)
    return CNpcWarrior:New(iWid)
end

function CWar:OnBossDie()
    if self:IsWarEnd() then
        return
    end
    self:WarEndEffect()
end

function CWar:WarEndEffect()
    self.m_iWarResult = 0
    self:RecordDamage()
    local oBoss = global.oFieldBossMgr:GetBoss(self.m_iBossId)
    if not oBoss then
        return
    end
    oBoss:SyncBossStatus()
    super(CWar).WarEndEffect(self)
end



CNpcWarrior = {}
CNpcWarrior.__index = CNpcWarrior
inherit(CNpcWarrior, basewarrior.CNpcWarrior)

function CNpcWarrior:New(wid)
    local o = super(CNpcWarrior).New(self,wid)
    o.m_SumDamage = {}
    return o
end

function CNpcWarrior:SubHp(iDamage,mArgs)

    local iWid = mArgs["attack"]
    local oWar = self:GetWar()
    local oWarrior = oWar:GetWarrior(iWid)
    if oWarrior:IsPartner() then
        local iOwner = oWarrior:GetData("owner")
        local oOwner = oWar:GetWarrior(iOwner)
        local iPid = oOwner:GetPid()
        self.m_SumDamage[iPid] = (self.m_SumDamage[iPid] or 0) + iDamage
    elseif oWarrior:IsPlayer() then
        local iPid = oWarrior:GetPid()
        self.m_SumDamage[iPid] = (self.m_SumDamage[iPid] or 0) + iDamage
    end
    super(CNpcWarrior).SubHp(self,iDamage)
end
