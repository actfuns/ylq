--import module

local global = require "global"
local skynet = require "skynet"

local shareobj = import(lualib_path("base.shareobj"))
local datactrl = import(lualib_path("public.datactrl"))

function NewPartnerShare(iPid)
    local o = CPartnerShareMgr:New(iPid)
    return o
end

CPartnerShareMgr = {}
CPartnerShareMgr.__index =CPartnerShareMgr
inherit(CPartnerShareMgr,datactrl.CDataCtrl)

function CPartnerShareMgr:New(iPid)
    local o = super(CPartnerShareMgr).New(self,iPid)
    o.m_iPid = iPid
    o.m_mPartner = {}
    o.m_oPartnerShare = CPartnerShare:New()
    o.m_oPartnerShare:Init()
    return o
end

function CPartnerShareMgr:Release()
    self.m_mPartner = nil
    baseobj_safe_release(self.m_oPartnerShare)
    super(CPartnerShareMgr).Release(self)
end

function CPartnerShareMgr:PackAmountData()
    return {
        partner = self.m_mPartner,
    }
end

function CPartnerShareMgr:GenReaderCopy()
    return self.m_oPartnerShare:GenReaderCopy()
end

function CPartnerShareMgr:HasPartner(iPartype)
    return self.m_mPartner[iPartype]
end

function CPartnerShareMgr:AddPartner(iPartype, mData)
    if self:HasPartner(iPartype) then
        return
    end
    self.m_oPartnerShare:PrepareUpdate()
    self.m_mPartner[iPartype] = mData
end

function CPartnerShareMgr:ShareUpdateAmount()
    self:UnDirty()
    local mData = self:PackAmountData()
    self.m_oPartnerShare:UpdateData(mData)
end

CPartnerShare = {}
CPartnerShare.__index = CPartnerShare
inherit(CPartnerShare, shareobj.CShareWriter)

function CPartnerShare:New()
    local o = super(CPartnerShare).New(self)
    o.m_mPartner = {}
    return o
end

function CPartnerShare:UpdateData(mData)
    if self:IsUpdate() then
        self.m_mPartner = mData.partner
        self:Update()
    end
end

function CPartnerShare:Pack()
    local m = {}
    m.partner = self.m_mPartner
    return m
end