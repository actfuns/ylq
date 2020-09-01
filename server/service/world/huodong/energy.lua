-- import module
local res = require "base.res"
local global = require "global"

local xgpush = import(lualib_path("public.xgpush"))
local huodongbase = import(service_path("huodong.huodongbase"))

function NewHuodong(sHuodongName)
    return CHuodong:New(sHuodongName)
end

CHuodong = {}
CHuodong.__index = CHuodong
CHuodong.m_sTempName = "体力"
inherit(CHuodong, huodongbase.CHuodong)

function CHuodong:New(sHuodongName)
    local o = super(CHuodong).New(self, sHuodongName)
    o:Init()
    return o
end

function CHuodong:Init()
    self.m_mCheck = {}
end

function CHuodong:OnLogin(oPlayer)
    if self.m_mCheck[oPlayer.m_iPid] then
        self:Dirty()
        self.m_mCheck[oPlayer.m_iPid] = nil
    end
end

function CHuodong:OnLogout(oPlayer)
    if oPlayer.m_oActiveCtrl:IsGamePush("energy") then
        return
    end
    local iEnergy = oPlayer.m_oActiveCtrl:GetEnergy()
    local iMaxEnergy = oPlayer.m_oActiveCtrl:GetMaxEnergy()
    if iEnergy < iMaxEnergy then
        self:Dirty()
        local iAdd = iMaxEnergy - iEnergy
        local iRecoveryTime = self:GetEnergyRecoveryTime()
        local iTime = iAdd*iRecoveryTime*60
        local iEndTime = get_time() + iTime
        self.m_mCheck[oPlayer.m_iPid] = iEndTime
        if table_count(self.m_mCheck) == 1 then
            self:CheckEnergy()
        end
    end
end

function CHuodong:NeedSave()
    return true
end

function CHuodong:Save()
    local mData = {}
    mData.check = self.m_mCheck
    return mData
end

function CHuodong:MergeFrom(mFromData, mArgs)
    self:Dirty()
    local mData = mFromData.check or {}
    for iPid,iEndTime in pairs() do
        self.m_mCheck[iPid] = iEndTime
    end
    return true
end

function CHuodong:Load(mData)
    self.m_mCheck = mData.check or {}
    self:CheckEnergy()
end

function CHuodong:GetEnergyRecoveryTime()
    local mConfig = res["daobiao"]["global"]["energy_recovertime"]
    return tonumber(mConfig["value"] or 10)
end

function CHuodong:CheckEnergy()
    self:DelTimeCb("CheckRecoveryEnergy")
    local iTime = get_time()
    self:Dirty()
    for iPid,iEndTime in pairs(self.m_mCheck) do
        if iTime >= iEndTime then
            self.m_mCheck[iPid] = nil
            self:PushToClient(iPid,10002)
        end
    end
    local func = function()
        local oHuodong = global.oHuodongMgr:GetHuodong("energy")
        if oHuodong then
            oHuodong:CheckEnergy()
        end
    end
    if table_count(self.m_mCheck) > 0 then
        self:AddTimeCb("CheckRecoveryEnergy",5*60*1000,func)
    end
end

function CHuodong:PushToClient(iPid,iPushId)
    xgpush.PushById(iPid, iPushId)
end