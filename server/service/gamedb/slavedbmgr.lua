--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local record = require "public.record"
local bson = require "bson"

local serverinfo = import(lualib_path("public.serverinfo"))

function NewSlaveDbMgr(...)
    local o = CSlaveDbMgr:New(...)
    return o
end

CSlaveDbMgr = {}
CSlaveDbMgr.__index = CSlaveDbMgr

function CSlaveDbMgr:New()
    local o = setmetatable({}, self)
    o.m_mServers = {}
    return o
end

function CSlaveDbMgr:Init()
end

function CSlaveDbMgr:AddNewServer(sServerKey, mGameCfg, mGameLogCfg, mGameUmCfg, mChatLogCfg)
    if not self.m_mServers[sServerKey] then
        skynet.fork(function ()
            if not self.m_mServers[sServerKey] then
                local oClient1 = mongoop.NewMongoClient({
                    host = mGameCfg.host,
                    port = mGameCfg.port,
                    username = mGameCfg.username,
                    password = mGameCfg.password,
                })
                local oClient2 = mongoop.NewMongoClient({
                    host = mGameLogCfg.host,
                    port = mGameLogCfg.port,
                    username = mGameLogCfg.username,
                    password = mGameLogCfg.password,
                })
                local oClient3 = mongoop.NewMongoClient({
                    host = mGameUmCfg.host,
                    port = mGameUmCfg.port,
                    username = mGameUmCfg.username,
                    password = mGameUmCfg.password,
                })
                local oClient4 = mongoop.NewMongoClient({
                    host = mChatLogCfg.host,
                    port = mChatLogCfg.port,
                    username = mChatLogCfg.username,
                    password = mChatLogCfg.password,
                })
                self.m_mServers[sServerKey] = CServerObj:New()
                self.m_mServers[sServerKey]:Init(sServerKey, oClient1, oClient2, oClient3, oClient4)
            end
        end)
    end
end

function CSlaveDbMgr:GetServerList()
    return self.m_mServers
end

function CSlaveDbMgr:GetServer(sServerKey)
    return self.m_mServers[sServerKey]
end

function CSlaveDbMgr:QueryResult(sServerKey,sDbName,sTableName,mSearch,mBack)
    mSearch = mSearch or {}
    local mData = {}
    local oServer = self:GetServer(sServerKey)
    if not oServer then
        return mData
    end
    local oDbObj = oServer:GetDBObj(sDbName)
    local mQuery = oDbObj:Find(sTableName, mSearch,mBack)
    while mQuery:hasNext() do
        local m = mQuery:next()
        table.insert(mData,m)
    end
    return mData
end

CServerObj = {}
CServerObj.__index = CServerObj

function CServerObj:New()
    local o = setmetatable({}, self)
    o.m_sServer = ""
    o.m_oGameDb = nil
    o.m_oGameLogDb = nil
    return o
end

function CServerObj:Init(sServerKey, oGameClient, oGameLogClient, oGameUmClient, oChatLogClient)
    self.m_sServer = sServerKey
    self.m_oGameDb = CGameDbObj:New(oGameClient)
    self.m_oGameLogDb = CGameLogDbObj:New(oGameLogClient)
    self.m_oGameUmDb = CGameUmObj:New(oGameUmClient)
    self.m_oChatLogDb = CChatLogDbObj:New(oChatLogClient)
end

function CServerObj:GetDBObj(sDbName)
    if sDbName == "game" then
        return self.m_oGameDb:GetDb()
    elseif sDbName == "unmovelog" then
        return self.m_oGameUmDb:GetDb()
    elseif sDbName == "chatlog" then
        return self.m_oChatLogDb:GetDb()
    else
        local sLogName,num = string.match(sDbName,sDbName)
        local iYear,iMonth = num/100,num%100
        return self.m_oGameLogDb:GetDb(iYear,iMonth)
    end
end

function CServerObj:GetHttpHost()
    return serverinfo.get_gs_host(self.m_sServer)
end

function CServerObj:Release()
    release(self)
end

function CServerObj:ServerID()
    return self.m_sServer
end

function CServerObj:GetServerTag()
    return get_server_tag(self.m_sServer)
end


CGameDbObj = {}
CGameDbObj.__index = CGameDbObj

function CGameDbObj:New(oClient)
    local o = setmetatable({}, self)
    o.m_oClient = oClient
    o.m_oDb = nil
    return o
end

function CGameDbObj:Init()
end

function CGameDbObj:Release()
    release(self)
end

function CGameDbObj:InitDb()
    if not self.m_oDb then
        local o = mongoop.NewMongoObj()
        o:Init(self.m_oClient, "game")
        self.m_oDb = o
    end
end

function CGameDbObj:GetDb()
    if not self.m_oDb then
        self:InitDb()
    end
    return self.m_oDb
end


CGameLogDbObj = {}
CGameLogDbObj.__index = CGameLogDbObj

function CGameLogDbObj:New(oClient)
    local o = setmetatable({}, self)
    o.m_oClient = oClient
    o.m_mDbs = {}
    return o
end

function CGameLogDbObj:Init()
end

function CGameLogDbObj:Release()
    release(self)
end

function CGameLogDbObj:TimeString(iYear, iMonth)
    return string.format("%04d%02d", iYear, iMonth)
end

function CGameLogDbObj:DiffMonth(iYear, iMonth)
    iYear = math.max(2000, math.min(iYear, 3000))
    iMonth = math.max(1, math.min(iMonth, 12))

    local m = os.date("*t", get_time())
    local iNowYear = m.year
    local iNowMonth = m.month
    if iYear > iNowYear then
        return -1
    elseif iYear == iNowYear then
        if iMonth > iNowMonth then
            return -1
        end
    end

    local iDiff = (iNowYear - iYear)*12 + iNowMonth - iMonth
    return iDiff
end

function CGameLogDbObj:InitDb(sTime)
    if not self.m_mDbs[sTime] then
        local o = mongoop.NewMongoObj()
        o:Init(self.m_oClient, string.format("gamelog%s", sTime))
        self.m_mDbs[sTime] = o
    end
end

function CGameLogDbObj:GetDb(iYear, iMonth)
    local iDiffMonth = self:DiffMonth(iYear, iMonth)
    if iDiffMonth < 0 or iDiffMonth > 1 then
        return
    end
    local sTime = self:TimeString(iYear, iMonth)

    if not self.m_mDbs[sTime] then
        self:InitDb(sTime)
    end
    return self.m_mDbs[sTime]
end

CGameUmObj = {}
CGameUmObj.__index = CGameUmObj

function CGameUmObj:New(oClient)
    local o = setmetatable({}, self)
    o.m_oClient = oClient
    o.m_oDb = nil
    return o
end

function CGameUmObj:Init()
end

function CGameUmObj:Release()
    release(self)
end

function CGameUmObj:InitDb()
    if not self.m_oDb then
        local o = mongoop.NewMongoObj()
        o:Init(self.m_oClient, "unmovelog")
        self.m_oDb = o
    end
end

function CGameUmObj:GetDb()
    if not self.m_oDb then
        self:InitDb()
    end
    return self.m_oDb
end

CChatLogDbObj = {}
CChatLogDbObj.__index = CChatLogDbObj

function CChatLogDbObj:New(oClient)
    local o = setmetatable({}, self)
    o.m_oClient = oClient
    o.m_oDb = nil
    return o
end

function CChatLogDbObj:Init()
end

function CChatLogDbObj:Release()
    release(self)
end

function CChatLogDbObj:InitDb()
    if not self.m_oDb then
        local o = mongoop.NewMongoObj()
        o:Init(self.m_oClient, "chatlog")
        self.m_oDb = o
    end
end

function CChatLogDbObj:GetDb()
    if not self.m_oDb then
        self:InitDb()
    end
    return self.m_oDb
end