local global = require "global"
local skynet = require "skynet"
local socket = require "socket"
local interactive = require "base.interactive"
local router = require "base.router"
local extype = require "base.extype"
local record = require "public.record"
local serverdefines = require "public.serverdefines"

local serverinfo = import(lualib_path("public.serverinfo"))

local socket_error = setmetatable({}, {__tostring = function() return "[Error: socket]" end })
local readsocket = function (fd, ...)
        local result = socket.read(fd, ...)
        if not result then
            error(socket_error)
        else
            return result
        end
end

function NewRouterClient(...)
    local o = CRouterClient:New(...)
    return o
end

CRouterClient = {}
CRouterClient.__index = CRouterClient
inherit(CRouterClient, logic_base_cls())

function CRouterClient:New(iPort)
    local o = super(CRouterClient).New(self)
    o.m_iFd = nil
    o.m_bIsConnecting = false
    o.m_iLastHeartBeatTime = get_time()
    o.m_lBigPacketCache = {}
    o.m_iPort = iPort
    return o
end

function CRouterClient:Init()
    self:ConnectRouter()
    skynet.fork(function ()
        while 1 do
            if not self.m_iFd or self.m_bIsConnecting then
                skynet.sleep(1*100)
            else
                local ok = pcall(self.RecvRouter, self)
                if not ok then
                    if self.m_iFd then
                        self:DisconnectRouter()
                    end
                    self:ConnectRouter()
                end
            end
        end
    end)

    skynet.fork(function ()
        while 1 do
            if self.m_iFd then
                local iCurrTime = get_time()
                if iCurrTime - self:GetLastHeartBeatTime() >= 2*60 then
                    self:DisconnectRouter()
                    self:ConnectRouter()
                end
            else
                if not self.m_bIsConnecting then
                    self:ConnectRouter()
                end
            end
            skynet.sleep(5*100)
        end
    end)

    skynet.fork(function ()
        while 1 do
            if self.m_iFd then
                self:SendP2R(router.PROTO_P2R.P2RHeartBeat, {
                    sk = get_server_tag(),
                })
            end
            skynet.sleep(4*100)
        end
    end)
end

function CRouterClient:ConnectRouter()
    if not self.m_iFd and not self.m_bIsConnecting then
        local sIP = serverinfo.get_router_host()
        local iPort = assert(self.m_iPort)
        self.m_bIsConnecting = true

        local iFd = socket.open(sIP, iPort)
        if self.m_bIsConnecting then
            self.m_iFd = iFd
            self.m_bIsConnecting = false
            self:SendP2R(router.PROTO_P2R.P2RHeartBeat, {
                sk = get_server_tag(),
            })
        else
            socket.shutdown(iFd)
            self.m_iFd = nil
        end
    end
end

function CRouterClient:DisconnectRouter()
    if self.m_bIsConnecting then
        self.m_bIsConnecting = false
    end
    if self.m_iFd then
        socket.shutdown(self.m_iFd)
        self.m_iFd = nil
    end
end

function CRouterClient:RecvRouter()
    local iFd = self.m_iFd
    if iFd then
        local s = socket.read(iFd, 2)
        local iLen = s:byte(1)*(2^8) + s:byte(2)
        s = socket.read(iFd, iLen)
        local iR2PCmd = s:byte(1)
        local sData = string.sub(s, 2)
        local mData
        if #sData > 0 then
            mData = skynet.unpack(sData)
        else
            mData = {}
        end
        safe_call(self.RouterCmd, self, iR2PCmd, mData)
    end
end

function CRouterClient:RouterCmd(iCmd, mArgs)
    if iCmd == router.PROTO_R2P.R2PRouter then
        self:ClrBigPacketCache()
        local mRecord = mArgs.record
        local mData = mArgs.data
        skynet.send(mRecord.des, "router", mRecord, mData)
    elseif iCmd == router.PROTO_R2P.R2PRouterBig then
        local iIndex = mArgs.index
        local iTotal = mArgs.total
        local sSubData = mArgs.data

        if iIndex == 1 then
            self:ClrBigPacketCache()
        end
        self:AddBigPacketCache(sSubData)
        local l = self:GetBigPacketCache()
        if #l ~= iIndex then
            self:ClrBigPacketCache()
            record.warning("RouterCmd bigpacket fail")
        else
            if iIndex == iTotal then
                self:ClrBigPacketCache()
                local sResult = table.concat(l, "")
                local mOrigin = skynet.unpack(sResult)
                local mRecord = mOrigin.record
                local mData = mOrigin.data
                skynet.send(mRecord.des, "router", mRecord, mData)
            end
        end
    elseif iCmd == router.PROTO_R2P.R2PHeartBeat then
        self.m_iLastHeartBeatTime = get_time()
    else
        record.warning(string.format("RouterCmd fail %d", iCmd))
    end
end

function CRouterClient:SendP2R(iCmd, mData)
    if self.m_iFd then
        if iCmd ~= router.PROTO_P2R.P2RRouter then
            local l = {
                string.char(iCmd%256),
                skynet.packstring(mData or {}),
            }
            local s = string.pack(">s2", table.concat(l, ""))
            socket.write(self.m_iFd, s)
        else
            local sData = skynet.packstring(mData or {})
            local iLimit = 30*1024
            local iWarn = 1024*1024
            local iDataLen = #sData
            if iDataLen > iLimit then
                local lSub = {}
                local mP2RRecord = mData.record
                local sDesServer = mP2RRecord.dessk
                local iStart = 1
                while iStart <= iDataLen do
                    local iNext = iStart + iLimit
                    local sSub = string.sub(sData, iStart, iNext - 1)
                    table.insert(lSub, sSub)
                    iStart = iNext
                end
                for k, v in ipairs(lSub) do
                    local l = {
                        string.char(router.PROTO_P2R.P2RRouterBig%256),
                        skynet.packstring({
                            sk = sDesServer,
                            total = #lSub,
                            index = k,
                            data = v,
                        }),
                    }
                    local s = string.pack(">s2", table.concat(l, ""))
                    socket.write(self.m_iFd, s)
                end
                if iDataLen > iWarn then
                    record.warning(string.format("SendP2R(%d Bytes) larger than %d Bytes, srcsk:%s dessk:%s module:%s cmd:%s type:%s session:%s",
                        iDataLen, iWarn, mP2RRecord.srcsk, mP2RRecord.dessk, mP2RRecord.module, mP2RRecord.cmd, mP2RRecord.type, mP2RRecord.session
                    ))
                end
            else
                local l = {
                    string.char(router.PROTO_P2R.P2RRouter%256),
                    sData,
                }
                local s = string.pack(">s2", table.concat(l, ""))
                socket.write(self.m_iFd, s)
            end
        end
    else
        --record.warning(string.format("SendP2R fail %d", iCmd))
    end
end

function CRouterClient:SendP2P(mRecord, mData)
    if self.m_iFd then
        self:SendP2R(router.PROTO_P2R.P2RRouter, {
            record = mRecord,
            data = mData,
        })
    else
        --record.warning(string.format("SendP2P fail %s %s", mRecord.module, mRecord.cmd))
    end
end

function CRouterClient:GetLastHeartBeatTime()
    return self.m_iLastHeartBeatTime
end

function CRouterClient:AddBigPacketCache(sData)
    table.insert(self.m_lBigPacketCache, sData)
end

function CRouterClient:GetBigPacketCache()
    return self.m_lBigPacketCache
end

function CRouterClient:ClrBigPacketCache()
    if self:HasBigPacketCache() then
        self.m_lBigPacketCache = {}
    end
end

function CRouterClient:HasBigPacketCache()
    local l = self.m_lBigPacketCache
    if #l > 0 then
        return true
    else
        return false
    end
end
