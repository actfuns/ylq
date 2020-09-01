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
    if self:Level() < 3 then
        return
    end
    local iSkill = self:Type()
    local fCallback = function (oAttack,lVictim,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnPerform(oAttack,lVictim,oPerform)
        end
    end
    oAction:AddFunction("OnPerform",self.m_ID,fCallback)

    local fCallback = function (oAttack,oVictim,iDamage)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnKill(oAttack,oVictim,iDamage)
        end
    end
    oAction:AddFunction("OnKill",self.m_ID,fCallback)


end

function CPerform:OnKill(oAttack,oVictim,iDamage)
    oAttack:AddBoutArgs("p51402_cnt",1)
end


function CPerform:OnPerform(oAttack,lVictim,oPerform)
    if self:Type() ~= oPerform:Type() or oAttack:IsDead() then
        return
    end
    local iCnt = oAttack:QueryBoutArgs("p51402_cnt")
    if not iCnt then
        return
    end

    local mArgs = self:GetSkillArgsEnv()
    oAttack:SetBoutArgs("p51402_cnt",nil)
    for i=1,iCnt do
        self:SpecialAttack(oAttack)
    end
end

function CPerform:SpecialAttack(oAttack)
    if oAttack:IsDead() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iDamage = math.floor((mArgs["damage_ratio"] or 5000 ) * oAttack:QueryAttr("attack") /10000)
    local lVictim = oAttack:GetEnemyList()
    for _,oWarrior in ipairs(lVictim) do
        self:ModifyHp(oWarrior,oAttack,-iDamage,{attack_wid=oAttack:GetWid()})
    end
end








