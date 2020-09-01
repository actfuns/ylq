local skynet = require "skynet"
local global = require "global"
local extend = require "base/extend"

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
    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
        end
    end
    oAction:AddFunction("OnReceivedDamage",self.m_ID,fCallback)
end


function CPerform:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    if oVictim:Random(iRatio,10000) then
        local iHit = iDamage * (mArgs["damage_ratio"] or 3000) / 10000
        if iHit >0 then
            self:ShowPerfrom(oVictim)
            oAttack:ModifyHp(-iHit,{attack_wid=oVictim:GetWid()})
        end
        return -iDamage
    end
    return 0
end

