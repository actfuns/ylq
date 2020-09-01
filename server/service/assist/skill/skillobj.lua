--import module

local global = require "global"

local skillobj = import(lualib_path("public.skillobj"))

CSkill = {}
CSkill.__index =CSkill
CSkill.m_sType = "base"
inherit(CSkill,skillobj.CSkill)

function CSkill:New(iSk)
    local o = super(CSkill).New(self,iSk)
    return o
end