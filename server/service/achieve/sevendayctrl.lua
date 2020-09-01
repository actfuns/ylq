local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"

local datactrl = import(lualib_path("public.datactrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loadachieve = import(service_path("loadachieve"))

function NewSevenDayCtrl()
    local o = CSevenDayCtrl:New()
    return o
end

CSevenDayCtrl = {}
CSevenDayCtrl.__index = CSevenDayCtrl
inherit(CSevenDayCtrl, datactrl.CDataCtrl)

function CSevenDayCtrl:New()
    local o = super(CSevenDayCtrl).New(self)
    o.m_mList = {}
    o.m_Already={}
    o.m_Sended = false
    o.m_LoadFinish = false
    return o
end

function CSevenDayCtrl:Release()
    for _, oAchieve in pairs(self.m_mList) do
        baseobj_safe_release(oAchieve)
    end
    self.m_mList = nil
    super(CSevenDayCtrl).Release(self)
end

function CSevenDayCtrl:Load(mData)
    local mAchieveData = mData["achieve"] or {}
    for sAchieveID,data in pairs(mAchieveData) do
        local iAchieveID = tonumber(sAchieveID)
        local oAchieve = loadachieve.LoadSevenDay(iAchieveID,data)
        self.m_mList[iAchieveID] = oAchieve
    end
    self.m_Already = mData["already"] or {}
    self.m_Sended = mData["sended"] or false
    self.m_LoadFinish = true
end

function CSevenDayCtrl:IsLoadFinish()
    return self.m_LoadFinish
end

function CSevenDayCtrl:Save()
    local mData = {}
    local mAchieveData = {}
    for iAchieveID,oAchieve in pairs(self.m_mList) do
        mAchieveData[db_key(iAchieveID)] = oAchieve:Save()
    end
    mData["achieve"] = mAchieveData
    mData["already"] = self.m_Already
    mData["sended"] = self.m_Sended
    return mData
end

function CSevenDayCtrl:UnDirty()
    super(CSevenDayCtrl).UnDirty(self)
    for _,oAchieve in pairs(self.m_mList) do
        oAchieve:UnDirty()
    end

end

function CSevenDayCtrl:IsDirty()
   if super(CSevenDayCtrl).IsDirty(self) then
        return true
    end
    for _,oAchieve in pairs(self.m_mList) do
        if oAchieve:IsDirty() then
            return true
        end
    end
    return false
end

function CSevenDayCtrl:GetList()
    return self.m_mList
end

function CSevenDayCtrl:GetAchieve(iAchieveID)
    return self.m_mList[iAchieveID]
end

function CSevenDayCtrl:AddAchieve(iAchieveID)
    self:Dirty()
    self.m_mList[iAchieveID] = loadachieve.CreateSevenDay(iAchieveID)
    return self.m_mList[iAchieveID]
end

function CSevenDayCtrl:RemoveAchieve(iAchieveID)
    self:Dirty()
    local oAchieve = self.m_mList[iAchieveID]
    if oAchieve then
        baseobj_delay_release(oAchieve)
    end
    self.m_mList[iAchieveID] = nil
end

function CSevenDayCtrl:AddAchDegree(iAchieveID,iAdd)
    local oAchieve = self:GetAchieve(iAchieveID)
    if not oAchieve then
        oAchieve = self:AddAchieve(iAchieveID)
    end
    oAchieve:AddDegree(iAdd)
end

function CSevenDayCtrl:SetAchDegree(iAchieveID,iDegree)
    local oAchieve = self:GetAchieve(iAchieveID)
    if not oAchieve then
        oAchieve = self:AddAchieve(iAchieveID)
    end
    oAchieve:SetAchDegree(iDegree)
end

function CSevenDayCtrl:SignReward(iAchieveID)
    local oAchieve = self:GetAchieve(iAchieveID)
    if not oAchieve then
        return false
    end
    return oAchieve:SignReward()
end

function CSevenDayCtrl:SignAlready(id)
    if not table_in_list(self.m_Already,id) then
        self:Dirty()
        table.insert(self.m_Already,id)
        return true
    end
    return false
end

function CSevenDayCtrl:GetAlready()
    return self.m_Already
end

function CSevenDayCtrl:IsDone(iAchieveID)
    local oAchieve = self:GetAchieve(iAchieveID)
    if oAchieve then
        return oAchieve:IsDone()
    end
    return false
end

function CSevenDayCtrl:SetSend()
    if self.m_Sended then
        return
    end
    self:Dirty()
    self.m_Sended = true
end

function CSevenDayCtrl:IsSend()
    return self.m_Sended
end

function CSevenDayCtrl:CheckFix(iPid,sCmd,mData)
    local func = self[sCmd]
    if func then
        func(self, iPid, mData)
    end
end

function CSevenDayCtrl:FixGemLevel(iPid, mData)
    local oAchieveMgr = global.oAchieveMgr
    mData = mData or {}
    local iAchieveID = 10302
    local oAchieve = self:GetAchieve(iAchieveID)
    if not oAchieve then
        if oAchieveMgr:HasSevenDay(iAchieveID) then
            oAchieve = self:AddAchieve(iAchieveID)
        end
    end
    if oAchieve then
        local iCntLv = mData.level or 0
        local iDegree = oAchieve:GetDeGree()
        if iDegree < iCntLv then
            oAchieveMgr:AddSevenDayDegress(iPid, iAchieveID, iCntLv - iDegree)
        end
    end
end

function CSevenDayCtrl:TestCmd(oPlayer, sCmd, m, sReason)
end
