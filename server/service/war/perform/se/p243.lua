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
    local fCallback = function (oVictim,oAttack,oPerform)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnPerformed(oVictim,oAttack,oPerform)
        end
    end
    oAction:AddFunction("OnPerformed",self.m_ID,fCallback)

    local fCallback = function (oVictim,iHp,mArgs)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnModifyHp(oVictim,iHp,mArgs)
        end
    end
    oAction:AddFunction("OnModifyHp",self.m_ID,fCallback)
end


function CPerform:OnModifyHp(oVictim,iHp,mArgs)
    if iHp >= 0 then
        return
    end
    if not mArgs["attack_wid"] then
        return
    end
    if mArgs["BuffID"]  and not mArgs["attack_buff"] then
        return
    end
    if oVictim:QueryBoutArgs("p243_target") ==mArgs["attack_wid"] then
        return
    end

    local oWar = oVictim:GetWar()
    local oAttack = oWar:GetWarrior(mArgs["attack_wid"])
    if not oAttack or oAttack:IsDead() then
        return
    end
    local mEnv = self:GetSkillArgsEnv()
    local iRatio = mEnv["ratio"] or 800
    if not in_random(iRatio,10000) then
        return
    end
    oVictim:SetBoutArgs("p243_target",mArgs["attack_wid"])
    self:ShowPerfrom(oVictim)
    self:Effect_Condition_For_Victim(oAttack,oVictim,{NoSubNow=1})
end


function CPerform:OnPerformed(oVictim,oAttack,oPerform)
    if oVictim:IsFriend(oAttack) then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 800
    if not in_random(iRatio,10000) then
        return
    end
    self:ShowPerfrom(oVictim)
    self:Effect_Condition_For_Victim(oAttack,oVictim,{NoSubNow=1})
end


