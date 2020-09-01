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
    local oActionMgr = global.oActionMgr
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,iDamageRatio,3)
end


function CPerform:CalWarrior(oAction,oPerformMgr)
    if self:Level() < 3 then
        return
    end
    local iSkill = self:Type()
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCalDamageRatio(oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnCalDamageRatio",self.m_ID,fCallback)
end


function CPerform:OnCalDamageRatio(oAttack,oVictim,oPerform,iDamage)
    if self:Type() ~= oPerform:Type() or oVictim:IsDead() then
        return 0
    end
    if not oAttack:QueryBoutArgs("IsCrit")  then
        return 0 
    end
    local iRatio  =  self:GetSkillArgsEnv()["buff_ratio"] or 5000
    if in_random(iRatio,10000) then
        oAttack:AddBoutArgs("p51302_buff",1)
    end
    return 0 
end

function CPerform:Effect_Condition_For_Attack(oAttack)
    local iCnt = oAttack:QueryBoutArgs("p51302_buff") 
    if not iCnt then
        return
    end
    oAttack:SetBoutArgs("p51302_buff",nil)

    local oWar = oAttack:GetWar()
    local iBuff = 1053
    local oBuffMgr = oAttack.m_oBuffMgr
    local mArgs = {
    level = 1,
    attack = oAttack:GetWid(),
    buff_bout = oWar.m_iBout,
    }
    for i=1,iCnt do
        oBuffMgr:AddBuff(iBuff,255,mArgs)
    end
end






