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
inherit(CPerform, pfobj.CPassivePerform)

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

function CPerform:OnReceiveDamage(oAttack,oVictim,oPerform,iDamage)
    
    if not oVictim:IsCallNpc() then
        return 0
    end
    
    local iRatio = oVictim:GetHpRatio()
    local mArgs = self:GetSkillArgsEnv()
    local iHpRatio = (mArgs["hp_ratio"] or 2000)//100
    if iRatio < iHpRatio then
        return math.floor(oVictim:GetHp() + 1)
    end
    
    return 0
end