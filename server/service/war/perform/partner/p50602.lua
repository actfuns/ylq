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

function CPerform:Effect_Condition_For_Victim(oVictim,oAttack)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["ratio"] or 1000
    if not in_random(iRatio,10000) then
        return
    end
    local iClassType = gamedefines.BUFF_TYPE.CLASS_FUZHU
    local iCnt = 1
    local iExtraLevel = mArgs["extra_level"] or 3
    if self:Level() >= iExtraLevel then
        iCnt = 2
    end

    for i=1,iCnt do
        local iClassCnt = oVictim.m_oBuffMgr:ClassBuffCnt(iClassType)
        if iClassCnt > 0 then
            oAttack:SetBoutArgs("remove_fuzhu",1)
            oVictim.m_oBuffMgr:RemoveRandomBuff(iClassType)
        end
    end
end

function CPerform:Effect_Condition_For_Attack(oAttack)
    if not oAttack:IsAwake() then
        return
    end
    if not oAttack:QueryBoutArgs("remove_fuzhu") then
        return
    end

    self:ShowPerfrom(oAttack,{skill = 50603})
    super(CPerform).Effect_Condition_For_Attack(self,oAttack)
end