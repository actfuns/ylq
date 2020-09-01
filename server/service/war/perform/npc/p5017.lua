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
             return  oSkill:OnPerform(oAttack,lVictim,oPerform)
        end
        return 0
    end
    oAction:AddFunction("OnPerform",self.m_ID,fCallback)
end

function CPerform:OnPerform(oAttack,lVictim,oPerform)
    if self:Type() ~= oPerform:Type() then
        return
    end
    local iBuffID = 1071
    local oWar = oAttack:GetWar()
    local oFriendList = oAttack:GetFriendList()
    local mEnv = self:GetSkillArgsEnv()
    local iAddAttack = oAttack:QueryAttr("attack") * mEnv["attack_ratio"] / 10000
    for _,o in ipairs(oFriendList) do
        if not o.m_oBuffMgr:HasBuff(iBuffID) then
            local mArgs = {
                level = self:Level(),
                attack = oAttack:GetWid(),
                buff_bout = oWar.m_iBout,
                master_attack = iAddAttack,
            }
            local oBuff = o.m_oBuffMgr:AddBuff(iBuffID,2,mArgs)
            oBuff.m_NoSubNowWar = 1
        end
    end
end



