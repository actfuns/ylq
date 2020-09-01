--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local record = require "public.record"
local cjson = require "cjson"
local bson = require "bson"
local httpuse = require "public.httpuse"

local bkdefines = import(service_path("bkdefines"))


function NewGmToolsObj(...)
    local o = CGmToolsObj:New(...)
    return o
end

CGmToolsObj = {}
CGmToolsObj.__index = CGmToolsObj

function CGmToolsObj:New()
    local o = setmetatable({}, self)
    o:Init()
    return o
end

function CGmToolsObj:Init()
end

function CGmToolsObj:PackPlayerInfo(sServer, iRowNum, mData)
    local mInfo = {}
    mInfo["pid"] = mData["pid"]
    mInfo["account"] = mData["account"]
    mInfo["nickName"] = mData["name"]
    mInfo["serverId"] = sServer
    mInfo["rowNum"] = iRowNum
    return mInfo
end

function CGmToolsObj:SearchPlayer(lServers, mSearch)
    local mRet = {}
    local iRowNum = 0
    for _, oServer in pairs(lServers) do
        local oGameDb = oServer.m_oGameDb:GetDb()
        local m = oGameDb:Find("player", mSearch, {pid=true, name=true, account=true, base_info=true})
        while m:hasNext() do
            iRowNum = iRowNum + 1
            local mData = m:next()
            mongoop.ChangeAfterLoad(mData)
            table.insert(mRet, self:PackPlayerInfo(oServer:ServerID(), iRowNum,mData))
        end
    end
    return mRet
end

function CGmToolsObj:PackSummonInfo(sServer, mData)
    if not mData then return end

    local lSummon = {}
    local mSummonInfo = {}
    if mData["summon_info"] then
        mSummonInfo = mData["summon_info"]["summondata"]
    end
    if #mSummonInfo <= 0 then return end

    local iPid = mData["pid"]
    local sName = mData["name"]
    for _, m in pairs(mSummonInfo) do
        local mSumm = {}
        mSumm["playerId"] = iPid
        mSumm["pname"] = sName
        local _, traceId = table.unpack(m.traceno)
        mSumm["id"] = traceId
        mSumm["name"] = m.name
        mSumm["sid"] = m.sid
        mSumm["grade"] = m.grade
        mSumm["serverid"] = sServer
        table.insert(lSummon, mSumm)
    end
    return lSummon
end

function CGmToolsObj:SearchOrg(oServer, mSearch)
    local oGameDb = oServer.m_oGameDb:GetDb()
    local m = oGameDb:FindOne("org", mSearch, {orgid = true, name = true, base_info = true})
    mongoop.ChangeAfterLoad(m)
    return self:PackOrgInfo(oServer:ServerID(), m)
end

function CGmToolsObj:PackOrgInfo(sServer, mData)
    if not mData or not mData.orgid then return end

    local mOrg = {}
    mOrg["orgId"] = mData.orgid
    mOrg["orgName"] = mData.name
    mOrg["aim"] = mData["base_info"]["aim"]
    mOrg["serverid"] = sServer
    return mOrg
end

function CGmToolsObj:SearchPlayerList2(mArgs)
    local lServerId = mArgs["serverids"]
    local iMinGrade = mArgs["mingrade"] or 0
    local iMaxGrade = mArgs["maxgrade"] or 0
    local sName = mArgs["name"]
    local sOrgName = mArgs["orgname"]
    local iCStartTime = mArgs["cstarttime"]
    local iCEndTime = mArgs["cendtime"]
    local iLStartTime = mArgs["lstarttime"]
    local iLEndTime = mArgs["lendtime"]

    local oBackendObj = global.oBackendObj
    local mServers = oBackendObj:GetServersByIds(lServerId)

    local mSearch = {}
    if sName and #sName > 0 then
        mSearch["name"] = {["$regex"]=sName}
    else
        -- TODO
    end

    if iMinGrade < iMaxGrade then
        mSearch["base_info.grade"] = {["$gte"]=iMinGrade, ["$lt"]=iMaxGrade}
    end
    if iCStartTime and iCEndTime and iCStartTime < iCEndTime then
       mSearch["create_time"] = {["$gte"]=iCStartTime, ["$lt"]=iCEndTime}
    end
    if iLStartTime and iLEndTime and iLStartTime < iLEndTime then
       mSearch["active_info.login_time"] = {["$gte"]=iLStartTime, ["$lt"]=iLEndTime}
    end

    local lRet = {}
    local iRowNum = 1
    for sServer, oServer in pairs(mServers) do
        local oGameDb = oServer.m_oGameDb:GetDb()
        local m = oGameDb:Find("player", mSearch, {pid=true, name=true, account=true,
            base_info=true, channel=true, create_time=true, active_info=true})
        while m:hasNext() do
            local mRet = m:next()
            mongoop.ChangeAfterLoad(mRet)
            table.insert(lRet, self:PackInfo2RoleList(iRowNum, sServer,mRet))
        end
    end
    return lRet
end

function CGmToolsObj:SearchPlayerList(mArgs)
    local lServerId = mArgs["serverids"]
    local iMinGrade = mArgs["mingrade"] or 0
    local iMaxGrade = mArgs["maxgrade"] or 0
    local iPid = mArgs["pid"]
    local sName = mArgs["name"]
    local sOrgName = mArgs["orgname"]
    local iCStartTime = mArgs["cstarttime"]
    local iCEndTime = mArgs["cendtime"]
    local iLStartTime = mArgs["lstarttime"]
    local iLEndTime = mArgs["lendtime"]

    local oBackendObj = global.oBackendObj
    local mServers = oBackendObj:GetServersByIds(lServerId)

    local mSearch = {}
    if iPid and iPid ~= 0 then
        mSearch["pid"] = iPid
    end

    if sName and #sName > 0 then
        mSearch["name"] = {["$regex"]=sName}
    else
        -- TODO
    end

    if iMinGrade < iMaxGrade then
        mSearch["base_info.grade"] = {["$gte"]=iMinGrade, ["$lt"]=iMaxGrade}
    end
    if iCStartTime and iCEndTime and iCStartTime < iCEndTime then
       mSearch["base_info.create_time"] = {["$gte"]=iCStartTime, ["$lt"]=iCEndTime}
    end
    if iLStartTime and iLEndTime and iLStartTime < iLEndTime then
       mSearch["active_info.login_time"] = {["$gte"]=iLStartTime, ["$lt"]=iLEndTime}
    end

    local mSearch2 = {}
    if iLStartTime and iLEndTime and iLStartTime < iLEndTime then
        mSearch2["_time"] = {["$gte"] = bson.date(iLStartTime),["$lt"] = bson.date(iLEndTime)}
        mSearch2["subtype"] = "logout"
    end

    local lRet = {}
    local iRowNum = 1

    for sServer, oServer in pairs(mServers) do
        local oGameDb = oServer.m_oGameDb:GetDb()
        local m = oGameDb:Find("player", mSearch, {pid=true, name=true, account=true,
            base_info=true, channel=true, create_time=true, active_info=true})

        local mPlayer, mPid = {}, {}
        while m:hasNext() do
            local mTmp = m:next()
            mongoop.ChangeAfterLoad(mTmp)
            table.insert(mPlayer, mTmp)
            table.insert(mPid, mTmp["pid"])
            if #mPlayer > 100 then
                break
            end
        end

        local mOnlineTime = {}
        if #mPid > 0 then
            mSearch2["pid"] = {["$in"]=mPid}
            local lDate = bkdefines.GetYearMonthList((iLStartTime or get_time()), (iLEndTime or get_time()))
            for _, mDate in pairs(lDate) do
                local iYear, iMonth = mDate[1], mDate[2]
                local oGameLogDb = oServer.m_oGameLogDb:GetDb(iYear, iMonth)
                if oGameLogDb then
                    local mLogout = oGameLogDb:Find("player", mSearch2)
                    while mLogout:hasNext() do
                        local mData = mLogout:next()
                        mongoop.ChangeAfterLoad(mData)
                        mOnlineTime[mData.pid] = (mOnlineTime[mData.pid] or 0) + (mData.duration or 0)
                    end
                end
            end
        end
        for _, mp in pairs(mPlayer) do
            mp["duration"] = mOnlineTime[mp.pid] or 0
            table.insert(lRet, self:PackInfo2RoleList(iRowNum, sServer, mp))
        end
        if #lRet > 100 then
            break
        end
    end
    return lRet
end

function CGmToolsObj:PackInfo2RoleList(iRowNum, sServer, m)
    -- TODO
    local res = require "base.res"
    local mDBSchool = res["daobiao"]["school"]
    local mNet = {}
    mNet["iRowNum"] = iRowNum
    mNet["gameServerId"] = sServer
    mNet["id"] = m["pid"]
    mNet["nickName"] = m["name"]
    mNet["account"] = m["account"]
    mNet["regChannel"] = m["channel"] or 0
    mNet["platform"] = 0
    mNet["grade"] = m["base_info"]["grade"]

    local iSchool = m["base_info"]["school"]
    mNet["factionId"] = iSchool
    mNet["factionName"] = mDBSchool[iSchool].name
    mNet["guildName"] = m["base_info"].orgname

    mNet["createAt"] = (m["base_info"]["create_time"] or 0) * 1000
    mNet["recentLoginTime"] = (m["active_info"]["login_time"] or 0) * 1000
    mNet["logoutTime"] = (m["active_info"]["disconnect_time"] or 0) * 1000
    mNet["duration"] = math.floor(m["duration"] or 0)
    return mNet
end

function CGmToolsObj:PostMsg2GameServer(lServer, mData)
    local iCnt = #lServer
    for _, oServer in pairs(lServer) do
        local sHost = oServer:GetHttpHost()
        httpuse.post(sHost, "/gmtools", cjson.encode(mData), function (body, header)
            iCnt = iCnt - 1
            local mRes = cjson.decode(body)
            if mRes.errcode then
                record.error("host:%s, errCode:%s, errMsg:%s", sHost, mRes.errcode, mRes.errmsg)
            end
        end)
    end
end

