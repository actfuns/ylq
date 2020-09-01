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
            return oSkill:OnCalDefense(oAttack,oVictim,oPerform)
        end
        return 0
    end
    oAction:AddFunction("OnCalDefense",self.m_ID,fCallback)
end

function CPerform:OnCalDefense(oAttack,oVictim,oPerform)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 3000
    local iDefenseRatio = mArgs["defense_ratio"] or 4000
    if oAttack:GetData("awake") then
        iRatio = iRatio + ( mArgs["awake_ratio"] or 1000)
    end
    if not in_random(iRatio,10000) then
        return 0
    end
    self:ShowPerfrom(oAttack,{perform=oPerform,})
    local iDefense = math.floor(oVictim:QueryAttr("defense") * iDefenseRatio / 10000)
    return -iDefense
end