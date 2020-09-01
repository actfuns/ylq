--import module

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local extend = require "base.extend"
local record = require "public.record"

local tinsert = table.insert
local tremove = table.remove
local skypack = skynet.packstring

function NewProxy(...)
    local o = CProxy:New(...)
    return o
end

CProxy = {}
CProxy.__index = CProxy
inherit(CProxy, logic_base_cls())

function CProxy:New(sHost, sCb)
    local o = super(CProxy).New(self)
    o.m_sHostAddr = sHost
    o.m_sHostCb = sCb
    o.m_mFrame = {}

    o.m_mPacket = {}
    o.m_mFlood = {}
    o.m_iLastSecond = get_time()

    o.m_mBadBoy = {}

    o.m_lLog = {}
    return o
end

function CProxy:Init()
    local f1
    f1 = function ()
        self:DelTimeCb("DoFrame")
        self:AddTimeCb("DoFrame", 20, f1)
        self:DoFrame()
    end
    f1()

    local f2
    f2 = function ()
        self:DelTimeCb("CheckBad")
        self:AddTimeCb("CheckBad", 10*1000, f2)
        self:CheckBad()
    end
    f2()

    local f3
    f3 = function ()
        self:DelTimeCb("ClearBad")
        self:AddTimeCb("ClearBad", 180*1000, f3)
        self:ClearBad()
    end
    f3()

    local f4
    f4 = function ()
        self:DelTimeCb("WriteLog")
        self:AddTimeCb("WriteLog", 300*1000, f4)
        self:WriteLog()
    end
    f4()
end

function CProxy:DoAddRecv(iFd, iType, sData)
    local l = self.m_mFrame[iFd]
    if not l then
        l = {}
        self.m_mFrame[iFd] = l
    end

    self:RecordPacket(iFd)
    self:RecordFlood(iFd, #sData)
    self:NoteDebug(iFd, iType)
    if #l < 10 then
        tinsert(l, {iFd, iType, sData})
    end
end

function CProxy:RecordBadBoy(iFd)
    local i = self.m_mBadBoy[iFd]
    if not i then
        i = 0
        self.m_mBadBoy[iFd] = i
    end
    i = i + 1
    self.m_mBadBoy[iFd] = i
    if i >= 10 then
        self:AlertBadBoy(iFd)
    end
end

function CProxy:AlertBadBoy(iFd)
    local dm = self:GetDebug()
    local ym = dm[iFd]
    local sm
    if ym then
        sm = extend.Table.serialize(ym)
        dm[iFd] = nil
    end

    self:NotifyHost(skypack({
        cmd = "badboy",
        fd = iFd,
        debug = sm,
    }))
    self.m_mPacket[iFd] = nil
    self.m_mFlood[iFd] = nil
    self.m_mBadBoy[iFd] = nil
end

function CProxy:RecordPacket(iFd)
    local i = self.m_mPacket[iFd]
    if not i then
        i = 0
        self.m_mPacket[iFd] = i
    end
    i = i + 1
    self.m_mPacket[iFd] = i
end

function CProxy:RecordFlood(iFd, iDataLen)
    local i = self.m_mFlood[iFd]
    if not i then
        i = 0
        self.m_mFlood[iFd] = i
    end
    i = i + iDataLen
    self.m_mFlood[iFd] = i
end

function CProxy:NotifyHost(sParam)
    local sHost = self.m_sHostAddr
    local sModule = self.m_sHostCb
    if sHost and sModule then
        local sCmd = [[
            local m = import(service_path("%s"))
            if m then
                m.Invoke(%s)
            end
        ]]
        sCmd = string.format(sCmd, sModule, "[["..sParam.."]]")
        interactive.Send(sHost, "default", "ExecuteString", {cmd = sCmd})
    end
end

function CProxy:DoFrame()
    local commit = {}
    while next(self.m_mFrame) do
        local m = self.m_mFrame
        local del = {}
        for k, l in pairs(m) do
            if #l > 0 then
                local o = tremove(l, 1)
                tinsert(commit, o)
                if #l <= 0 then
                    del[k] = true
                end
            else
                del[k] = true
            end
        end

        for k, _ in pairs(del) do
            m[k] = nil
        end
    end

    if #commit > 0 and self.m_sHostAddr then
        net.PushMerge(self.m_sHostAddr, commit)
    end
end

function CProxy:ClearBad()
    self.m_mBadBoy = {}
end

function CProxy:CheckBad()
    local iNowTime = get_time()
    local iDiffTime = iNowTime - self.m_iLastSecond
    if iDiffTime > 0 then
        local dm = self:GetDebug()

        local mNowBad = {}
        for k, v in pairs(self.m_mPacket) do
            local fRes = v/iDiffTime
            if fRes >= 4 then
                local bBad = false
                if fRes >= 8 then
                    mNowBad[k] = 1
                    bBad = true
                end
                local ym = dm[k]
                if ym then
                    self:PacketLog(k, fRes, ym, bBad)
                end
            end
        end

        for k, v in pairs(self.m_mFlood) do
            local fRes = v/iDiffTime
            if fRes >= 512 then
                mNowBad[k] = 1
                local ym = dm[k]
                if ym then
                    self:FloodLog(k, fRes, ym)
                end
            end
        end

        for k, v in pairs(mNowBad) do
            self:RecordBadBoy(k)
        end
    end

    self.m_iLastSecond = iNowTime
    self.m_mPacket = {}
    self.m_mFlood = {}
    self:CheckDebug()
end

function CProxy:GetDebug()
    if not self.m_mDebug then
        self.m_mDebug = {}
    end
    return self.m_mDebug
end

function CProxy:NoteDebug(iFd, iType)
    local m = self:GetDebug()
    if not m[iFd] then
        m[iFd] = {}
    end
    if not m[iFd][iType] then
        m[iFd][iType] = 0
    end
    m[iFd][iType] = m[iFd][iType] + 1
end

function CProxy:CheckDebug()
    local m = self:GetDebug()
    local new = {}
    for k, v in pairs(self.m_mBadBoy) do
        new[k] = m[k]
    end
    self.m_mDebug = nil
    if next(new) then
        self.m_mDebug = new
    end
end

function CProxy:PacketLog(k, fRes, ym, bBad)
    local sm = extend.Table.serialize(ym)
    local sLog = string.format("CProxy CheckBad PacketWarning fd:%s packet_per_sec:%s debug:%s", k, fRes, sm)
    if bBad then
        record.warning(sLog)
    end
    local sTime = get_time_format_str(get_time(), "%Y-%m-%d %H:%M:%S")
    local sLog = string.format("[%s] %s", sTime, sLog)
    table.insert(self.m_lLog, sLog)
end

function CProxy:FloodLog(k, fRes, ym)
    local sm = extend.Table.serialize(ym)
    local sLog = string.format("CProxy CheckBad FloodWarning fd:%s flood_per_sec:%s debug:%s", k, fRes, sm)
    record.warning(sLog)
end

function CProxy:WriteLog()
    if next(self.m_lLog) then
        local mLog = self.m_lLog
        self.m_lLog = {}
        local sContent = table.concat(mLog, "\n")
        write_file("log/lua_net_proxy.log", sContent)
    end
end
