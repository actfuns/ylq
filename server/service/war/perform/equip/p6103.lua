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

function CPerform:CalWarrior(oWarrior,oPerformMgr)
    self:InitTeamReceiveDamage(oWarrior)
end

function CPerform:OnTeamAttacked(oAction,oVictim,oAttack,oPerform,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1500
    if oAction:Random(iRatio) then
        self:ShowPerfrom(oAction)
        local oWar = oAttack:GetWar()
        local mData = self:GetSkillData()
        local mBuff = mData["attackBuff"] or {}
        local iAttackRatio = mArgs["attack_ratio"] or 1000
        local iSpeedRatio = mArgs["speed_ratio"]
        local iAddAttack = math.floor(iAttackRatio * oVictim:QueryAttr("attack")//10000)
        local iAddSpeed = math.floor(iSpeedRatio * oVictim:QueryAttr("speed")//10000)
        local mArgs = {
            level = self:Level(),
            attack = oVictim:GetWid(),
            buff_bout = oWar.m_iBout,
            add_attr = string.format("{attack = %s,speed = %s}",iAddAttack,iAddSpeed),
        }
        local oBuffMgr = oAction.m_oBuffMgr
        for _,mData in pairs(mBuff) do
            local iBuffID = mData["buffid"]
            local iBout = mData["bout"]
            oBuffMgr:AddBuff(iBuffID,iBout,mArgs)
        end
    end
end



