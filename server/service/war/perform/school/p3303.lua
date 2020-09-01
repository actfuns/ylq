--import module

local global = require "global"
local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/pfobj"))

function NewCPerform(...)
    local o = CPerform:New(...)
    return o
end

CPerform = {}
CPerform.__index = CPerform
inherit(CPerform, pfobj.CPerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    super(CPerform).TruePerform(self,oAttack,oVictim,iDamageRatio)
    if not oAttack or oAttack:IsDead() then
        return
    end
    local oWar = oAttack:GetWar()
    if not oWar then
        return
    end
    local oActionMgr = global.oActionMgr
    local mArgs = self:GetSkillArgsEnv()
    local iCnt = self:Range()
    local iActionWid = oVictim:GetWid()
    local iSelectWid
    for i=1,iCnt do
        local mEnemy = oAttack:GetEnemyList()
        local m = {}
        for _,w in pairs(mEnemy) do
            if w:GetWid() ~= iActionWid then
                table.insert(m,w)
            end
        end
        if #m <= 0 then
            return
        end
        local oNewVictim = m[math.random(#m)]
        iSelectWid = oNewVictim:GetWid()
        oAttack:SendAll("GS2CWarSkill", {
            war_id = oAttack:GetWarId(),
            action_wlist = {iActionWid,},
            select_wlist = {iSelectWid,},
            skill_id = self.m_ID,
            magic_id = 2,
        })
        local iTime = self:PerformMagicTime(i)
        if oWar then
            oWar:AddAnimationTime(iTime,{skill=self:Type(),mgi=i})
        end
        self:SetData("PerformAttackCnt",1)
        local iAttackCnt = self:GetData("PerformAttackCnt",0)
        iAttackCnt = iAttackCnt + 1
        self:SetData("PerformAttackCnt",iAttackCnt)
        local iRatio = 100 - 20 * i
        oActionMgr:DoAttack(oAttack,oNewVictim,self,iRatio)
        if oNewVictim and not oNewVictim:IsDead() then
            self:Effect_Condition_For_Victim(oNewVictim,oAttack)
        end
        iActionWid = iSelectWid
    end
end

function CPerform:Effect_Condition_For_Victim(oVictim,oAttack)
     if not oVictim or oVictim:IsDead() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    local iMinRatio = mArgs["min_ratio"] or 2500
    local iMaxRatio = mArgs["max_ratio"] or 7500
    iRatio = oAttack:AbnormalRatio(oVictim,iRatio,iMaxRatio,iMinRatio)
    if in_random(iRatio,10000) then
        super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack)
    end
end