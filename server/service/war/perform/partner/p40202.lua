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
    local iBuffID = 1012
    local oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
    local iExtDamage
    local mArg = self:GetSkillArgsEnv()
    if oBuff then
        local iLevel = oBuff:BuffLevel()
        local fRatio = (mArg["damage_ratio"] or 5000)/10000

        iExtDamage = math.floor(oAttack:QueryAttr("attack") * iLevel *fRatio)
    end
    local oActionMgr = global.oActionMgr
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,iDamageRatio,2)
    if iExtDamage then
        oBuff = oVictim.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oVictim.m_oBuffMgr:RemoveBuff(oBuff)
            self:ModifyHp(oVictim,oAttack,-iExtDamage)
        end
    end
end