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
    oAction:SetData("IgnoreSpSkill",true)
    local fCallback = function (oAction,oPerform)
        local oSkill = oAction:GetPerform(iSkill)
        if oSkill then
            return oSkill:OnAIChoosePerform(oAction,oPerform)
        end
    end
    oAction:AddFunction("OnAIChoosePerform",self.m_ID,fCallback)
end


function CPerform:OnAIChoosePerform(oAction,oPerform)
    local mPerform = oAction:GetPerformList()
    for _,iPerform in pairs(mPerform) do
        local oPf = oAction:GetPerform(iPerform)
        if oPf and oPf:IsSp() then
            oPerform = oPf
            break
        end
    end
    return oPerform
end

