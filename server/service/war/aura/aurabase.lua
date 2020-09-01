--import module

local global = require "global"
local skynet = require "skynet"
local extend = require "base/extend"


CAura = {}

CAura = {}
CAura.__index = CAura
inherit(CAura, logic_base_cls())

function CAura:New(id)
    local o = super(CAura).New(self)
    o.m_ID = id
    o.m_mArgs = {}
    return o
end


function CAura:Init(oAction,mArgs)
     mArgs = mArgs or {}
     mArgs["wid"] = oAction:GetWid()
     self.m_mArgs = mArgs
end

function CAura:GetWid()
    return self.m_mArgs["wid"]
end

function CAura:Args()
    return self.m_mArgs
end

function CAura:OnRemove(oAction,oBuffMgr)

end

function CAura:GetArrtData()
    local res = require "base.res"
    return res["daobiao"]["aura"][self.m_ID]["attr_set"]
end



function CAura:GetArgs()
    local res = require "base.res"
    return res["daobiao"]["aura"][self.m_ID]["args"]
end


function CAura:OnOverlying(oAction,oNewAura)
end


function NewCAura(...)
    local o = CAura:New(...)
    return o
end


