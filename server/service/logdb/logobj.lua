local global = require "global"
local skynet = require "skynet"
local bson = require "bson"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local logdefines = import(service_path("logdefines"))

function NewLogObj(...)
    local o = CLogObj:New(...)
    return o
end

CLogObj = {}
CLogObj.__index = CLogObj
inherit(CLogObj, logic_base_cls())

function CLogObj:New()
    local o = super(CLogObj).New(self)
    o.m_oClient = nil
    o.m_sBaseDbName = nil
    o.m_mLogDb = {}
    o.m_oUnmoveLogDb = nil
    o.m_oChatLogDb = nil
    return o
end

function CLogObj:Init(mInit)
    self.m_sBaseDbName = mInit.basename
    self.m_oClient = mongoop.NewMongoClient({
        host = mInit.host, 
        port = mInit.port,
        username = mInit.username,
        password = mInit.password,
    })
end

function CLogObj:InitUnmoveLogDb(mInit)
    local oClient = mongoop.NewMongoClient({
        host = mInit.host,
        port = mInit.port,
        username = mInit.username,
        password = mInit.password,
    })
    self.m_oUnmoveLogDb = mongoop.NewMongoObj()
    self.m_oUnmoveLogDb:Init(oClient, mInit.basename)
    self.m_oUnmoveLogDb:CreateIndex("analy", {platform = 1}, {name = "analy_platform_index"})
    self.m_oUnmoveLogDb:CreateIndex("analy", {channel = 1}, {name = "analy_channel_index"})
end

function CLogObj:InitChatLogDb(mInit)
    local oClient = mongoop.NewMongoClient({
        host = mInit.host,
        port = mInit.port,
        username = mInit.username,
        password = mInit.password,
    })
    self.m_oChatLogDb = mongoop.NewMongoObj()
    self.m_oChatLogDb:Init(oClient, mInit.basename)
    self.m_oChatLogDb:CreateIndex("chat", {pid = 1}, {name = "chat_pid",})
    self.m_oChatLogDb:CreateIndex("chat", {channel = 1}, {name = "chat_channel",})
    self.m_oChatLogDb:CreateIndex("chat", {_time = 1}, {name = "chat_time",expireAfterSeconds=14*24*3600})
    self.m_oChatLogDb:CreateIndex("chat", {svr = 1}, {name = "chat_svr",})
end

function CLogObj:LogMonth(iTime)
    return os.date("%Y%m", iTime)
end

function CLogObj:InitLogDb(sTime)
    local o = mongoop.NewMongoObj()
    o:Init(self.m_oClient, self.m_sBaseDbName..sTime)

    skynet.fork(function ()
        self:CreateLogDbIndex(sTime)
    end)

    self.m_mLogDb[sTime] = o
end

function CLogObj:CreateLogDbIndex(sTime)
    local o = self.m_mLogDb[sTime]
    if o then
        local mLogIndex = logdefines.GetLogIndex()
        for sTableName,mIndex in pairs(mLogIndex) do
            for _,sIndex in pairs(mIndex) do
                local name = string.format("%s_%s_index",sTableName,sIndex)
                o:CreateIndex(sTableName, { [sIndex] = 1}, { name = name })
            end
        end
    end
end

function CLogObj:PushLog(sType, m)
    local iTime = get_time()
    local sTime = self:LogMonth(iTime)
    m._time = bson.date(iTime)

    if not self.m_mLogDb[sTime] then
        self:InitLogDb(sTime)
    end
    self.m_mLogDb[sTime]:InsertLowPriority(sType, m)
end

function CLogObj:PushUnmoveLog(sType, m)
    local iTime = get_time()
    m._time = bson.date(iTime)
    self.m_oUnmoveLogDb:InsertLowPriority(sType, m)
end

function CLogObj:PushChatLog(sType,m)
    local iTime = get_time()
    m._time = bson.date(iTime)
    self.m_oChatLogDb:InsertLowPriority(sType, m)
end

function CLogObj:FindLog(sType,mSearch,mBackInfo,exact_time)
    local iTime = exact_time
    local sTime = self:LogMonth(iTime)
    if not self.m_mLogDb[sTime] then
        self:InitLogDb(sTime)
    end
    return self.m_mLogDb[sTime]:Find(sType,mSearch,mBackInfo)
end

function CLogObj:FindUnmoveLog(sType,mSearch,mBackInfo)
    return self.m_oUnmoveLogDb:Find(sType,mSearch,mBackInfo)
end


function CLogObj:FindUnmoveLog(sType,mSearch,mBackInfo)
    return self.m_oUnmoveLogDb:Find(sType,mSearch,mBackInfo)
end