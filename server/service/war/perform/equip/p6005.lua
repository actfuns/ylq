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
    local fCallback = function (oAttack,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:PerformStart(oAttack,oPerform)
        end
        return 0
    end
    oAction:AddFunction("PerformStart",self.m_ID,fCallback)
end

function CPerform:PerformStart(oAttack,oPerform)
    if oPerform:ActionType() ~= 1 or oAttack:IsDead() then
        return
    end
    local mTarget = oAttack:QueryBoutArgs("perform_target",{})
    local iWid = mTarget[1]
    if not iWid then
        return
    end
    local oWar = oAttack:GetWar()
    local oVictim = oWar:GetWarrior(iWid)
    if not oVictim then
        return
    end
    local mArg = self:GetSkillArgsEnv()
    local iRatio = mArg["ratio"] or 5000
    local iMinRatio = mArg["min_ratio"] or 1000
    local iMaxRatio = mArg["max_ratio"] or 5000
    iRatio = oAttack:AbnormalRatio(oVictim,iRatio,iMinRatio,iMaxRatio)
    if oAttack:Random(iRatio) then
        self:ShowPerfrom(oAttack)
        self:Effect_Condition_For_Victim(oVictim)
    end

end



