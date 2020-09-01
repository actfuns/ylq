local skynet = require "skynet"
local global = require "global"
local interactive = require "base.interactive"
local extend = require "base.extend"
local record = require "public.record"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))

CBaseOfflineCtrl = {}
CBaseOfflineCtrl.__index = CBaseOfflineCtrl
inherit(CBaseOfflineCtrl, datactrl.CDataCtrl)

function CBaseOfflineCtrl:New(iPid)
    local o = super(CBaseOfflineCtrl).New(self, {pid = iPid})
    o.m_iPid = iPid
    o.m_iLastTime = get_time()
    o.m_bLoading = true
    o.m_lWaitFuncList = {}
    o.m_sDbFlag = nil
    return o
end

function CBaseOfflineCtrl:LoadFinish()
    self.m_bLoading = false
end

function CBaseOfflineCtrl:GetPid()
    return self.m_iPid
end

function CBaseOfflineCtrl:GetDbFlag()
    assert(self.m_sDbFlag, "GetDbFlag fail")
    return self.m_sDbFlag
end

function CBaseOfflineCtrl:GetSaveDbFlag()
    assert(self.m_sDbFlag, "GetSaveDbFlag fail")
    return "SaveOffline"..self.m_sDbFlag
end

function CBaseOfflineCtrl:GetLoadDbFlag()
    assert(self.m_sDbFlag, "GetLoadDbFlag fail")
    return "LoadOffline"..self.m_sDbFlag
end

function CBaseOfflineCtrl:SetLastTime()
    self.m_iLastTime = get_time()
end

function CBaseOfflineCtrl:GetLastTime()
    return self.m_iLastTime
end

function CBaseOfflineCtrl:AddWaitFunc(func)
    table.insert(self.m_lWaitFuncList, func)
end

function CBaseOfflineCtrl:WakeUpFunc()
    for _, func in ipairs(self.m_lWaitFuncList) do
        func(self)
    end
    self:SetLastTime()
end

function CBaseOfflineCtrl:WakeUpFailFunc()
    for _, func in ipairs(self.m_lWaitFuncList) do
        func(nil)
    end
end

function CBaseOfflineCtrl:IsLoading()
    return self.m_bLoading
end

function CBaseOfflineCtrl:IsActive()
    local iNowTime = get_time()
    if iNowTime - self:GetLastTime() <= 5 * 60 then
        return true
    end
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self:GetPid())
    if oPlayer then
        return true
    end
    return false
end

function CBaseOfflineCtrl:Save()
    local mData = {}
    return mData
end

function CBaseOfflineCtrl:Load(m)
end

function CBaseOfflineCtrl:OnLogin()
end

function CBaseOfflineCtrl:OnLogout(oPlayer)
    self:SaveDb()
end

function CBaseOfflineCtrl:OnDisconnected(oPlayer)
end

function CBaseOfflineCtrl:Schedule()
    local oWorldMgr = global.oWorldMgr
    local sDbFlag = self:GetDbFlag()
    local iPid = self:GetPid()
    local f1
    f1 = function ()
        local oBaseOfflineCtrl = oWorldMgr:GetOfflineObject(sDbFlag,iPid)
        oBaseOfflineCtrl:DelTimeCb("_CheckClean")
        oBaseOfflineCtrl:AddTimeCb("_CheckClean", 2*60*1000, f1)
        oBaseOfflineCtrl:_CheckClean()
    end
    f1()
end

function CBaseOfflineCtrl:ConfigSaveFunc()
    local sDbFlag = self:GetDbFlag()
    local iPid = self:GetPid()
    self:ApplySave(function ()
        local oWorldMgr = global.oWorldMgr
        local obj = oWorldMgr:GetOfflineObject(sDbFlag, iPid)
        if not obj then
            record.warning(string.format("%s offline %s save err: no obj",iPid,sDbFlag))
            return
        end
        obj:_CheckSaveDb()
    end)
end

function CBaseOfflineCtrl:_CheckSaveDb()
    assert(not is_release(self), "_CheckSaveDb fail")
    self:SaveDb()
end

function CBaseOfflineCtrl:SaveDb()
    local sFlag = self:GetSaveDbFlag()
   if self:IsDirty() then
        local mData = {
            pid = self:GetPid(),
            data = self:Save()
        }
        gamedb.SaveDb(self:GetPid(),"common","SaveDb", {module="offlinedb",cmd=sFlag,data = mData})
        self:UnDirty()
    end
end

function CBaseOfflineCtrl:_CheckClean()
    assert(not is_release(self), "_CheckClean fail")
    if not self:IsLoading() and not self:IsActive() then
        local oWorldMgr = global.oWorldMgr
        oWorldMgr:CleanOfflineBlock(self:GetDbFlag(), self:GetPid())
    end
end
