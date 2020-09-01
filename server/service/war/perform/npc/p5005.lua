--import module

local global = require "global"
local skynet = require "skynet"
local extend = require "base/extend"

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


function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
             return  oSkill:OnCalDamage(oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnCalDamage",self.m_ID,fCallback)
end


function CPerform:OnCalDamage(oAttack,oVictim,oPerform,iDamage)
    if oPerform:Type() ~= self:Type() then
        return 0
    end
    if not self:CheckEffectRatio(oAttack,oVictim) then
        return 0
    end
    local iMaxHp = oVictim:GetMaxHp()
    local mArgs = self:GetSkillArgsEnv()
    return iMaxHp*mArgs["damage"]/100
end

function CPerform:Perform(oAttack,lVictim)
    local oActionMgr = global.oActionMgr
    local oWar = oAttack:GetWar()
    local mArgs = self:GetSkillArgsEnv()
    local iWid = oAttack:GetWid()
    local iAttackCnt = 5 + #oAttack:GetFriendList() -1
    local iMagicIdx = 1
    for i=1,iAttackCnt do
        oAttack = oWar:GetWarrior(iWid)
        if not oAttack or oAttack:IsDead() then
            break
        end
        local mEnemy = oAttack:GetEnemyList()
        if #mEnemy <= 0 then
            return
        end
        local oVictim = extend.Random.random_choice(mEnemy)
        if not oVictim:IsDead() then
            if i > 1 then
                iMagicIdx = 2
            end
            oActionMgr:DoPerform(oAttack,oVictim,self,100,iMagicIdx)
            end
    end
    local oAttack = oWar:GetWarrior(iWid)
    if oAttack and not oAttack:IsDead() then
        oAttack:OnPerform(lVictim,self)
        oAttack.m_oBuffMgr:CheckAttackBuff(oAttack)
        self:Effect_Condition_For_Attack(oAttack)
        if self:IsCD(oAttack) then
            self:SetCD(oAttack)
        end
    end
    if self:IsNearAction() then
        oWar:SendAll("GS2CWarGoback", {
            war_id = oWar:GetWarId(),
            action_wid = iWid,
        })
    end
end
