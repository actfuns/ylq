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
    local fCallback = function (oAttack)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnActionEnd(oAction,oAttack)
        end
    end
    oCamp:AddFunction("OnActionEnd",iFuncNo,fCallback)


    local oCamp = oAction:GetCamp()
    local fCallback = function(oVictim,oAttack,oPerform,iDamage)
        local oWar = oAttack:GetWar()
        local oAction = oWar:GetWarrior(iWid)
        if not oAction or  oAction:IsDead() then
            return 0
        end
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnReceivedDamage(oAction,oVictim,oAttack,oPerform,iDamage)
        end
        return 0
    end
    oCamp:AddFunction("OnReceivedDamage",iFuncNo,fCallback)


end

function CPerform:OnActionEnd(oAction,oAttack)
    local iDamage = oAttack:QueryBoutArgs("p6201_damage")
    if not iDamage then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 2000
    if oAction:Random(iRatio) then
        self:ShowPerfrom(oAction)
        local oWar = oAttack:GetWar()
        local mData = self:GetSkillData()
        local mBuff = mData["attackBuff"] or {}
        local iAttackRatio = mArgs["attack_ratio"] or 1000
        local iAddAttack = math.floor(iAttackRatio * iDamage//10000)
        local mArgs = {
            level = self:Level(),
            attack = oAttack:GetWid(),
            buff_bout = oWar.m_iBout,
            add_attr = string.format("{attack = %s}",iAddAttack),
        }
        local oBuffMgr = oAction.m_oBuffMgr
        for _,mData in pairs(mBuff) do
            local iBuffID = mData["buffid"]
            local iBout = mData["bout"]
            oBuffMgr:AddBuff(iBuffID,iBout,mArgs)
        end
    end
end

function CPerform:OnReceivedDamage(oAction,oVictim,oAttack,oPerform,iDamage)
    if not oPerform:IsGroupAttack() then
        return 0
    end
    oAttack:AddBoutArgs("p6201_damage",iDamage)
    return 0
end


