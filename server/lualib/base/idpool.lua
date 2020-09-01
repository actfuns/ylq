--import module

local skynet = require "skynet"

CIDPool = {}
CIDPool.__index = CIDPool

local floor = math.floor
local max = math.max
local tinsert = table.insert
local tremove = table.remove

function CIDPool:New(t, i)
    local o = setmetatable({}, self)
    o.m_iAvailableTime = floor(max(t, 0))
    o.m_iBaseId = floor(max(i or 0, 0))
    o.m_mCollect = {}
    o.m_mProduct = {}
    return o
end

function CIDPool:Init()
end

function CIDPool:Release()
end

function CIDPool:ChangeAvailableTime(t)
    self.m_iAvailableTime = floor(max(t, 0))
end

function CIDPool:Produce()
    local iNowTime = get_time()
    local iAvailableTime = self.m_iAvailableTime
    local m = {}
    for k, v in pairs(self.m_mCollect) do
        if iNowTime - v >= iAvailableTime then
            m[k] = 1
        end
    end
    for k, _ in pairs(m) do
        self.m_mCollect[k] = nil
        self.m_mProduct[k] = 1
    end
end

function CIDPool:Free(id)
    if id >= 0 and id <= self.m_iBaseId and not self.m_mCollect[id] and not self.m_mProduct[id] then
        self.m_mCollect[id] = get_time()
    else
        print(string.format("CIDPool Free error:%s", id))
    end
end

function CIDPool:Gain()
    local m = self.m_mProduct
    local id = next(m)
    if id then
        m[id] = nil
        return id
    end
    self.m_iBaseId = self.m_iBaseId + 1
    return self.m_iBaseId
end
