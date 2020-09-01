local global = require "global"
local extend = require "base.extend"

local datactrl = import(lualib_path("public.datactrl"))
local imageobj = import(service_path("imageobj"))

function NewImageCtrl()
    local o = CImageCtrl:New()
    return o
end

CImageCtrl = {}
CImageCtrl.__index = CImageCtrl
inherit(CImageCtrl, datactrl.CDataCtrl)

function CImageCtrl:New()
    local o = super(CImageCtrl).New(self)
    o.m_mList = {}
    o.m_mDelList = {}
    return o
end

function CImageCtrl:Release()
    for _, oImage in pairs(self.m_mList) do
        baseobj_safe_release(oImage)
    end
    self.m_mList = nil
    super(CImageCtrl).Release(self)
end

function CImageCtrl:Load(mData)
    mData = mData or {}
    for sImageKey,data in pairs(mData) do
        local oImage = imageobj.LoadImage(sImageKey,data)
        self.m_mList[sImageKey] = oImage
    end
end

function CImageCtrl:Save()
    local mImageData = {}
    for sImageKey,oImage in pairs(self.m_mList) do
        if oImage:IsDirty() then
            mImageData[sImageKey] = oImage:Save()
        end
    end
    return mImageData
end

function CImageCtrl:UnDirty()
    super(CImageCtrl).UnDirty(self)
    for _,oImage in pairs(self.m_mList) do
        oImage:UnDirty()
    end
end

function CImageCtrl:IsDirty()
    for _,oImage in pairs(self.m_mList) do
        if oImage:IsDirty() then
            return true
        end
    end
    return false
end

function CImageCtrl:GetList()
    return self.m_mList
end

function CImageCtrl:GetImage(sImageKey)
    return self.m_mList[sImageKey]
end

function CImageCtrl:AddImage(sImageKey)
    self.m_mList[sImageKey] = imageobj.NewImage(sImageKey)
    return self.m_mList[sImageKey]
end

function CImageCtrl:RemoveImage(sImageKey)
    local oImage = self.m_mList[sImageKey]
    if oImage then
        baseobj_delay_release(oImage)
    end
    self.m_mList[sImageKey] = nil
    self.m_mDelList[sImageKey] = true
end

function CImageCtrl:CheckPass(sImageKey)
    local oImage = self.m_mList[sImageKey]
    if oImage then
        oImage:CheckPass()
    end
end