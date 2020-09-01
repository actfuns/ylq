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
inherit(CPerform, pfobj.CPassivePerform)

function CPerform:New(pfid)
    local o = super(CPerform).New(self,pfid)
    return o
end

function CPerform:CalWarrior(oAction,oPerformMgr)
    local iSkill = self:Type()
    local fCallback = function (oVictim,oAttack,oPerform,iDamage)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
        end
        return 0
    end
    oPerformMgr:AddFunction("OnReceivedDamage",self.m_ID,fCallback)
    local fCallback = function (oVictim,oAttack,iDamage)
        local oSkill = oVictim:GetPerform(iSkill)
        if oSkill then
            oSkill:OnKilled(oVictim,oAttack,iDamage)
        end
    end
    oPerformMgr:AddFunction("OnKilled",self.m_ID,fCallback)
end

function CPerform:OnReceivedDamage(oVictim,oAttack,oPerform,iDamage)
    local mArgs = self:GetSkillArgsEnv()
    local iHpRatio = mArgs["hp_ratio"] or 1000
    local iRatio = mArgs["ratio"] or 1000
    local oWar = oVictim:GetWar()
    local iCurRatio = math.floor(oVictim:GetHp()*10000/oVictim:GetMaxHp())
    if iCurRatio <= iHpRatio and in_random(iRatio,10000) then
        local iType = gamedefines.BUFF_TYPE.CLASS_FUZHU
        if oAttack.m_oBuffMgr:RemoveRandomBuff(iType)  then
            self:ShowPerfrom(oVictim)
            if oVictim:IsAwake() then
                local mArgs = {
                    level = self:Level(),
                    attack = oAttack:GetWid(),
                    buff_bout = oWar.m_iBout,
                }
                oVictim.m_oBuffMgr:AddBuff(1040,255,mArgs)
            end
        end
    end
    return 0
end

function CPerform:OnKilled(oVictim,oAttack,iDamage)
    local iType = gamedefines.BUFF_TYPE.CLASS_FUZHU
    if oAttack.m_oBuffMgr:RemoveClassBuff(iType) then
        self:ShowPerfrom(oVictim)
    end

end