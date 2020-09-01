--import module

local global = require "global"
local skynet = require "skynet"

local auraload = import(service_path("aura/auraload"))

function NewAuraMgr(...)
    local o = CAuraMgr:New(...)
    return o
end

CAuraMgr = {}
CAuraMgr.__index = CAuraMgr
inherit(CAuraMgr, logic_base_cls())

function CAuraMgr:New(iWarId,iCamp)
    local o = super(CAuraMgr).New(self)
    o.m_iWarId = iWarId
    o.m_iCamp = iCamp
    o.m_mAttrRatio = {}
    o.m_oAuraList = {}
    return o
end

function CAuraMgr:Release()
    for id,obj in pairs(self.m_Auramgr:AuraList()) do
        self.m_oAuraList[id] = nil
        baseobj_delay_release(obj)
    end
    super(CAuraMgr).Release(self)
end


function CAuraMgr:AddAura(oAction,id,mArg)
    if self.m_oAuraList[id] then
        return
    end
    local obj  = auraload.NewAura(id)
    obj:Init(oAction,mArg)
    self.m_oAuraList[obj.m_ID] = obj
    local mAttr = obj:GetArrtData()

    for k,v in pairs(mAttr) do
        self:ModifAttrBaseRatio(k,v)
    end
    return obj
end

function  CAuraMgr:RemoveAura(id)
    local obj = self.m_oAuraList[id]
    if not obj then
        return
    end
    obj:OnRemove()
    self.m_oAuraList[id] = nil
    local mAttr = obj:GetArrtData()
    for k,v in pairs(mAttr) do
        self:ModifAttrBaseRatio(k,-v)
    end
    baseobj_delay_release(obj)
    return obj
end


function CAuraMgr:GetAttrBaseRatio(sAttr,rDefault)
    rDefault = rDefault or 0
    return self.m_mAttrRatio[sAttr] or rDefault
end

function CAuraMgr:ModifAttrBaseRatio(sAttr,iValue)
    if not self.m_mAttrRatio[sAttr] then
        self.m_mAttrRatio[sAttr] = 0
    end
    self.m_mAttrRatio[sAttr] = self.m_mAttrRatio[sAttr] + iValue
    return self.m_mAttrRatio[sAttr]
end

function CAuraMgr:AuraList()
    return self.m_oAuraList
end



