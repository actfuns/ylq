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
    local iCamp = oAction:GetCampId()
    local oWar = oAction:GetWar()
    local oCamp = oWar:GetCamp(iCamp)
    local iMaxHp = oAction:GetMaxHp()
    local iSkill = self:Type()
    local fCallback = function (oAttack)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnNewBout(oAction)
        end
    end
    oPerformMgr:AddFunction("OnNewBout",self.m_ID,fCallback)
    local iWid = oAction:GetWid()
    local fCallback = function (oAttack)
        BeforeCommand(oAttack,iWid,iMaxHp,iSkill)
    end
    local iFuncNo = self.m_ID * 100 + iWid
    oCamp:AddFunction("BeforeCommand",iFuncNo,fCallback)
    local mCheck = oCamp:Query("effect_produce",{})
    mCheck[iWid] = true
    oCamp:Set("effect_produce",mCheck)
end

function CPerform:OnNewBout(oAction)
    if oAction:IsDead() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 4000
    if not in_random(iRatio,10000) then
        return
    end
    self:ShowPerfrom(oAction)
    local oCamp = oAction:GetCamp()
    oAction:SetBoutArgs("se252",true)
end

function BeforeCommand(oAttack,iWid,iMaxHp,iSkill)
    local oWar = oAttack:GetWar()
    local oWarrior = oWar:GetWarrior(iWid)
    if not oWarrior or   oWarrior:IsDead() then
        return
    end
    local oSkill = oWarrior:GetPerform(iSkill)
    if not oSkill then
        return
    end
    oSkill:BeforeCommand(oAttack,oWarrior,iMaxHp)
end

function CPerform:ValidEffect(oAction,oWarrior)
    local oCamp = oAction:GetCamp()
    local mCheck = oCamp:Query("effect_produce",{})
    if not mCheck[oWarrior:GetWid()] then
        return false
    end
    if oAction:QueryBoutArgs("cur_252") then
        return false
    end
    return true
end

function CPerform:BeforeCommand(oAction,oWarrior,iMaxHp)
    if oAction:IsDead() then
        return
    end
    if not self:ValidEffect(oAction,oWarrior) then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 4000
    if not in_random(iRatio,10000) then
        return
    end
    self:ShowPerfrom(oWarrior)
    local mArgs = self:GetSkillArgsEnv()
    local iHpRatio = mArgs["hp_ratio"] or 800
    local iAddHp = math.floor(iMaxHp * iHpRatio / 10000)
    self:ModifyHp(oAction,oAction,iAddHp)
end