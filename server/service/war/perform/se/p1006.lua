local skynet = require "skynet"
local global = require "global"
local extend = require "base/extend"

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
    local fCallback = function (oAction,oVictim,oPerform,iDamage)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            oSkill:OnAttack(oAction,oVictim,oPerform,iDamage)
        end
    end
    oAction:AddFunction("OnAttack",self.m_ID,fCallback)

end


function CPerform:OnAttack(oAction,oVictim,oPerform,iDamage)
    -- 20% 清除对方辅助组一个BUFF
    local iSkill = oPerform:Type()
    local mPerform = oAction:GetData("perform_ai")
    if not mPerform then
        return
    end
    if not mPerform[iSkill] then
        return
    end
    if not in_random(20,100) then
        return
    end
    local oBuffMgr = oVictim.m_oBuffMgr
    local oBuffList = oBuffMgr:GetClassBuff(2)
    if #oBuffList == 0 then
        return
    end
    local oBuff = extend.Random.random_choice(oBuffList)
    oBuffMgr:RemoveBuff(oBuff)
end



