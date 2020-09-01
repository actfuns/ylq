local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loadachieve = import(service_path("loadachieve"))

function NewAchieveCtrl()
    local o = CAchieveCtrl:New()
    return o
end

CAchieveCtrl = {}
CAchieveCtrl.__index = CAchieveCtrl
inherit(CAchieveCtrl, datactrl.CDataCtrl)

function CAchieveCtrl:New()
    local o = super(CAchieveCtrl).New(self)
    o.m_mList = {}
    o.m_Already={}
    o.m_LoadFinish = false
    return o
end

function CAchieveCtrl:Release()
    for _, oAchieve in pairs(self.m_mList) do
        baseobj_safe_release(oAchieve)
    end
    self.m_mList = nil
    super(CAchieveCtrl).Release(self)
end

function CAchieveCtrl:Load(mData)
    local mAchieveData = mData["achieve"] or {}
    for sAchieveID,data in pairs(mAchieveData) do
        local iAchieveID = tonumber(sAchieveID)
        if loadachieve.IsExistAchieve(iAchieveID) then
            local oAchieve = loadachieve.LoadAchieve(iAchieveID,data)
            oAchieve:FixDegree()
            self.m_mList[iAchieveID] = oAchieve
        end
    end
    self.m_Already = mData["already"] or {}
    self.m_LoadFinish = true
end

function CAchieveCtrl:IsLoadFinish()
    return self.m_LoadFinish
end

function CAchieveCtrl:Save()
    local mData = {}
    local mAchieveData = {}
    for iAchieveID,oAchieve in pairs(self.m_mList) do
        mAchieveData[db_key(iAchieveID)] = oAchieve:Save()
    end
    mData["achieve"] = mAchieveData
    mData["already"] = self.m_Already
    return mData
end

function CAchieveCtrl:UnDirty()
    super(CAchieveCtrl).UnDirty(self)
    for _,oAchieve in pairs(self.m_mList) do
        oAchieve:UnDirty()
    end

end

function CAchieveCtrl:IsDirty()
   if super(CAchieveCtrl).IsDirty(self) then
        return true
    end
    for _,oAchieve in pairs(self.m_mList) do
        if oAchieve:IsDirty() then
            return true
        end
    end
    return false
end

function CAchieveCtrl:GetList()
    return self.m_mList
end

function CAchieveCtrl:GetAchieve(iAchieveID)
    return self.m_mList[iAchieveID]
end

function CAchieveCtrl:AddAchieve(iAchieveID)
    self:Dirty()
    self.m_mList[iAchieveID] = loadachieve.CreateAchieve(iAchieveID)
    return self.m_mList[iAchieveID]
end

function CAchieveCtrl:RemoveAchieve(iAchieveID)
    self:Dirty()
    local oAchieve = self.m_mList[iAchieveID]
    if oAchieve then
        baseobj_delay_release(oAchieve)
    end
    self.m_mList[iAchieveID] = nil
end

function CAchieveCtrl:AddAchDegree(iAchieveID,iAdd)
    local oAchieve = self:GetAchieve(iAchieveID)
    if not oAchieve then
        oAchieve = self:AddAchieve(iAchieveID)
    end
    oAchieve:AddDegree(iAdd)
end

function CAchieveCtrl:SetAchDegree(iAchieveID,iDegree)
    local oAchieve = self:GetAchieve(iAchieveID)
    if not oAchieve then
        oAchieve = self:AddAchieve(iAchieveID)
    end
    oAchieve:SetAchDegree(iDegree)
end

function CAchieveCtrl:SignReward(iAchieveID)
    local oAchieve = self:GetAchieve(iAchieveID)
    if not oAchieve then
        return false
    end
    return oAchieve:SignReward()
end

function CAchieveCtrl:SignAlready(id)
    if not table_in_list(self.m_Already,id) then
        self:Dirty()
        table.insert(self.m_Already,id)
        return true
    end
    return false
end

function CAchieveCtrl:GetAlready()
    return self.m_Already
end

function CAchieveCtrl:TestCmd(oPlayer, sCmd, m, sReason)
end
