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


function CPerform:Perform(oAttack,lVictim)
    local iAttackCnt = 1
    local oBuff = oAttack.m_oBuffMgr:HasBuff(1003)
    if oBuff then
        local mArg = oBuff:GetBuffArgsEnv()
        local iMin = mArg["min_normal_attack_time"] or 1
        local iMax = mArg["max_normal_attack_time"] or 2
        iAttackCnt = math.random(iMin,iMax)
        oAttack.m_oBuffMgr:RemoveBuff(oBuff)
    end
    local oVictim = lVictim[1]
    local oActionMgr = global.oActionMgr
    local f = function (idx) 
        if idx > 1 then
            return 2
        else
            return 1
        end
    end
    oActionMgr:DoMultiPerform(oAttack,oVictim,self,100,iAttackCnt,{MagicID=f})
end