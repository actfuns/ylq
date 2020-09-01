
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
    o.m_mRtMonitorMemory = {}
    o.m_oMemCurrentFile = nil
    return o
end

function CMonitor:Init()
end

function CMonitor:AddRtMonitor(mData)
    if not self.m_mRtMonitorMemory then
        self.m_mRtMonitorMemory = {}
    end
    local iCnt,iTime,iOldCnt,iOldTime
    local mKeyMemory
    for sKey,mKeyRecord in pairs(mData) do
        if not self.m_mRtMonitorMemory[sKey] then
            self.m_mRtMonitorMemory[sKey] = {}
        end
        mKeyMemory = self.m_mRtMonitorMemory[sKey]
        iCnt = mKeyRecord.count or 0
        iTime = mKeyRecord.time or 0
        iOldCnt = mKeyMemory.count or 0
        mKeyMemory.count = iOldCnt + iCnt
        iOldTime = mKeyMemory.time or 0
        mKeyMemory.time = iOldTime + iTime
        self.m_mRtMonitorMemory[sKey] = mKeyMemory
    end
end

function CMonitor:Start()
    local f1
    f1 = function ()
        self:DelTimeCb("WriteRtMonitor")
        self:AddTimeCb("WriteRtMonitor", 60*60*1000, f1)
        self:WriteRtMonitor()
    end
    f1()
end

function CMonitor:WriteRtMonitor()
    if self.m_oMemCurrentFile then
        self.m_oMemCurrentFile:close()
        self.m_oMemCurrentFile = nil
    end
    local Table = require("base.extend").Table
    local lRecord = {}
    local iCnt,iTime,fAvg
    for sKey,mKeyRecord in pairs(self.m_mRtMonitorMemory) do
        iCnt = mKeyRecord.count
        iTime = mKeyRecord.time
        fAvg = iTime / iCnt
        table.insert(lRecord,{key = sKey,total = iTime,count = iCnt,avg=fAvg})
    end
    table.sort(lRecord, function (a, b)
        return a["total"] > b["total"]
    end)
    local s1 = Table.pretty_serialize(lRecord)
    table.sort(lRecord,function (a,b)
        return a["count"] > b["count"]
    end)
    local s2 = Table.pretty_serialize(lRecord)
    table.sort( lRecord, function (a,b)
        return a["avg"] > b["avg"]
    end)
    local s3 = Table.pretty_serialize(lRecord)
    local f = io.open("log/lua_rt_monitor.log", "wb")
    self.m_oMemCurrentFile = f
    local sTime = os.date("%c", get_time())
    f:write(string.format("%s\n",sTime))
    f:write(string.format("totle:%s\n%s",sTime,s1))
    f:write(string.format("count:%s\n%s",sTime,s2))
    f:write(string.format("avg:%s\n%s",sTime,s3))
    self.m_oMemCurrentFile:close()
    self.m_oMemCurrentFile = nil
end

function CMonitor:Stop()
    self:DelTimeCb("WriteRtMonitor")
end

function CMonitor:Clear()
    self.m_mRtMonitorMemory = {}
end