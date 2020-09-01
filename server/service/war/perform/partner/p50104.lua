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
    local mFriend = oAction:GetFriendList()
    local iWid = oAction:GetWid()
    local iSkill = self:Type()

    local oCamp = oAction:GetCamp()
    
    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        OnAttacked(iWid,oVictim,oAttack,oPerform,iDamage)
    end
    local iFuncNo = self.m_ID * 100 + iWid
    oCamp:AddFunction("OnAttacked",iFuncNo,fCallback)


    local oEnemyCamp = oAction:GetEnemyCamp()
    local fCallback = function (oAttack)
        OnActionEnd(iWid,oAttack)
    end
    local iFuncNo = self.m_ID * 100 + iWid
    oEnemyCamp:AddFunction("OnActionEnd",iFuncNo,fCallback)
end




function CPerform:OnActionEnd(oAction,oAttack)
    local lNewVictim = oAction:QueryBoutArgs("p50104_target")
    if not lNewVictim then
        return
    end
    oAction:SetBoutArgs("p50104_target",nil)
    local oSkill = oAction:GetPerform(50101)
    if not oSkill then
        return
    end
    for wid,_ in pairs(lNewVictim) do
        if oAttack:IsAlive() then
            oSkill:Perform(oAction,{oAttack})
        end
    end
end


function CPerform:OnAttacked(oAction,oVictim,oAttack,oPerform,iDamage)
    local oWar = oAction:GetWar()
    if not oWar or oAction:GetWid() ==  oVictim:GetWid() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    if not in_random(iRatio,10000) then
        return
    end
    local lNewVictim = oAction:QueryBoutArgs("p50104_target",{})
    if not lNewVictim[oVictim:GetWid()] then
        lNewVictim[oVictim:GetWid()] = true
        oAction:SetBoutArgs("p50104_target",lNewVictim)
    end
end


function OnAttacked(iWid,oVictim,oAttack,oPerform,iDamage)
    local oWar = oVictim:GetWar()
    local oAction = oWar:GetWarrior(iWid)
    if not oAction or not oAction:ValidAction() then
        return
    end
    local oSkill = oAction:GetPerform(50104)
    if not oSkill then
        return
    end
    oSkill:OnAttacked(oAction,oVictim,oAttack,oPerform,iDamage)
end

function OnActionEnd(iWid,oAttack)
    local oWar = oAttack:GetWar()
    local oAction = oWar:GetWarrior(iWid)
    if not oAction or not oAction:ValidAction() then
        return
    end
    local oSkill = oAction:GetPerform(50104)
    if not oSkill then
        return
    end
    oSkill:OnActionEnd(oAction,oAttack)
end




