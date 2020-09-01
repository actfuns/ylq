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
    self:InitTeamReceiveDamage(oAction)


    local iSkill = self:Type()
    local iWid = oAction:GetWid()

    local iFuncNo = self:CampFuncNo(oAction:GetWid())
    local oCamp = oAction:GetEnemyCamp()

    local fCallback = function (oAttack)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnActionEnd(oAction,oAttack)
        end
    end
    oCamp:AddFunction("OnActionEnd",iFuncNo,fCallback)

end

function CPerform:OnTeamAttacked(oAction,oVictim,oAttack,oPerform,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 400
    local iMinRatio = mArgs["min_ratio"] or 100
    local iMaxRatio = mArgs["max_ratio"] or 5000
    iRatio = oAction:AbnormalRatio(oAttack,iRatio,iMaxRatio,iMinRatio)
    if oAction:Random(iRatio) then
        self:ShowPerfrom(oAction)
        oAttack:SetBoutArgs("p6104_target",1)
    end
end

function CPerform:OnActionEnd(oAction,oAttack)
     if oAttack:QueryBoutArgs("p6104_target") then
        self:Effect_Condition_For_Victim(oAttack,oAction)
    end
end













