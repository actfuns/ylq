
local skynet = require "skynet"
local ltimer = require "ltimer"
local rt_monitor = require "base.rt_monitor"

local M = {}
local iTestOverflow = 0

local tremove = table.remove
local tinsert = table.insert
local mmax = math.max
local mfloor = math.floor

local oTimerMgr

local function Trace(sMsg)
    print(debug.traceback(sMsg))
end

local DriverFunc
DriverFunc = function ()
    if not oTimerMgr.m_bExecute then
        oTimerMgr:FlushNow()
        oTimerMgr.m_bExecute = true
        oTimerMgr.m_oCobj:ltimer_update(oTimerMgr:GetTime(), oTimerMgr.m_lCbHandles)
        oTimerMgr:ProxyFunc()
        oTimerMgr.m_bExecute = false
        skynet.timeout(1, DriverFunc)
    end
end

local CTimer = {}
CTimer.__index = CTimer

function CTimer:New()
    local o = setmetatable({}, self)
    o.m_mName2Id = {}
    return o
end

function CTimer:Release()
    for k, v in pairs(self.m_mName2Id) do
        oTimerMgr:DelCallback(v)
    end
    self.m_mName2Id = {}

    release(self)
end

function CTimer:AddCallback(sKey, iDelay, func)
    assert(iDelay>0,string.format("CTimer AddCallback delay error too small %s %s", sKey, iDelay))
    iDelay = mmax(1, mfloor(iDelay/10))
    assert(iDelay<2^32, string.format("CTimer AddCallback delay error too huge %s %s", sKey, iDelay))
    assert(func, string.format("CTimer AddCallback func error , func is nil %s %s", sKey, iDelay))
    local iOldId = self.m_mName2Id[sKey]
    if iOldId and not oTimerMgr:GetCallback(iOldId) then
        self.m_mName2Id[sKey] = nil
        iOldId = nil
    end

    local mName2Id = self.m_mName2Id
    local f
    f = function ()
        local id = mName2Id[sKey]
        if not id then
            return
        end
        mName2Id[sKey] = nil

        rt_monitor.mo_call({"servicetimer", sKey}, func)
    end

    local iNewId = oTimerMgr:AddCallback(iDelay, f)
    self.m_mName2Id[sKey] = iNewId
    if iOldId then
        print(string.format("[WARNING] CTimer AddCallback repeated %s %d %d %s", sKey, iOldId, iNewId,debug.traceback()))
    end
end

function CTimer:DelCallback(sKey)
    local id = self.m_mName2Id[sKey]
    if id then
        self.m_mName2Id[sKey] = nil
        oTimerMgr:DelCallback(id)
    end
end

function CTimer:GetCallback(sKey)
    local id = self.m_mName2Id[sKey]
    if not id then
        return nil
    end
    return oTimerMgr:GetCallback(id)
end


local CTimerMgr = {}
CTimerMgr.__index = CTimerMgr

function CTimerMgr:New()
    local o = setmetatable({}, self)

    o.m_lCbHandles = {}
    o.m_iCbDispatchId = 0
    o.m_bExecute = false
    o.m_mCbUsedId = {}
    o.m_lCbReUseId = {}

    o:FlushStart()
    o:FlushNow()
    o.m_oCobj = ltimer.ltimer_create(o:GetTime())

    return o
end

function CTimerMgr:Release()
    release(self)
end

function CTimerMgr:Init()
    skynet.timeout(1, DriverFunc)
end

function CTimerMgr:FlushStart()
    self.m_iServiceStartTime = skynet.starttime()
end

function CTimerMgr:FlushNow()
    self.m_iServiceNow = skynet.now()
end

function CTimerMgr:GetTime()
    return self.m_iServiceStartTime*100+self.m_iServiceNow+iTestOverflow
end

function CTimerMgr:GetNow()
    return self.m_iServiceNow
end

function CTimerMgr:GetStartTime()
    return self.m_iServiceStartTime
end

function CTimerMgr:NewTimer()
    return CTimer:New()
end

function CTimerMgr:GetCbDispatchId()
    local l = self.m_lCbReUseId
    local id = tremove(l, #l)
    if id then
        return id
    end
    self.m_iCbDispatchId = self.m_iCbDispatchId + 1
    return self.m_iCbDispatchId
end

function CTimerMgr:AddCallback(iDelay, func)
    local iCbId = self:GetCbDispatchId()
    self.m_mCbUsedId[iCbId] = func
    self.m_oCobj:ltimer_add_time(iCbId, iDelay)
    return iCbId
end

function CTimerMgr:DelCallback(iCbId)
    self.m_mCbUsedId[iCbId] = nil
end

function CTimerMgr:GetCallback(iCbId)
    return self.m_mCbUsedId[iCbId]
end

function CTimerMgr:ProxyFunc()
    for _, v in ipairs(self.m_lCbHandles) do
        tinsert(self.m_lCbReUseId, v)
        local f = self.m_mCbUsedId[v]
        if f then
            self.m_mCbUsedId[v] = nil
            xpcall(f, Trace)
        end
    end
    list_clear(self.m_lCbHandles)
end


function M.Init()
    if not oTimerMgr then
        oTimerMgr = CTimerMgr:New()
        oTimerMgr:Init()
    end
end

function M.NewTimer()
    return oTimerMgr:NewTimer()
end

function M.AddCallback(iDelay, func)
    assert(iDelay>0, string.format("servicetimer AddCallback delay error too small %s", iDelay))
    iDelay = mmax(1, mfloor(iDelay/10))
    assert(iDelay<2^32, string.format("servicetimer AddCallback delay error too huge %s", iDelay))
    return oTimerMgr:AddCallback(iDelay, func)
end

function M.DelCallback(iCbId)
    oTimerMgr:DelCallback(iCbId)
end

function M.TestOverflow(i)
    iTestOverflow = i
end

function M.ServiceTime()
    return oTimerMgr:GetTime()
end

function M.ServiceNow()
    return oTimerMgr:GetNow()
end

function M.ServiceStartTime()
    return oTimerMgr:GetStartTime()
end

return M
