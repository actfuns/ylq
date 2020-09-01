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
    local oEnemyCamp = oAction:GetEnemyCamp()
    local iFuncNo = self.m_ID * 100 + oAction:GetWid()
    local iWid = oAction:GetWid()
    local fCallback = function (oVictim,oBuff)
        OnAddBuffHandle(iWid,iSkill,oVictim,oBuff)
    end
    oEnemyCamp:AddFunction("OnAddBuffHandle",iFuncNo,fCallback)
end

function CPerform:OnAddBuffHandle(oAction,oVictim,oBuff)
    if oBuff:InBuffClassType(gamedefines.WAR_BUFF_CLASS.CONTROL) then
        local mArgs = self:GetSkillArgsEnv()
        local iRatio = mArgs["ratio"] or 4000
        if in_random(iRatio,10000) then
            self:ShowPerfrom(oAction)
            local iDamgaeRatio = mArgs["damage_ratio"] or 3000
            local iDamgae = math.floor((oVictim:QueryAttr("attack") * iDamgaeRatio) / 10000)
            self:ModifyHp(oVictim,oAction,-iDamgae)
        end
    end
end


function OnAddBuffHandle(iWid,iSkill,oVictim,oBuff)
    local oWar = oVictim:GetWar()
    local oAction = oWar:GetWarrior(iWid)
    if not oAction or  oAction:IsDead() then
        return
    end
    local oSkill = oAction:GetPerform(iSkill)
    if not oSkill then
        return
    end
    oSkill:OnAddBuffHandle(oAction,oVictim,oBuff)
end