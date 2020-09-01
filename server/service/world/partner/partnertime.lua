local global = require "global"
local extend = require "base/extend"

local datactrl = import(lualib_path("public.datactrl"))
local timeop = import(lualib_path("base.timeop"))

function NewToday(...)
    return CToday:New(...)
end

CToday = {}
CToday.__index = CToday
inherit(CToday, datactrl.CDataCtrl)

function CToday:New(id)
    local o = super(CToday).New(self, {id = id})
    o.m_ID = id
    o.m_mData = {}
    o.m_mKeepList = {}
    return o
end

function CToday:Load(data)
    data = data or {}
    self.m_mData = data["data"] or {}
    self.m_mKeepList = data["keeplist"] or {}
end

function CToday:Save()
    local data = {}
    data["data"] = self.m_mData
    data["keeplist"]  = self.m_mKeepList
    return data
end

function CToday:Add(key,value)
    self:Validate(key)
    local iValue = self:GetData(key,0)
    iValue = iValue + value
    self:SetData(key,iValue)
    self.m_mKeepList[key] = self:GetTimeNo()
end

function CToday:Set(key,value)
    self:Validate(key)
    self:SetData(key,value)
    self.m_mKeepList[key] = self:GetTimeNo()
end

function CToday:Query(key,rDefault)
    self:Validate(key)
    return self:GetData(key,rDefault)
end

function CToday:Delete(key)
    if not self:GetData(key) then
        return
    end
    self:Dirty()
    self:SetData(key,nil)
    self.m_mKeepList[key] =nil
end

function CToday:Validate(key)
    local iDayNo = self.m_mKeepList[key]
    if not iDayNo then
        return
    end
    if iDayNo >= self:GetTimeNo() then
        return
    end
    self:SetData(key,nil)
    self.m_mKeepList[key] = nil
end

function CToday:ClearData()
    self:Dirty()
    self.m_mKeepList = {}
    self.m_mData = {}
end

function CToday:GetTimeNo()
    return timeop.get_dayno()
end