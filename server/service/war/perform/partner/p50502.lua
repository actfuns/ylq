local skynet = require "skynet"

local global = require "global"
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

function CPerform:Perform(oAttack,lVictim,mArgs)
    mArgs = mArgs or {}
    local oActionMgr = global.oActionMgr
    mArgs["random_perform_action"] = function (oAttack,oVictim,oPerform,iRatio,iMagicIdx)
        if iMagicIdx > 1 then
            iMagicIdx = 2
        end
        oActionMgr:DoPerform(oAttack,oVictim,oPerform,100,iMagicIdx)
    end
    
    local iBuffID = mArgs["buff_id"] or 1010
    local oBuff = oAttack.m_oBuffMgr:HasBuff(iBuffID)
    local iAttackCnt = 3
    if oBuff then
        iAttackCnt = iAttackCnt + oBuff:BuffLevel()
        oAttack.m_oBuffMgr:RemoveBuff(oBuff)
    end
    self:RandomPerform(oAttack,lVictim,iAttackCnt,mArgs)
end

