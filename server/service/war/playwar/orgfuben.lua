--import module
local global = require "global"
local interactive = require "base.interactive"
local record = require "public.record"

local basewar = import(service_path("warobj"))
local npcwarrior = import(service_path("npcwarrior"))


CWar = {}
CWar.__index = CWar
inherit(CWar, basewar.CWar)


function NewWar(...)
    local o = CWar:New(...)
    o.m_sWarType = "orgfuben"
    return o
end

function CWar:Init(mInit,mExtra)
    super(CWar).Init(self,mInit,mExtra)
    self.m_Org = mInit.org
    self.m_Boss = mInit.boss
    self.m_PlayerParnetList = mInit.use_parlist or {}
    self.m_BossHit = 0
end


function CWar:NewNpcWarrior(iWid)
    return CNpcWarrior:New(iWid)
end


function CWar:BoutStart()
    if self.m_iBout == 0 then
        -- 收录伙伴信息
        local mPlayerPartner = {}
        local mWarrior = self:GetWarriorList(1) or {}
        for _,oAction in pairs(mWarrior) do
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

                    local mParlist = self.m_PlayerParnetList[iPid] or {}
                    local oPlayer = self:GetPlayerWarrior(iPid)
                    local mFightPartner = oPlayer:Query("today_fight",{})
                    for _,rpid in ipairs(mParlist) do
                        mFightPartner[rpid] =1
                    end
                    mFightPartner[oAction:GetData("parid")] = 1
                    oPlayer:Set("today_fight",mFightPartner)

                end
            end
        end
        self.m_WorldbossPartner = mPlayerPartner
    end

    super(CWar).BoutStart(self)
end


function CWar:WarStartConfig(mInfo)
    super(CWar).WarStartConfig(self,mInfo)
    for iPid,_ in pairs(self.m_PlayerParnetList) do
        self:SendUseFightPartner(iPid)
    end
end

function CWar:SendUseFightPartner(iPid)
    local mParlist = self.m_PlayerParnetList[iPid]
    local oPlayer = self:GetPlayerWarrior(iPid)

    if mParlist  and oPlayer then
        local mFightPartner = oPlayer:Query("today_fight",{})
        for _,rpid in ipairs(mParlist) do
            mFightPartner[rpid] =1
            end
        oPlayer:Set("today_fight",mFightPartner)
        local mNet = {
        war_id = oPlayer.m_iWarId,
        wid = oPlayer:GetWid(),
        partner_list = table_value_list(mParlist),
        sp = 0,
        command_list = {},
        }
        oPlayer:Send("GS2CPlayerWarriorEnter",mNet)
    end
end




function CWar:ExtendWarEndArg(mArgs)
    local mArg = super(CWar).ExtendWarEndArg(self,mArgs) or {}
    mArg.world = self.m_WorldbossPartner or {}
    mArg.bosshit = self.m_BossHit
    return  mArg
end

function CWar:OnHitBoss(oWarrior,iHit)
    self.m_BossHit = self.m_BossHit  + iHit
end


function CWar:OnBossDie(iOrg,iBoss)
    if self.m_Org == iOrg and self.m_Boss == iBoss then
        self.m_iWarResult = 1
        self:WarEndEffect()
    end
end

function CWar:OnWarEscape(oPlayer,iActionWid)
    local iCamp = oPlayer.m_iCamp
    if iCamp == 1 then
        self.m_iWarResult = 2
    else
        self.m_iWarResult = 1
    end
    self:WarEndEffect()
end





CNpcWarrior = {}
CNpcWarrior.__index = CNpcWarrior
inherit(CNpcWarrior, npcwarrior.CNpcWarrior)

function CNpcWarrior:NewBout()
    self.m_Hit = 0
    super(CNpcWarrior).NewBout(self)
end

function CNpcWarrior:SubHp(iDamage,mArgs)
    self.m_Hit  = self.m_Hit + iDamage
    super(CNpcWarrior).SubHp(self,iDamage,mArgs)
    if self:IsBoss() and self.m_Hit > 0 then
        self.m_Hit = 0
        local mExtra = self:GetData("data")
        interactive.Send(".world","orgfuben","HPNotify",{damage = iDamage,org=mExtra["Org"],type=mExtra["OrgBoss"]})
        local oWar = self:GetWar()
        oWar:OnHitBoss(self,iDamage)
    end
end

function CNpcWarrior:KeepAlive()
    local iMonster =self:GetData("monsterid", 20000)
    if iMonster < 20000 then
        self:SetData("hp", math.max(1, self:GetData("hp", 0)))
    end
end
