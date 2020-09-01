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

    local fCallback = function (oAttack,oPerform)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:PerformStart(oAction,oAttack,oPerform)
        end
    end
    oCamp:AddFunction("PerformStart",iFuncNo,fCallback)

    local oCamp = oAction:GetCamp()
    local fCallback = function (oCamp,iSp)
        local oWar = oCamp:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAddSP(oAction,oCamp,iSp)
        end
    end
    oCamp:AddFunction("OnAddSP",iFuncNo,fCallback)

end

function CPerform:OnPerform(oAction,oAttack,lVictim,oPerform)
    local oCamp = oAction:GetCamp()
    local iNowSp = oCamp.m_SP6205
    if not iNowSp then
        return
    end
    oCamp.m_SP6205 = nil
    if oPerform:IsGroupAttack() or iNowSp < 1 then
        return
    end
    local mArg = self:GetSkillArgsEnv()
    local iRatio = mArg["ratio"] or 1000
    local iDamage = mArg["damage_ratio"] or 5000
    local iBuffID = 1063
    if not  oAction.m_oBuffMgr:HasBuff(iBuffID)  and oAction:Random(iRatio) then
        self:ShowPerfrom(oAction)
        local oWar = oAttack:GetWar()
        local iAdd = (iDamage * iNowSp*100)/10000
        local mArgs = {
            level = self:Level(),
            attack = oAttack:GetWid(),
            buff_bout = oWar.m_iBout,
            attr_value_list = string.format("{critical_damage=%s}",iAdd)
        }
        local oBuffMgr = oAction.m_oBuffMgr
        local oBuff = oBuffMgr:AddBuff(iBuffID,1,mArgs)
        if oBuff then
            oBuff.m_NoSubNowWar = 1
        end
        
    end
end

function CPerform:PerformStart(oAction,oAttack,oPerform)
    local oCamp = oAction:GetCamp()
    oCamp.m_SP6205 = 0
end


function CPerform:OnAddSP(oAction,oCamp,iSp)
    if oAction:GetCampId() ~= oCamp:GetCampId() then
        return
    end
    if oCamp.m_SP6205 then
        oCamp.m_SP6205 = oCamp.m_SP6205 + iSp
    end
end




