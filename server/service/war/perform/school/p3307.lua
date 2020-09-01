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
inherit(CPerform, pfobj.CPassivePerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fCallback = function (oAttack,oVictim,oPerform)
        local oSkill = oAttack:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnCalDamageRatio(oAttack,oVictim,oPerform)
        end
        return 0
    end
    oPerformMgr:AddFunction("OnCalDamageRatio",self.m_ID,fCallback)
end

function CPerform:OnCalDamageRatio(oAttack,oVictim,oPerform)
    local oBuffMgr = oVictim.m_oBuffMgr
    local iCnt = oBuffMgr:ClassBuffCnt(gamedefines.BUFF_TYPE.CLASS_ABNORMAL)
    local mArgs = self:GetSkillArgsEnv()
    local iRatio = mArgs["attack_ratio"] or 500
    local iAddRatio = iRatio * iCnt / 100
    if iAddRatio > 0 then
        self:ShowPerfrom(oAttack,{show=1,perform=oPerform})
    end
    return iAddRatio
end