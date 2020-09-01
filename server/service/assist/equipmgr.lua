--import module

local global = require "global"
local skynet = require "skynet"

local shareobj = import(lualib_path("base.shareobj"))
local attrmgr = import(lualib_path("public.attrmgr"))

function NewEquipMgr(iPid)
    local o = CEquipMgr:New(iPid)
    return o
end

CEquipMgr = {}
CEquipMgr.__index =CEquipMgr
inherit(CEquipMgr,attrmgr.CAttrMgr)

function CEquipMgr:New(iPid)
    local o = super(CEquipMgr).New(self,iPid)
    o.m_iPid = iPid
    o.m_oEquipMgrShareObj = CEquipMgrShareObj:New()
    o.m_oEquipMgrShareObj:Init()
    return o
end

function CEquipMgr:Release()
    baseobj_safe_release(self.m_oEquipMgrShareObj)
    super(CEquipMgr).Release(self)
end

function CEquipMgr:PackRemoteData()
    return {
        apply = self.m_mApply,
        ratio_apply = self.m_mRatioApply,
        power = self:PackEquipPower(),
    }
end

function CEquipMgr:PackEquipPower()
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(self.m_iPid)
    return oPlayer.m_oItemCtrl:GetWieldEquipPower()
end

function CEquipMgr:UpdateData()
    if not self:IsDirty() then
        return
    end
    self:UnDirty()
    local mData = self:PackRemoteData()
    self.m_oEquipMgrShareObj:UpdateData(mData)
end

function CEquipMgr:GetEquipMgrReaderCopy()
    return self.m_oEquipMgrShareObj:GenReaderCopy()
end

function CEquipMgr:ShareUpdate()
    self:UnDirty()
    local mData = self:PackRemoteData()
    self.m_oEquipMgrShareObj:UpdateData(mData)
end

CEquipMgrShareObj = {}
CEquipMgrShareObj.__index = CEquipMgrShareObj
inherit(CEquipMgrShareObj, shareobj.CShareWriter)

function CEquipMgrShareObj:New()
    local o = super(CEquipMgrShareObj).New(self)
    o.m_mApply = {}
    o.m_mRatioApply = {}
    o.m_iEquipPower = 0
    return o
end

function CEquipMgrShareObj:UpdateData(mData)
    self.m_mApply = mData.apply or {}
    self.m_mRatioApply = mData.ratio_apply or {}
    self.m_iEquipPower = mData.power or self.m_iEquipPower
    self:Update()
end

function CEquipMgrShareObj:Pack()
    local m = {}
    m.apply = self.m_mApply
    m.ratio_apply = self.m_mRatioApply
    m.power = self.m_iEquipPower
    return m
end