local global = require "global"
local skynet = require "skynet"
local extend = require "base.extend"

local datactrl = import(lualib_path("public.datactrl"))

function NewImage(sKey)
    local o = CImage:New(sKey)
    o:Dirty()
    return o
end

function LoadImage(sKey,mData)
    local o = CImage:New(sKey)
    o:Load(mData)
    return o
end

CImage = {}
CImage.__index =CImage
inherit(CImage,datactrl.CDataCtrl)

function CImage:New(sKey)
    local o = super(CImage).New(self)
    o.m_sKey = sKey
    o:Init()
    return o
end

function CImage:Init()
    self.m_Check = 0
    self.m_CreateTime = get_time()
end

function CImage:Save()
    local mData = {}
    mData["key"] = self.m_sKey or ""
    mData["check"] = self.m_Check or 0
    mData["create_time"] = self.m_CreateTime
    return mData
end

function CImage:Load(mData)
    mData = mData or {}
    self.m_sKey = mData["key"] or ""
    self.m_Check = mData["check"] or 0
    self.m_CreateTime = mData["create_time"] or get_time()
end

function CImage:Key()
    return self.m_sKey
end

function CImage:IsCheck()
    return self.m_Check ~= 0
end

function CImage:GetCreateTime()
    return self.m_CreateTime
end

function CImage:CheckPass()
    self:Dirty()
    self.m_Check = 1
end