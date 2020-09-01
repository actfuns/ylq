--import module

local servicetime = require "base.servicetimer"
local servicesave = require "base.servicesave"
local memcmp = require "base.memcmp"
local tbpool = require "base.tbpool"

local basedefines = import(lualib_path("base.basedefines"))

function NewEventCtrl(...)
    return CEventCtrl:New(...)
end

CBaseObject = {}
CBaseObject.__index = CBaseObject

function CBaseObject:New()
    local o = setmetatable(tbpool.Pop(), self)
    --local o = setmetatable({}, self)
    o.m_oTimer = nil
    o.m_oEventCtrl = nil
    o.m_iSaveId = nil
    --lxldebug for mem leak
    memcmp.track(o)
    return o
end

function CBaseObject:Release()
    if self.m_oTimer then
        self.m_oTimer:Release()
        self.m_oTimer = nil
    end
    if self.m_oEventCtrl then
        self.m_oEventCtrl:Release()
        self.m_oEventCtrl = nil
    end
    if self.m_iSaveId then
        self:CancelSave()
    end

    release(self)
    tbpool.Push(self)
end

function CBaseObject:AddTimeCb(sKey, iDelay, func)
    if not self.m_oTimer then
        self.m_oTimer = servicetime.NewTimer()
    end
    self.m_oTimer:AddCallback(sKey, iDelay, func)
end

function CBaseObject:DelTimeCb(sKey)
    if self.m_oTimer then
        self.m_oTimer:DelCallback(sKey)
    end
end

function CBaseObject:GetTimeCb(sKey)
    if self.m_oTimer then
        return self.m_oTimer:GetCallback(sKey)
    end
end

function CBaseObject:AddEvent(obj, iType, func)
    if not self.m_oEventCtrl then
        self.m_oEventCtrl = CEventCtrl:New()
    end
    self.m_oEventCtrl:AddEvent(obj, iType, func)
end

function CBaseObject:DelEvent(obj, iType)
    if self.m_oEventCtrl then
        self.m_oEventCtrl:DelEvent(obj, iType)
    end
end

function CBaseObject:TriggerEvent(iType, mData)
    if self.m_oEventCtrl then
        self.m_oEventCtrl:TriggerEvent(iType, mData)
    end
end

function CBaseObject:ApplySave(f, iTime)
    assert(not self.m_iSaveId, "ApplySave fail")
    self.m_iSaveId = servicesave.NewSaveObj(f, iTime)
end

function CBaseObject:GetSaveId()
    return self.m_iSaveId
end

function CBaseObject:CancelSave()
    assert(self.m_iSaveId, "CancelSave fail")
    servicesave.DelSaveObj(self.m_iSaveId)
    self.m_iSaveId = nil
end

function CBaseObject:DoSave()
    assert(self.m_iSaveId, "DoSave fail")
    servicesave.DoSaveObj(self.m_iSaveId)
end

function CBaseObject:AddSaveMerge(obj)
    assert(self.m_iSaveId and obj:GetSaveId(), "AddSaveMerge fail")
    if self.m_iSaveId ~= obj:GetSaveId() then
        servicesave.AddSaveMerge(self.m_iSaveId, obj:GetSaveId())
    end
end


CEventCtrl = {}
CEventCtrl.__index = CEventCtrl

function CEventCtrl:New()
    local o = setmetatable({}, self)
    o.m_mHandler = {}
    return o
end

function CEventCtrl:Release()
    release(self)
end

function CEventCtrl:AddEvent(obj, iType, func)
    local sKey = tostring(obj)
    if not self.m_mHandler[iType] then
        self.m_mHandler[iType] = {}
    end
    self.m_mHandler[iType][sKey] = func
end

function CEventCtrl:DelEvent(obj, iType)
    local sKey = tostring(obj)
    if self.m_mHandler[iType] then
        self.m_mHandler[iType][sKey] = nil
    end
end

function CEventCtrl:TriggerEvent(iType, mData)
    local m = self.m_mHandler[iType]
    if m then
        for k, func in pairs(m) do
            safe_call(func, iType, mData)
        end
    end
end
