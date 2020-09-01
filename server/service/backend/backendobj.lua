--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local record = require "public.record"
local bson = require "bson"

local serverinfo = import(lualib_path("public.serverinfo"))

function NewBackendObj(...)
    local o = CBackendObj:New(...)
    return o
end

CBackendObj = {}
CBackendObj.__index = CBackendObj

function CBackendObj:New()
    local o = setmetatable({}, self)
    o.m_mServers = {}
    o.m_oBackendDb = nil
    return o
end

function CBackendObj:Init()
end

function CBackendObj:Release()
    release(self)
end

function CBackendObj:InitBackendDb(mInit)
    local oClient = mongoop.NewMongoClient({
        host = mInit.host,
        port = mInit.port,
        username = mInit.username,
        password = mInit.password,
    })
    self.m_oBackendDb = mongoop.NewMongoObj()
    self.m_oBackendDb:Init(oClient, mInit.name)

    skynet.fork(function ()
        local o = self.m_oBackendDb
        local sTableName = "test"
        o:CreateIndex(sTableName, {_time = 1}, {name = "test_time_index"})
        sTableName = "player"
        o:CreateIndex(sTableName, {pid = 1}, {name = "player_pid_index"})
        o:CreateIndex(sTableName, {type = 1}, {name = "player_type_index"})
    end)
end

function CBackendObj:PushLog(sType, m)
    local iTime = get_time()
    m._time = bson.date(iTime)

    self.m_oBackendDb:InsertLowPriority(sType, m)
end

function CBackendObj:GenID(sType)
    local sTableName = "idcounter"
    local m = self.m_oBackendDb:FindOne(sTableName, {type = sType}, {id = true})
    local iId = 1
    if m and m.id then
        iId = m.id + 1
    end
    self.m_oBackendDb:Update(sTableName, {type = sType}, {["$set"]={id = iId}}, true)
    return iId
end

function CBackendObj:GetID(sType)
    local m = self.m_oBackendDb:FindOne("idcounter", {type = sType}, {id = true})
    local iId = 0
    if m and m.id then
        iId = m.id
    end
    return iId
end

function CBackendObj:AfterAddServer()
    skynet.fork(function ()
        self:Schedule()
    end)
end

function CBackendObj:Schedule()
    local f
    f = function ()
        local tbl = get_hourtime({factor=1,hour=1})
        local iSecs = tbl.time - get_time()
        if iSecs <= 0 then
            iSecs = 3600
        end
        skynet.timeout(iSecs * 100, f)
        self:NewHour()
    end
    local tbl = get_hourtime({factor=1,hour=1})
    local iSecs = tbl.time - get_time()
    if iSecs <= 0 then
        f()
    else
        skynet.timeout(iSecs * 100, f)
    end
end

function CBackendObj:NewHour()
    local tbl = get_hourtime({hour=0})
    local date = tbl.date
    local iDay = date.day
    local iHour = date.hour

    local oPlayerStatObj = global.oPlayerStatObj
    oPlayerStatObj:NewHour(iDay,iHour)
end

function CBackendObj:AddNewServer(sServerKey, mGameCfg, mGameLogCfg, mGameUmCfg, mChatLogCfg)
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

function CBackendObj:GetServerObj(sServerKey)
    return self.m_mServers[sServerKey]
end

function CBackendObj:GetAllServers()
    return table_value_list(self.m_mServers)
end

function CBackendObj:Test(mArgs)
    local iYear, iMonth, sServerKey = mArgs.year, mArgs.month, mArgs.server
    local oServer = self.m_mServers[sServerKey]
    if not oServer then
        return {errcode = 1}
    end

    local oGameDb = oServer.m_oGameDb:GetDb()
    if not oGameDb then
        return {errcode = 1}
    end

    local oGameLogDb = oServer.m_oGameLogDb:GetDb(iYear, iMonth)
    if not oGameLogDb then
        return {errcode = 1}
    end

    local m1 = oGameDb:FindOne("player", {pid = 1}, {pid = true, account = true, base_info = true, deleted = true})
    local m2 = oGameLogDb:FindOne("test")

    return {errcode = 0, data = {player = m1, log = m2}}
end

function CBackendObj:GetServerList()
    return self.m_mServers
end


function CBackendObj:GetServer(sServerKey)
    return self.m_mServers[sServerKey]
end

function CBackendObj:GetServersByIds(lServerIds)
    if not lServerIds then
        return self.m_mServers
    end
    local mServer = {}
    for _, id in pairs(lServerIds) do
        local oServer = self:GetServer(id)
        if oServer then
            mServer[id] = oServer
        end
    end
    return mServer
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

function CServerObj:GetHttpHost()
    return serverinfo.get_gs_host(self.m_sServer)
end

function CServerObj:Release()
    release(self)
end

function CServerObj:ServerID()
    return self.m_sServer
end

function CServerObj:FindGameDbPlayers(mSearch)
    local oGameDb = self.m_oGameDb:GetDb()
    if not oGameDb then return end
    local mData = oGameDb:Find("player",mSearch,{pid=true, name=true, account=true, base_info=true})
    mongoop.ChangeAfterLoad(mData)
    return mData
end

function CServerObj:PackPlayerInfo(iRowNum, mData)
    local mInfo = {}
    mInfo["pid"] = mData["pid"]
    mInfo["account"] = mData["account"]
    mInfo["nickName"] = mData["name"]
    mInfo["serverId"] = self.m_sServer
    mInfo["rowNum"] = iRowNum
    return mInfo
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