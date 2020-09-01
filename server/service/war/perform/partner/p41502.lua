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


function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    self:Effect_Condition_For_Victim(oVictim,oAttack,{NoSubNow=1,casterstart_falg=1})
end


--[[
function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fCallback = function (oAttack)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnDead(oAttack)
        end
    end
    oAction:AddFunction("OnDead",self.m_ID,fCallback)
    local fCallback = function (oAttack)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            oSkill:OnReplacePartner(oAttack)
        end
    end
    oAction:AddFunction("OnReplacePartner",self.m_ID,fCallback)
end


function CPerform:RemoveAllBuff(oAction)
    local mFriend = oAction:GetFriendList()
    if #mFriend <= 0 then
        return
    end
    local iBuff = 1016
    for _,oWarrior in ipairs(mFriend) do
        local oBuff = oWarrior.m_oBuffMgr:HasBuff(iBuff)
        if oBuff and oBuff:GetAttack() == oAction:GetWid() then
            oWarrior.m_oBuffMgr:RemoveBuff(oBuff)
        end
    end
end

function CPerform:OnDead(oAction)
    self:RemoveAllBuff(oAction)
end

function CPerform:OnReplacePartner(oAction)
    self:RemoveAllBuff(oAction)
end

]]


