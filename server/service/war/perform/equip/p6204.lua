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
    local iWid = oAction:GetWid()
    local iFuncNo = self:CampFuncNo(oAction:GetWid())
    local oCamp = oAction:GetCamp()
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return 0
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCalDamageRatio(oAction,oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oCamp:AddFunction("OnCalDamageRatio",iFuncNo,fCallback)
end

function CPerform:OnCalDamageRatio(oAction,oAttack,oVictim,oPerform,iDamage)
    if oAttack.m_oBuffMgr:HasGroupType(gamedefines.BUFF_TYPE.CLASS_ABNORMAL,101) then
        local mArgs = self:GetSkillArgsEnv()
        local iRatio = mArgs["ratio"] or 2000
        if oAction:Random(iRatio) then
            self:ShowPerfrom(oAction)
            return mArgs["damage_ratio"] or 0
        end
    end
    return 0
end


