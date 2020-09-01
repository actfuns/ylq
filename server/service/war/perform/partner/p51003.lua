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
    local oWar = oAction:GetWar()
    local iCamp = oAction:GetCampId()
    local oCamp = oWar:GetCamp(iCamp)
    local iWid = oAction:GetWid()
    local iSkill = self:Type()
    local fCallback = function (oAttack,lVictim,oPerform)
        OnAfterGoback(oAttack,lVictim,oPerform,iWid,iSkill)
    end
    local iFuncNo = self.m_ID * 100 + iWid
    oCamp:AddFunction("OnAfterGoback",iFuncNo,fCallback)
end

function CPerform:OnAfterGoback(oAttack,lVictim,oPerform,iWid)
    if oAttack:GetWid() == iWid or oPerform:IsGroupAttack() then
        return
    end
    if oAttack:GetNormalAttackSkillId() ~= oPerform:Type() then
        return
    end
    local oWar = oAttack:GetWar()
    local oAction = oWar:GetWarrior(iWid)
    if not oAction or oAction:IsDead() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 2000
    if not oAction:Random(iRatio) then
        return
    end

    local NewVictimLst = {}
    for _,o in ipairs(lVictim) do
        if o:IsAlive() and not o:QueryBoutArgs("p51003_attack") then
            o:SetBoutArgs("p51003_attack",1)
            table.insert(NewVictimLst,o)
            break
        end
    end
    if #NewVictimLst == 0 then
        return
    end


    self:ShowPerfrom(oAction)
    local iAttackNormal = oAction:GetNormalAttackSkillId()

    local oPerform = oAction:GetPerform(iAttackNormal)
    oPerform:Perform(oAction,NewVictimLst)
end

function OnAfterGoback(oAttack,lVictim,oPerform,iWid,iSkill)
    local oWar = oAttack:GetWar()
    if not oWar then
        return
    end
    local oOwner = oWar:GetWarrior(iWid)
    if not oOwner or not oOwner:ValidAction() then
        return
    end
    local oSkill = oOwner:GetPerform(iSkill)
    if not oSkill then
        return
    end
    oSkill:OnAfterGoback(oAttack,lVictim,oPerform,iWid)
end