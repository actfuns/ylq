--import module
local global = require "global"
local interactive = require "base.interactive"

local basewar = import(service_path("warobj"))
local basewarrior = import(service_path("npcwarrior"))

CWar = {}
CWar.__index = CWar
inherit(CWar, basewar.CWar)


function CNewWorldBoss()
    local o  = CWorldBoss:New()
    return o
end

function NewWar(...)
    local o = CWar:New(...)
    o.m_sWarType = "worldboss"
    return o
end

function CWar:Init(mInit,mExtra)
    super(CWar).Init(self,mInit,mExtra)
    self.m_lCamps[2].m_LimitCallNpc = 5
end

function CWar:BoutStart()
    if self.m_iBout == 0 then
        local oBoss = self:GetBoss(2,1)
        local mExtra = oBoss:GetData("data",{})
        local iBuff = mExtra["teambuff"] or 0

        local mSkill = {4001,4002,4003,}
        for _,iSkill in ipairs(mSkill) do
            if oBoss:GetPerform(iSkill) then
               oBoss.m_TempPerform = iSkill
            end
        end
        -- 收录伙伴信息
        local mPlayerPartner = {}
        local mWarrior  =  self:GetWarriorList(1) or {}
        for _,oAction in pairs(mWarrior) do
            if iBuff ~=0 then
                oAction.m_oBuffMgr:AddBuff(iBuff,3,{level=1,attack=oAction:GetWid()})
            end
            if oAction:IsPartner() then
                local iShape = oAction:GetData("model_info").shape
                local iWid = oAction:GetData("owner")
                local oWarrior = self:GetWarrior(iWid)
                if oWarrior and oWarrior:IsPlayer() then
                    local iPid = oWarrior:GetPid()
                    local mPartner = mPlayerPartner[iPid] or {}
                    local mArgs = {shape=iShape, name = oAction:GetData("name")}
                    mPartner[oAction:GetData("parid")] = mArgs
                    mPlayerPartner[iPid] = mPartner
                end
            end
        end
        self.m_WorldbossPartner = mPlayerPartner
    end

    super(CWar).BoutStart(self)
end

function CWar:WarEndEffect()
    self.m_iWarResult = 0
    self:RecordDamage()
    local oBoss = self:GetBoss()
    if oBoss then
        global.oWorldBoss:SyncBossStatus()
    end
    super(CWar).WarEndEffect(self)
end


function CWar:OnBoutEnd()
    --BOSS固定位置
    self:RecordDamage()
    super(CWar).OnBoutEnd(self)
end

function CWar:RecordDamage()
    local oBoss = self:GetBoss()
    if oBoss then
        local iDamage = oBoss.m_SumDamage or 0
        oBoss.m_SumDamage = 0
        local iTarget = 0
        local oWorldBoss = global.oWorldBoss
        for pid,_ in pairs(self.m_mPlayers) do
            iTarget = pid
            break
        end
        oWorldBoss:AddHit(iTarget,iDamage)
    end
end

function CWar:GetBoss()
    return self:GetWarriorByPos(2,1)
end


function CWar:NewNpcWarrior(iWid)
    return CNpcWarrior:New(iWid)
end

function CWar:OnBossDie(iWin)
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

function CWar:OnWarEscape(oPlayer,iActionWid)
    self.m_iWarResult = 2
    self:WarEndEffect()
end



function CWar:WarStartConfig(mInfo)
    super(CWar).WarStartConfig(self,mInfo)
end


function CWar:ExtendWarEndArg(mArgs)
    local mArg = super(CWar).ExtendWarEndArg(self,mArgs) or {}
     mArg.world = self.m_WorldbossPartner or {}
    return  mArg
end


CNpcWarrior = {}
CNpcWarrior.__index = CNpcWarrior
inherit(CNpcWarrior, basewarrior.CNpcWarrior)

function CNpcWarrior:New(wid)
    local o = super(CNpcWarrior).New(self,wid)
    o.m_SumDamage = 0
    return o
end

function CNpcWarrior:SubHp(iDamage)
    self.m_SumDamage = self.m_SumDamage+iDamage
    super(CNpcWarrior).SubHp(self,iDamage)
end

function CNpcWarrior:KeepAlive()
    local iMonster =self:GetData("monsterid", 20000)
    if iMonster < 20000 then
        self:SetData("hp", math.max(1, self:GetData("hp", 0)))
    end
end


CWorldBoss = {}
CWorldBoss.__index = CWorldBoss
inherit(CWorldBoss, logic_base_cls())

function CWorldBoss:New()
    local o = super(CWorldBoss).New(self)
    o:Init()
    return o
end

function CWorldBoss:Init()
    self.m_Max_HP = 0
    self.m_HP = 0
    self.m_AttackList = {}
    self.m_Hit = 0
    self.m_Version = 0
    self.m_IsDead = nil
    self.m_SyncTime =2000
end

function CWorldBoss:IsDead()
    return self.m_IsDead or self.m_HP<=0
end

function CWorldBoss:SetDead()
    self:DelTimeCb("SyncBossHit")
    self.m_IsDead = true
end

function CWorldBoss:ReBirth(mArg)
    self:Init()
    self.m_Max_HP = mArg.maxhp
    self.m_HP = self.m_Max_HP
end

function CWorldBoss:AddHit(pid,hit)
    self.m_Hit = self.m_Hit + hit
    --self.m_AttackList = {pid,}
    table.insert(self.m_AttackList,{pid,hit})

end

function CWorldBoss:SyncBossStatus()
    self:DelTimeCb("SyncBossHit")
    if self:IsDead() then
        return
    end
    self:AddTimeCb("SyncBossHit",self.m_SyncTime,function ()
        self:SyncBossStatus()
        end)
    if self.m_Hit ~= 0 then
        interactive.Send(".world","worldboss","HPNotify",{damage = self.m_Hit,pidlist = self.m_AttackList})
    end
    self.m_AttackList = {}
    self.m_Hit = 0
end

function CWorldBoss:OnBossDie(iWin)
    if not self:IsDead() then
        self:SetDead()
    end
    self:DelTimeCb("CleanBossWar")
    self:AddTimeCb("CleanBossWar",1000,function ()
        self:OnBossDie()
        end)
    local iCnt = 0
    local oWarMgr = global.oWarMgr
    for _,oWar in pairs(oWarMgr.m_mWars) do
            if oWar.m_sWarType and oWar.m_sWarType == "worldboss" then
                oWar:OnBossDie(iWin)
                iCnt = iCnt + 1
            end
            if iCnt >300 then
                break
            end
    end

    if iCnt == 0 then
        self:DelTimeCb("CleanBossWar")
    end
end








