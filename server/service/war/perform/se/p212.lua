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
    local fCallback = function (oAttack,oVictim,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCalDamageRatio(oAttack,oVictim,oPerform)
        end
        return 0
    end
    oAction:AddFunction("OnCalDamageRatio",self.m_ID,fCallback)
end

function CPerform:OnCalDamageRatio(oAttack,oVictim,oPerform)
    local mArgs = self:GetSkillArgsEnv()
    local iHpRatio = mArgs["hp_ratio"] or 7000
    iHpRatio  = iHpRatio / 100
    local iDamageRatio = mArgs["damage_ratio"] or 4000
    local iRatio = math.floor(oVictim:GetHp() * 100 / oVictim:GetMaxHp())
    if iRatio >= iHpRatio then
        self:ShowPerfrom(oAttack,{perform=oPerform,bout=1})
        return iDamageRatio
    end
    return 0
end