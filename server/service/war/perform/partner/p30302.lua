local skynet = require "skynet"

local global = require "global"
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
            return oSkill:OnReceiveDamage(oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnReceiveDamage",self.m_ID,fCallback)

end


function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local oActionMgr = global.oActionMgr
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,iDamageRatio,3)
end

function CPerform:Perform(oAttack,lVictim)
    super(CPerform).Perform(self,oAttack,lVictim)
    if not oAttack or oAttack:IsDead() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["hp_ratio"] or 5000
    local oWar = oAttack:GetWar()
    local iBout = oWar.m_iBout
    local iDamage = oAttack:QueryBoutArgs("p30302_damage",0)
    iDamage = math.floor(iDamage * iRatio / 10000)
    if iDamage > 0 then
        local mArgs = {
            attack_wid = oAttack:GetWid()
        }
        self:ModifyHp(oAttack,oAttack,iDamage,mArgs)
    end
end



function CPerform:OnReceiveDamage(oAttack,oVictim,oPerform,iDamage)
    if oPerform:Type() == self:Type() then
        oAttack:AddBoutArgs("p30302_damage",iDamage)
    end
    return 0
end

function CPerform:Effect_Condition_For_Victim(oVictim,oAttack)
    if not oAttack or not oAttack:IsAwake() then
        return
    end
    super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack)
end

