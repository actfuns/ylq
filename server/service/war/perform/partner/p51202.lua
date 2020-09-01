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

function CPerform:MaxRange(oAttack,oVictim)
    local iBuffID = 1009
    local oBuff = oAttack.m_oBuffMgr:HasBuff(iBuffID)
    local iCnt = 1
    if oBuff then
        iCnt = iCnt + oBuff:BuffLevel()
    end
    return iCnt
end

function CPerform:Perform(oAttack,lVictim)
    super(CPerform).Perform(self,oAttack,lVictim)
    local iBuffID = 1009
    if oAttack then
        local oBuff = oAttack.m_oBuffMgr:HasBuff(iBuffID)
        if oBuff then
            oAttack.m_oBuffMgr:RemoveBuff(oBuff)
        end
    end
end

function CPerform:TruePerform(oAttack,oVictim,iDamageRatio)
    local oActionMgr = global.oActionMgr
    oActionMgr:DoMultiAttack(oAttack,oVictim,self,iDamageRatio,3)
end