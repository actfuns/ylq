--import module

local global = require "global"
local skillobj = import(service_path("skill/se/sebase"))

function NewSkill(iSk)
    local o = CSESkill:New(iSk)
    return o
end

CSESkill = {}
CSESkill.__index = CSESkill
CSESkill.m_sType = "equip"
inherit(CSESkill,skillobj.CSESkill)

function CSESkill:New(iSk)
    local o = super(CSESkill).New(self,iSk)
    return o
end

