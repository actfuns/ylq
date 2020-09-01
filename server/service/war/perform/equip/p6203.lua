--import module

local global = require "global"
local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/equip/epfobj"))

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
    local iWid = oAction:GetWid()
    local iFuncNo = self:CampFuncNo(oAction:GetWid())
    local oCamp = oAction:GetEnemyCamp()
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return 0
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCalDamage(oAction,oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oCamp:AddFunction("OnCalDamage",iFuncNo,fCallback)
end

function CPerform:OnCalDamage(oAction,oAttack,oVictim,oPerform,iDamage)
    if not oAction.m_oBuffMgr:HasBuff(1061) and  oAttack:QueryBoutArgs("IsCrit") then
        local mArg = self:GetSkillArgsEnv()
        local iRatio = mArg["ratio"] or 1000
        if oAction:Random(iRatio) then
            self:ShowPerfrom(oAction)
            local iSelfBuff = 1061
            local iAttackBuff = 1062
            local oWar = oAction:GetWar()
            local f = function (oWarrior,iBuffID,iAttack,iBout)
                local oBuffMgr = oWarrior.m_oBuffMgr
                local mArgs = {
                    level = self:Level(),
                    attack = iAttack,
                    buff_bout = oWar.m_iBout,
                }
                oBuffMgr:AddBuff(iBuffID,iBout,mArgs)
            end

            f(oAction,iSelfBuff,oAction:GetWid(),1)
            f(oAttack,iAttackBuff,oAction:GetWid(),2)
        end
    end
    return 0
end


