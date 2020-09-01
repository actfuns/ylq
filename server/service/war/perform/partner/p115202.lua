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
inherit(CPerform, pfobj.CPerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fCallback = function (oAttack,lVictim,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:AfterShowWarSkill(oAttack,lVictim,oPerform)
        end
    end
    oAction:AddFunction("AfterShowWarSkill",self.m_ID,fCallback)

    local iSkill = self:Type()
    local fCallback = function (oAction)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnSubHp(oAction)
        end
    end
    oAction:AddFunction("OnSubHp",self.m_ID,fCallback)
end

function CPerform:AfterShowWarSkill(oAttack,lVictim,oPerform)
    if oPerform:Type() ~= self:Type() then
        return
    end
    if oAttack:IsAlive() then
        local iHP = oAttack:GetMaxHp()
        self:ModifyHp(oAttack,oAttack,-iHP)
    end
    
end

function CPerform:OnSubHp(oAction)
    oAction:Set("is_sacrifice",true)
end


