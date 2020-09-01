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
    local fCallback = function (oAttack)
        OnNewBout(oAttack)
    end
    oAction:AddFunction("OnNewBout",self.m_ID,fCallback)
end

function OnNewBout(oAction)
    if oAction:IsDead() then
        return
    end
    if oAction.m_iBout == 1 then
        --oAction.m_oBuffMgr:AddBuff(112,255,{level=1,attack=oAction:GetWid()})
    end
end


