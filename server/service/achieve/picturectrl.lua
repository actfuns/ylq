local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loadachieve = import(service_path("loadachieve"))

function NewPictureCtrl()
    local o = CPictureCtrl:New()
    return o
end

CPictureCtrl = {}
CPictureCtrl.__index = CPictureCtrl
inherit(CPictureCtrl, datactrl.CDataCtrl)

function CPictureCtrl:New()
    local o = super(CPictureCtrl).New(self)
    o.m_mList = {}
    o.openui=0
    return o
end

function CPictureCtrl:Release()
    for _, oAchieve in pairs(self.m_mList) do
        baseobj_safe_release(oAchieve)
    end
    self.m_mList = nil
    super(CPictureCtrl).Release(self)
end

function CPictureCtrl:Load(mData)
    local mPictureData = mData["picture"] or {}
    for sPictureID,data in pairs(mPictureData) do
        local iPictureID = tonumber(sPictureID)
        local oPicture = loadachieve.LoadPicture(iPictureID,data)
        self.m_mList[iPictureID] = oPicture
    end
    self.m_iOpenUI = mData["openui"] or 0
end

function CPictureCtrl:Save()
    local mData = {}
    local mPictureData = {}
    for iPictureID,oPicture in pairs(self.m_mList) do
        mPictureData[db_key(iPictureID)] = oPicture:Save()
    end
    mData["picture"] = mPictureData
    mData["openui"] = self.m_iOpenUI
    return mData
end

function CPictureCtrl:UnDirty()
    super(CPictureCtrl).UnDirty(self)
    for _,oAchieve in pairs(self.m_mList) do
        oAchieve:UnDirty()
    end

end

function CPictureCtrl:IsDirty()
   if super(CPictureCtrl).IsDirty(self) then
        return true
    end
    for _,oAchieve in pairs(self.m_mList) do
        if oAchieve:IsDirty() then
            return true
        end
    end
    return false
end

function CPictureCtrl:GetUIStatus()
    return self.m_iOpenUI
end

function CPictureCtrl:OpenUI()
    if self.m_iOpenUI == 1 then
        return
    end
    self.m_iOpenUI = 1
    self:Dirty()
end

function CPictureCtrl:GetList()
    return self.m_mList
end

function CPictureCtrl:GetPicture(iPictureID)
    return self.m_mList[iPictureID]
end

function CPictureCtrl:AddPicture(iPictureID)
    self:Dirty()
    self.m_mList[iPictureID] = loadachieve.CreatePicture(iPictureID)
    return self.m_mList[iPictureID]
end

function CPictureCtrl:RemoveAchieve(iPictureID)
    self:Dirty()
    local oAchieve = self.m_mList[iPictureID]
    if oAchieve then
        baseobj_delay_release(oAchieve)
    end
    self.m_mList[iPictureID] = nil
end

function CPictureCtrl:SetPicDegree(iPid,iPictureID,sKey,iTarget,iValue)
    self:Dirty()
    local oPicture = self:GetPicture(iPictureID)
    if not oPicture then
        oPicture = self:AddPicture(iPictureID)
    end
    oPicture:SetDegree(iPid,sKey,iTarget,iValue)
end

function CPictureCtrl:SignReward(iPictureID)
    local oPicture = self:GetPicture(iPictureID)
    if not oPicture then
        return false
    end
    return oPicture:SignReward()
end

function CPictureCtrl:TestCmd(oPlayer, sCmd, m, sReason)
end
