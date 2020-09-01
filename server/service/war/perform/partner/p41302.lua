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



function CPerform:PerformTarget(oAttack,oVictim)
    local mTargetList = super(CPerform).PerformTarget(self,oAttack,oVictim)
    if self:Level() < 3 then
        return mTargetList
    end
    local oWar = oAttack:GetWar()
    local oTarget
    local iHPRatio = 200
    for _,iWid in ipairs(mTargetList) do
        local oWarrior = oWar:GetWarrior(iWid)
        if oWarrior and iHPRatio > oWarrior:GetHpRatio() then
            oTarget = oWarrior
        end
    end
    if oTarget then
        local mArgs = self:GetSkillArgsEnv()
        local iRatio = mArgs["ratio"] or 4000
        local iMaxRatio = mArgs["max_ratio"] or 6000
        local iMinRatio = mArgs["in_ratio"] or 1000
        iRatio = oAttack:AbnormalRatio(oTarget,iRatio,iMaxRatio,iMinRatio)
        if in_random(iRatio,10000) then
            oTarget:SetBoutArgs("p41302_buff",true)
        end
    end
   return mTargetList
end

function CPerform:Effect_Condition_For_Victim(oVictim,oAttack)
    if not oVictim:QueryBoutArgs("p41302_buff") then
        return
    end
    oVictim:SetBoutArgs("p41302_buff",false)
    super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack)
end
