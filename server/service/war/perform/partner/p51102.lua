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
    local oActionMgr = global.oActionMgr
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,iDamageRatio,2)
end


function CPerform:Effect_Condition_For_Victim(oVictim,oAttack)
    if not oVictim:IsPartner() and not oVictim:IsPlayer() then
        return
    end
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 2000
    local iMinRatio = mArgs["min_ratio"] or 1000
    local iMaxRatio = mArgs["max_ratio"] or 7000
    iRatio = oAttack:AbnormalRatio(oVictim,iRatio,iMaxRatio,iMinRatio)
    if in_random(iRatio,10000) then
        super(CPerform).Effect_Condition_For_Victim(self,oVictim,oAttack)
        if oAttack:IsAwake() then
            local oBuff = oVictim.m_oBuffMgr:HasBuff(1032)
            if oBuff then
                oBuff.m_awake = 1
            end
        end
    end
end

