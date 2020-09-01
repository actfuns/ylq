--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local tconcat = table.concat
local tpack = table.pack
local tinsert = table.insert
local tsort = table.sort

local WASTE_LIST_LIMIT = 10000

function NewMonitor(...)
    local o = CMonitor:New(...)
    return o
end

CMonitor = {}
CMonitor.__index = CMonitor
inherit(CMonitor, logic_base_cls())

function CMonitor:New()
    local o = super(CMonitor).New(self)
    o.m_iStartTime = get_time()
    o.m_mRecord = {}
    o.m_mWaste = {
        small = {},
        big = {},
        huge = {},
    }
    o.m_oMonitorFile = nil
    return o
end

function CMonitor:Init()
end

function CMonitor:Record(iDiffUs, lKey, sServiceName)
    local sKey = string.format("{%s}%s", sServiceName, tconcat(lKey, "."))
    local m = self.m_mRecord[sKey]
    if not m then
        m = {count = 0, total_ms = 0}
        self.m_mRecord[sKey] = m
    end
    local iDiffMs = iDiffUs/1000
    m.count = m.count + 1
    m.total_ms = m.total_ms + iDiffMs
    self:AddWaste(sKey, iDiffMs)
end

function CMonitor:AddWaste(sKey, iMs)
    if iMs >= 10 then
        tinsert(self.m_mWaste["huge"], {key = sKey, timestamp = os.date("%c", get_time()), time = iMs})
        if #self.m_mWaste["huge"] >= 2*WASTE_LIST_LIMIT then
            self:UpdateWaste("huge")
        end
    elseif iMs >= 5 then
        tinsert(self.m_mWaste["big"], {key = sKey, timestamp = os.date("%c", get_time()), time = iMs})
        if #self.m_mWaste["big"] >= 2*WASTE_LIST_LIMIT then
            self:UpdateWaste("big")
        end
    elseif iMs >= 1 then
        tinsert(self.m_mWaste["small"], {key = sKey, timestamp = os.date("%c", get_time()), time = iMs})
        if #self.m_mWaste["small"] >= 2*WASTE_LIST_LIMIT then
            self:UpdateWaste("small")
        end
    end
end

function CMonitor:UpdateWaste(sKey)
    local l = self.m_mWaste[sKey]
    if not l or #l <= WASTE_LIST_LIMIT then
        return
    end
    local nl = {}
    for i = #l - WASTE_LIST_LIMIT + 1, #l do
        tinsert(nl, l[i])
    end
    self.m_mWaste[sKey] = nl
end

function CMonitor:WriteMonitorInfo()
    local iTime = get_time()

    if self.m_oMonitorFile then
        self.m_oMonitorFile:close()
        self.m_oMonitorFile = nil
    end

    local lMonitorByCount = {}
    local lMonitorByTime = {}
    local lMonitorWaste = {
        small = {},
        big = {},
        huge = {},
    }

    for k, v in pairs(self.m_mRecord) do
        tinsert(lMonitorByTime, {key = k, count = v.count, per_time = v.total_ms/v.count})
        tinsert(lMonitorByCount, {key = k, count = v.count, per_time = v.total_ms/v.count})
    end
    tsort(lMonitorByTime, function (a, b)
        return a.per_time > b.per_time
    end)
    tsort(lMonitorByCount, function (a, b)
        return a.count > b.count
    end)

    self:UpdateWaste("small")
    lMonitorWaste["small"] = self.m_mWaste["small"]
    self:UpdateWaste("big")
    lMonitorWaste["big"] = self.m_mWaste["big"]
    self:UpdateWaste("huge")
    lMonitorWaste["huge"] = self.m_mWaste["huge"]

    local f = io.open("log/lua_cpu_monitor.log", "wb")
    self.m_oMonitorFile = f
    f:write(string.format("start_time: %s  dump_time: %s\n", os.date("%c", self.m_iStartTime), os.date("%c", iTime)))

    local s = require("base.extend").Table.pretty_serialize(lMonitorByTime)
    f:write("PER TIME SORT SHOW:\n")
    f:write(string.format("%s\n", s))
    s = require("base.extend").Table.pretty_serialize(lMonitorByCount)
    f:write("COUNT SORT SHOW:\n")
    f:write(string.format("%s\n", s))
    s = require("base.extend").Table.pretty_serialize(lMonitorWaste)
    f:write("WASTE SHOW:\n")
    f:write(string.format("%s\n", s))   

    self.m_oMonitorFile:close()
    self.m_oMonitorFile = nil
end

function CMonitor:OnTime()
    self:WriteMonitorInfo()

    self.m_iStartTime = get_time()
    self.m_mRecord = {}
    self.m_mWaste = {
        small = {},
        big = {},
        huge = {},
    }
end

function CMonitor:Clear()
    self.m_mRecord = {}
    self.m_mWaste = {
        small = {},
        big = {},
        huge = {},
    }
end
