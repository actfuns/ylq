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
    o.m_oPartnerShare = CPartnerShare:New()
    return o
end

function CPartnerShareMgr:Release()
    baseobj_safe_release(self.m_oPartnerShare)
    super(CPartnerShareMgr).Release(self)
end

function CPartnerShareMgr:InitShareObj(oRemoteShare)
    self.m_oPartnerShare:Init(oRemoteShare)
end

function CPartnerShareMgr:ShareUpdate()
    self.m_oPartnerShare:Update()
end

function CPartnerShareMgr:GetPartner(iPartype)
    return self.m_oPartnerShare:GetPartner(iPartype)
end

CPartnerShare = {}
CPartnerShare.__index = CPartnerShare
inherit(CPartnerShare, shareobj.CShareReader)

function CPartnerShare:New()
    local o = super(CPartnerShare).New(self)
    o.m_mPartner = {}
    return o
end

function CPartnerShare:GetPartner(iPartype)
    self:Update()
    return self.m_mPartner[iPartype]
end

function CPartnerShare:Unpack(m)
    self.m_mPartner = m.partner or self.m_mPartner
end