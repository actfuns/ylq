--import module

local global = require "global"
local skynet = require "skynet"

local shareobj = import(lualib_path("base.shareobj"))
local attrmgr = import(lualib_path("public.attrmgr"))

function NewStoneMgr(iPid)
    local o = CStoneMgr:New(iPid)
    return o
end

CStoneMgr = {}
CStoneMgr.__index =CStoneMgr
inherit(CStoneMgr,attrmgr.CAttrMgr)

function CStoneMgr:New(iPid)
    local o = super(CStoneMgr).New(self,iPid)
    o.m_iPid = iPid
    o.m_oStoneMgrShareObj = CStoneMgrShareObj:New()
    o.m_oStoneMgrShareObj:Init()
    return o
end

function CStoneMgr:Release()
    baseobj_safe_release(self.m_oStoneMgrShareObj)
    super(CStoneMgr).Release(self)
end

function CStoneMgr:PackRemoteData()
    return {
        apply = self.m_mApply,
        ratio_apply = self.m_mRatioApply,
    }
end

function CStoneMgr:UpdateData()
    if not self:IsDirty() then
        return
    end
    self:UnDirty()
    local mData = self:PackRemoteData()
    self.m_oStoneMgrShareObj:UpdateData(mData)
end

function CStoneMgr:GetStoneMgrReaderCopy()
    return self.m_oStoneMgrShareObj:GenReaderCopy()
end

function CStoneMgr:ShareUpdate()
    self:UnDirty()
    local mData = self:PackRemoteData()
    self.m_oStoneMgrShareObj:UpdateData(mData)
end

CStoneMgrShareObj = {}
CStoneMgrShareObj.__index = CStoneMgrShareObj
inherit(CStoneMgrShareObj, shareobj.CShareWriter)

function CStoneMgrShareObj:New()
    local o = super(CStoneMgrShareObj).New(self)
    o.m_mApply = {}
    o.m_mRatioApply = {}
    return o
end

function CStoneMgrShareObj:UpdateData(mData)
    self.m_mApply = mData.apply or {}
    self.m_mRatioApply = mData.ratio_apply or {}
    self:Update()
end

function CStoneMgrShareObj:Pack()
    local m = {}
    m.apply = self.m_mApply
    m.ratio_apply = self.m_mRatioApply
    return m
end