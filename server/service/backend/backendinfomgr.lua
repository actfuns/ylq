--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local record = require "public.record"
local cjson = require "cjson"
local serverinfo = import(lualib_path("public.serverinfo"))
local serverdesc = import(lualib_path("public.serverdesc"))


function NewBackendInfoMgr(...)
    local o = CBackendInfoMgr:New(...)
    return o
end

local sServerTable = "gameserver"
local sChannelTable = "channel"
local sGroupTable = "servergroup"

CBackendInfoMgr = {}
CBackendInfoMgr.__index = CBackendInfoMgr

function CBackendInfoMgr:New()
    local o = setmetatable({}, self)
    o:Init()
    return o
end

function CBackendInfoMgr:Init()
end

function CBackendInfoMgr:GetClientServerList(mArgs)
    local iChannel = mArgs.channel
    local iPlatform = mArgs.platform
    local iVer = mArgs.version or 0

    local mRet = {}
    mRet["ports"] = {7011,7012,27011,27012,27013}
    local mServerList = {}
    for _, mServer in pairs(self:GetServerList()) do
        local sServerKey = mServer["id"]
        if not serverinfo.is_matched_platform(iPlatform, sServerKey) then
            goto continue
        end
        if not serverinfo.is_opened_channel(iChannel, sServerKey) then
            goto continue
        end
        local mData = {
            id = sServerKey,
            ip = mServer["ip"],
            name = mServer["name"],
            new = mServer["isNewServer"] or 0,
            group = mServer["serverIndex"] or 1,
        }
        table.insert(mServerList,mData)
        ::continue::
    end
    mRet["servers"] = mServerList
    mRet["groups"] = self:GetGroupList()
    mRet["RecommendServerList"] = {"1"}
    --local oNoticeMgr = global.oNoticeMgr
    --mRet = table_combine(mRet, oNoticeMgr:GetClientNotice(iVer))
    return mRet
end

function CBackendInfoMgr:GetServerList()
    local oBackendObj = global.oBackendObj
    local mData = oBackendObj.m_oBackendDb:Find(sServerTable, {})
    local lRet = {}
    while mData:hasNext() do
        local m = mData:next()
        table.insert(lRet, m)
    end
    return lRet
end

function CBackendInfoMgr:GetServerInfoList()
    local oBackendObj = global.oBackendObj
    local mData = oBackendObj.m_oBackendDb:Find(sServerTable, {})
    local lRet = {}
    while mData:hasNext() do
        local m = mData:next()
        if m.id and type(m.id) == "string" then
            m.id = tonumber(string.match(m.id, "%w+_%a+(%d*)"))
        end
        table.insert(lRet, m)
    end
    return lRet
end

function CBackendInfoMgr:GetGroupList()
    local oBackendObj = global.oBackendObj
    local mData = oBackendObj.m_oBackendDb:Find(sGroupTable, {})
    local lRet = {}
    while mData:hasNext() do
        local m = mData:next()
        table.insert(lRet, {id = m["id"],name=m["name"]})
    end
    return lRet
end

function CBackendInfoMgr:SaveOrUpdateServer(mArgs)
    local oBackendObj = global.oBackendObj
    local bAdd = mArgs["bAdd"]
    local mData = mArgs["data"]
    if bAdd then
        oBackendObj.m_oBackendDb:InsertLowPriority(sServerTable, mData)
    else
        local id = mData["id"]
        oBackendObj.m_oBackendDb:Update(sServerTable, {id = id}, {["$set"]=mData})
    end
end

function CBackendInfoMgr:DeleteServer(ids)
    local oBackendObj = global.oBackendObj
    oBackendObj.m_oBackendDb:Delete(sServerTable, {id={["$in"]=ids}})
end

function CBackendInfoMgr:GetChannelList()
    local oBackendObj = global.oBackendObj
    local mData = oBackendObj.m_oBackendDb:Find(sChannelTable, {})
    local lRet = {}
    while mData:hasNext() do
        local m = mData:next()
        table.insert(lRet, m)
    end
    return lRet
end

function CBackendInfoMgr:SaveOrUpdateChannel(mArgs)
    local oBackendObj = global.oBackendObj
    local bAdd = mArgs["bAdd"]
    local mData = mArgs["data"]
    if bAdd then
        oBackendObj.m_oBackendDb:InsertLowPriority(sChannelTable, mData)
    else
        local id = mData["id"]
        oBackendObj.m_oBackendDb:Update(sChannelTable, {id = id}, {["$set"]=mData})
    end
end

function CBackendInfoMgr:DeleteChannel(ids)
    local oBackendObj = global.oBackendObj
    oBackendObj.m_oBackendDb:Delete(sChannelTable, {id={["$in"]=ids}})
end



function CBackendInfoMgr:GetResourceInfo(sType)
    return self:GetBaseResourceInfo(sType)
end

function CBackendInfoMgr:GetBaseResourceInfo(sType)
    local mTable = {
        item = {{"daobiao", "item"}, {"id", "name"}},
    }
    local res = require "base.res"
    local mResource = mTable[sType]
    if not mResource then
        record.warning("gmtools get daobiao res error type: %s", sType)
        return {} 
    end
    local mRet = {}
    local mUrl, mKey = mResource[1], mResource[2]
    local mData = table_get_depth(res, mUrl) 
    for _, mInfo in pairs(mData) do
        table.insert(mRet, {id = mInfo[mKey[1]], name = mInfo[mKey[2]]})
    end
    return mRet
end



