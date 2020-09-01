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

    local fCallback = function (oAttack,lVictim,oPerform)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnPerform(oAction,oAttack,lVictim,oPerform)
        end
    end
    oCamp:AddFunction("OnPerform",iFuncNo,fCallback)

end

function CPerform:OnTeamAttacked(oAction,oVictim,oAttack,oPerform,iDamage)
    local iMax = oPerform:GetData("PerformAttackMaxCnt",1)
     if iDamage < 1 or oAttack:QueryBoutArgs("p6106_trigger") or oPerform:GetData("PerformAttackCnt",0) ~= iMax  then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    if not oAction:Random(iRatio) then
        return
    end
    oAttack:SetBoutArgs("p6106_trigger",1)
    local iHPRatio = mArgs["hp_ratio"] or 2000
    local iHP = math.floor(iHPRatio * oAction:QueryAttr("attack") // 10000)
    if iHP > 0 then
        self:ShowPerfrom(oAction)
        self:ModifyHp(oVictim,oAction,iHP,{attack_wid=oAction:GetWid(),})
    end
end

function CPerform:OnPerform(oAction,oAttack,lVictim,oPerform)
    if oAttack:QueryBoutArgs("p6106_trigger") then
        oAttack:SetBoutArgs("p6106_trigger",nil)
    end
end
