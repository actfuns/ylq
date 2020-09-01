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
inherit(CPerform, pfobj.CPassivePerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local oEnemyCamp = oAction:GetEnemyCamp()
    local iWid = oAction:GetWid()

    local fCallback = function (oAttack,lVictim,oPerform)
        local oWar = oAttack:GetWar()
        local oWarrior = oWar:GetWarrior(iWid)
        if not oWarrior then
            return
        end
        local oSkill = oWarrior:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAfterGoback(oWarrior,oAttack,lVictim,oPerform)
        end
    end
    oEnemyCamp:AddFunction("OnAfterGoback",self:CampFuncNo(oAction:GetWid()),fCallback)


    local fCallback = function (oVictim,iHp,mArgs)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnModifyHp(oVictim,iHp,mArgs)
        end
    end
    oAction:AddFunction("OnModifyHp",self.m_ID,fCallback)
end

function CPerform:OnModifyHp(oVictim,iHp,mArgs)
    if iHp >= 0 or not oVictim:ValidAction()  or oVictim:QueryBoutArgs("attack_back") then
        return
    end
    if not mArgs["attack_wid"] or mArgs["attack_wid"] == oVictim.m_iWid then
        return
    end
    if mArgs["BuffID"]  and not mArgs["attack_buff"] then
        return
    end
    local oWar = oVictim:GetWar()
    local oAttack = oWar:GetWarrior(mArgs["attack_wid"])
    if not oAttack or oAttack:IsDead() or not oAttack:IsCurrentAction() then
        return
    end
    local mEnv = self:GetSkillArgsEnv()
    local iRatio = mEnv["ratio"] or 2000
    if not in_random(iRatio,10000) then
        return
    end

    self:ShowPerfrom(oVictim,{perform=oPerform})
    oVictim:SetBoutArgs("attack_back",true)
    self.m_AttackBackTarget = mArgs["attack_wid"]
end

function CPerform:OnAfterGoback(oAction,oAttack,lVictim,oPerform)
    if not oAction:QueryBoutArgs("attack_back") or not oAction:ValidAttackBack(oAttack) then
        return
    end
     if not oAttack:IsCurrentAction() or  oAttack:IsDead() then
        return
    end
    if self.m_AttackBackTarget ~= oAttack:GetWid() then
        return
    end
    local oWar = oAction:GetWar()
    local iNormalAttackId = oAction:GetNormalAttackSkillId()
    local oPerform = oAction:GetPerform(iNormalAttackId)
    if not oPerform then
        return
    end

    self.m_AttackBackTarget = nil
    oPerform:Perform(oAction,{oAttack})
    oAction:SetBoutArgs("attack_back",false)
end


