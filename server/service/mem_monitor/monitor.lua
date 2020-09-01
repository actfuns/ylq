--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local tconcat = table.concat
local tpack = table.pack
local tinsert = table.insert
local tsort = table.sort

function NewMonitor(...)
    local o = CMonitor:New(...)
    return o
end

CMonitor = {}
CMonitor.__index = CMonitor
inherit(CMonitor, logic_base_cls())

function CMonitor:New()
    local o = super(CMonitor).New(self)
    o.m_iStartTime = nil
    o.m_mRecord = {}
    o.m_oMonitorFile = nil
    return o
end

function CMonitor:Init()
end

function CMonitor:Record(iMemInc, sKey)
    if not self.m_iStartTime then
        return
    end

    local m = self.m_mRecord[sKey]
    if not m then
        self.m_mRecord[sKey] = {sKey, 1, iMemInc}
    else
        m[2] = m[2] + 1
        m[3] = m[3] + iMemInc
    end
end

function CMonitor:Dump()
    if not self.m_iStartTime then
        return
    end

    local iTime = get_time()

    if self.m_oMonitorFile then
        self.m_oMonitorFile:close()
        self.m_oMonitorFile = nil
    end

    local lMonitorByMem = {}
    local lMonitorByPerMem = {}

    for k, v in pairs(self.m_mRecord) do
        tinsert(lMonitorByMem, {key = v[1], count = v[2], total_mem = v[3], per_mem = v[3]/v[2]})
        tinsert(lMonitorByPerMem, {key = v[1], count = v[2], total_mem = v[3], per_mem = v[3]/v[2]})
    end
    tsort(lMonitorByMem, function (a, b)
        return a.total_mem > b.total_mem
    end)
    tsort(lMonitorByPerMem, function (a, b)
        return a.per_mem > b.per_mem
    end)

    local f = io.open("log/lua_mem_monitor.log", "wb")
    self.m_oMonitorFile = f
    f:write(string.format("start_time: %s  dump_time: %s\n", os.date("%c", self.m_iStartTime), os.date("%c", iTime)))

    local s = require("base.extend").Table.pretty_serialize(lMonitorByMem)
    f:write("TOTAL MEM SORT SHOW:\n")
    f:write(string.format("%s\n", s))
    s = require("base.extend").Table.pretty_serialize(lMonitorByPerMem)
    f:write("PER MEM SORT SHOW:\n")
    f:write(string.format("%s\n", s))

    self.m_oMonitorFile:close()
    self.m_oMonitorFile = nil
end

function CMonitor:Start()
    self.m_iStartTime = get_time()
    self.m_mRecord = {}
end

function CMonitor:Stop()
    self.m_iStartTime = nil
    self.m_mRecord = {}
end

function CMonitor:Clear()
    self.m_mRecord = {}
end
