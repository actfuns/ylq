--import module

local global = require "global"
local skynet = require "skynet"
local extend = require "base/extend"

local gamedefines = import(lualib_path("public.gamedefines"))
local pfobj = import(service_path("perform/pfobj"))

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
    local fCallback = function (oAttack,oVictim,oPerform,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
             return  oSkill:OnAttack(oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnAttack",self.m_ID,fCallback)
end

function CPerform:OnAttack(oAttack,oVictim,oPerform,iDamage)
    if oPerform:Type() ~= self:Type() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["attack_ratio"] or 3000
    if not oAttack:Random(iRatio,10000) then
        return
    end
    local iDamageRatio = mArgs["attack_damage"] or 3000
    local iSum = mArgs["cnt"] or 2
    local iDamage = iDamage * iDamageRatio / 10000
    if iDamage < 1 then
        return
    end
    local iWid = oVictim:GetWid()
    local oList = oAttack:GetEnemyList()
    local iCnt = 0
    for _,o in ipairs(oList) do
        if o:GetWid() ~= iWid then
            o:ModifyHp(-iDamage,{attack_wid=oAttack:GetWid()})
            iCnt = iCnt + 1
            if iCnt >= 2 then
                break
            end
        end
    end
end

function CPerform:Effect_Condition_For_Victim(oVictim,oAttack,mExArg)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 3000
    if not oAttack:Random(iRatio,10000) then
        return
    end
    super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack,mExArg)
    
end











