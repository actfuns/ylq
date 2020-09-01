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
             return  oSkill:OnCalDamage(oAttack,oVictim,oPerform,iDamage)
        end
        return 0
    end
    oAction:AddFunction("OnCalDamage",self.m_ID,fCallback)

    local fCallback = function (oAttack)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
             return  oSkill:OnActionEnd(oAttack)
        end
        return 0
    end
    oAction:AddFunction("OnActionEnd",self.m_ID,fCallback)

end


function CPerform:OnCalDamage(oAttack,oVictim,oPerform,iDamage)
    if oPerform:Type() ~= self:Type() then
    return 0
    end
    if self.m_Temp_Hit and self:CheckEffectRatio(oAttack,oVictim) then
        local fHit = self.m_Temp_Hit
        return fHit
    end
    return 0
end


function CPerform:OnActionEnd(oAttack)
    self.m_Temp_Hit = nil
end


function CPerform:Perform(oAttack,lVictim)
    local mFriend = oAttack:GetFriendList()
    local mWarrior = {}
    for _,oWarrior in ipairs(mFriend) do
        if oWarrior:GetWid() ~= oAttack:GetWid() and not oWarrior:IsBoss() then
            table.insert(mWarrior,oWarrior)
        end
    end
    if #mWarrior > 0 then
        local oTarget =  extend.Random.random_choice(mWarrior)
        local iHP = oTarget:GetHp()
        local mArgs = self:GetSkillArgsEnv()
        self.m_Temp_Hit = iHP*mArgs["damage"]/100
        self:ModifyHp(oTarget,oAttack,-iHP,{dead=1})
    end
    super(CPerform).Perform(self,oAttack,lVictim)
end

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local oActionMgr = global.oActionMgr
    if oAttack:IsDead() or oVictim:IsDead() then
        return
    end
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,100,3)
end




