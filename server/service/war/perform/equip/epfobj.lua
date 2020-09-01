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
inherit(CPerform, pfobj.CPassivePerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end


--p61XXX
function CPerform:InitTeamReceiveDamage(oAction)
    local iSkill = self:Type()
    local iWid = oAction:GetWid()

    local iFuncNo = self:CampFuncNo(oAction:GetWid())
    local oCamp = oAction:GetCamp()

    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() or oVictim:GetWid() == oAction:GetWid() then
            return
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnTeamAttacked(oAction,oVictim,oAttack,oPerform,iDamage)
        end
    end
    oCamp:AddFunction("OnAttacked",iFuncNo,fCallback)
end
    
function CPerform:OnTeamAttacked(oAction,oVictim,oAttack,oPerform,iDamage)
    
end

