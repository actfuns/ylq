--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"
local extend = require "base.extend"
local bson = require "bson"
local res = require "base.res"

local bkdefines = import(service_path("bkdefines"))
local gamedefines = import(lualib_path("public.gamedefines"))

function PreProcess(mArgs)
    mArgs.platformIds = bkdefines.GetPlatformList(mArgs.platformIds)
    mArgs.channelIds = bkdefines.GetChannelList(mArgs.channelIds)
    if mArgs.platformIds then
        mArgs.platformIds = {["$in"]=mArgs.platformIds}
    end
    if mArgs.channelIds then
        mArgs.channelIds = {["$in"]=mArgs.channelIds}
    end
end

function PostQueryData(mArgs)
    PreProcess(mArgs)
    local oQueryObj = global.oQueryObj
    local sType = mArgs.sType
    local mData = {}
    if sType == "searchplayer" then
        mData = oQueryObj:SearchPlayerList(mArgs)
    elseif sType == "graderank" then
        mData = oQueryObj:GradeRank(mArgs)
    elseif sType == "powerrank" then
        mData = oQueryObj:PowerRank(mArgs)
    elseif sType == "querylogtype" then
        mData = oQueryObj:QueryLogType(mArgs)
    elseif sType == "querysubtype" then
        mData = oQueryObj:QuerySubLogType(mArgs)
    elseif sType == "querylog" then
        mData = oQueryObj:QueryLog(mArgs)
    end
    return {errcode=0,data=mData}
end

function PullData(mArgs)
    local sServerKey = mArgs.serverkey
    local sDbname = mArgs.dbname
    local sTablename = mArgs.tablename
    local oQueryObj = global.oQueryObj
    return oQueryObj:PullData(sServerKey,sDbname,sTablename)
end

function NewQueryObj(...)
    local o = QueryObj:New(...)
    return o
end

QueryObj = {}
QueryObj.__index = QueryObj

function QueryObj:New()
    local o = setmetatable({}, self)
    return o
end

function QueryObj:Init()
end

function QueryObj:GetServerGameDB(sServer)
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj.m_mServers[sServer]
    if not oServer then
        return
    end
    return oServer.m_oGameDb:GetDb()
end

function QueryObj:GetServerGameLogDB(sServer, iYear, iMonth)
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj.m_mServers[sServer]
    if not oServer then
        return
    end
    return oServer.m_oGameLogDb:GetDb(iYear, iMonth)
end

function QueryObj:SearchPlayerList(mArgs)
    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList() or mArgs.serverIds
    local pid = mArgs.playerID
    local playerName = mArgs.playerName
    local minGrade = mArgs.minGrade
    local maxGrade = mArgs.maxGrade
    local orgName = mArgs.orgName
    local startTimeCreate = bkdefines.AnalyTimeStamp2(mArgs.startTimeCreate)
    local endTimeCreate = bkdefines.AnalyTimeStamp2(mArgs.endTimeCreate)
    local startTimeRecentLogin = bkdefines.AnalyTimeStamp2(mArgs.startTimeRecentLogin)
    local endTimeRecentLogin = bkdefines.AnalyTimeStamp2(mArgs.endTimeRecentLogin)

    local mSearch = {}
    if pid and pid ~= 0 then
        mSearch["pid"] = pid
    end
    if playerName and playerName ~= "" then
        mSearch["name"] = {["$regex"]=playerName}
    end
    if orgName and orgName ~= "" then
        mSearch["base_info.orgname"] = {["$regex"]=orgName}
    end
    if minGrade ~= 0 and maxGrade ~= 0 then
        mSearch["base_info.grade"] = {["$gte"]=minGrade, ["$lte"]=maxGrade}
    elseif minGrade ~= 0 then
        mSearch["base_info.grade"] = {["$gte"]=minGrade}
    elseif maxGrade ~= 0 then
        mSearch["base_info.grade"] = {["$lte"] =maxGrade}
    end
    if startTimeCreate and endTimeCreate then
        mSearch["base_info.create_time"] = {["$gte"]=startTimeCreate, ["$lt"]=endTimeCreate}
    elseif startTimeCreate then
        mSearch["base_info.create_time"] = {["$gte"]=startTimeCreate}
    elseif endTimeCreate then
        mSearch["base_info.create_time"] = {["$lt"]=endTimeCreate}
    end
    if startTimeRecentLogin and endTimeRecentLogin then
        mSearch["active_info.login_time"] = {["$gte"]=startTimeRecentLogin, ["$lt"]=endTimeRecentLogin}
    elseif startTimeRecentLogin then
        mSearch["active_info.login_time"] = {["$gte"]=startTimeRecentLogin}
    elseif endTimeRecentLogin then
        mSearch["active_info.login_time"] = {["$lt"]=endTimeRecentLogin}
    end

    local mRet = {}
    local iLimit = 0
    for sServer,_ in pairs(serverkeys) do
        local oGameDb = self:GetServerGameDB(sServer)
        if oGameDb then
            if iLimit > 100 then
                break
            end
            local m = oGameDb:Find( "player",mSearch,{pid=true, name=true, account=true,
            base_info=true, active_info=true})
            while m:hasNext() do
                if iLimit > 100 then
                    break
                end
                iLimit = iLimit + 1
                local mData = m:next()
                local school = mData.base_info.school or 1
                local platform = (mData.base_info.platform == "" ) and "无" or mData.base_info.platform
                local channel = (mData.base_info.channel == "" ) and "无" or mData.base_info.channel
                local orgName = (mData.base_info.orgname == "" ) and "无" or mData.base_info.orgname
                local mUnit = {
                    platformName = platform,
                    regChannel = channel,
                    account = mData.account or "",
                    nickName = mData.name or string.format("玩家%d",mData.pid) or "",
                    pid = mData.pid or 0,
                    grade = mData.base_info.grade or 0,
                    factionName = res["daobiao"]["school"][school]["name"] or "",
                    orgName = orgName,
                    createAt = bkdefines.FormatTimeToSec(mData.base_info.create_time or 0),
                    recentLoginTime = bkdefines.FormatTimeToSec(mData.active_info.login_time or 0),
                }
                table.insert(mRet,mUnit)
            end
        end
    end

    return mRet
end

function QueryObj:GradeRank(mArgs)
    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList() or mArgs.serverIds
    local tResult = {}
    local tPlayer = {}
    for sServer,_ in pairs(serverkeys) do
        local oGameDb = self:GetServerGameDB(sServer)
        local pidlist = {}
        if oGameDb then
            local m = oGameDb:Find( "rank",{name="grade"},{rank_data=true})
            while m:hasNext() do
                local mData = m:next()
                local rank_data = mData.rank_data or {}
                local showdata = rank_data.show_data or {}
                for iPage,info in pairs(showdata) do
                    for iNo,data in pairs(info) do
                        local pid = data[3]
                        table.insert(pidlist,pid)
                        table.insert(tResult,{nickName = data[5],id =  pid,
                            grade = data[1],exp = data[2],faction = res["daobiao"]["school"][data[6]]["name"] or "",
                            serverName = bkdefines.GetServerName(sServer)
                        })
                    end
                end
            end
            local m2 = oGameDb:Find( "player",{pid={["$in"]=pidlist}},{pid=true,base_info=true,account=true})
            while m2:hasNext() do
                local mData = m2:next()
                local pid = mData.pid
                tPlayer[pid] = {platform=mData.base_info.platform,channel=mData.base_info.channel,account=mData.account}
            end
        end
    end
    table.sort(tResult,function (a,b)
        if a.grade ~= b.grade then
            return a.grade > b.grade
        else
            return a.exp > b.exp
        end
    end)
    for rank,mUnit in pairs(tResult) do
        local pid = mUnit.id or 0
        local mInfo = tPlayer[pid] or {}
        mUnit.platform = mInfo.platform or "无"
        mUnit.channel = mInfo.channel or "无"
        mUnit.account = mInfo.account or tostring(pid)
        mUnit.rank = rank
    end

    return tResult
end


function QueryObj:PowerRank(mArgs)
    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList() or mArgs.serverIds
    local tResult = {}
    local tPlayer = {}
    for sServer,_ in pairs(serverkeys) do
        local oGameDb = self:GetServerGameDB(sServer)
        local pidlist = {}
        if oGameDb then
            local m = oGameDb:Find( "rank",{name="warpower"},{rank_data=true})
            while m:hasNext() do
                local mData = m:next()
                local rank_data = mData.rank_data or {}
                local showdata = rank_data.show_data or {}
                for iPage,info in pairs(showdata) do
                    for iNo,data in pairs(info) do
                        local pid = data[2]
                        table.insert(pidlist,pid)
                        table.insert(tResult,{
                            nickName=data[4],id=pid, grade =data[7],
                            score=data[1],faction = res["daobiao"]["school"][data[5]]["name"] or "",
                            serverName = bkdefines.GetServerName(sServer)
                        })
                    end
                end
            end
            local m2 = oGameDb:Find( "player",{pid={["$in"]=pidlist}},{pid=true,base_info=true,account=true})
            while m2:hasNext() do
                local mData = m2:next()
                local pid = mData.pid
                tPlayer[pid] = {platform=mData.base_info.platform,channel=mData.base_info.channel,account=mData.account}
            end
        end
    end
    table.sort(tResult,function (a,b)
        return a.score > b.score
    end)
    for rank,mUnit in pairs(tResult) do
        local pid = mUnit.id or 0
        local mInfo = tPlayer[pid] or {}
        mUnit.platform = mInfo.platform or "无"
        mUnit.channel = mInfo.channel or "无"
        mUnit.account = mInfo.account or tostring(pid)
        mUnit.rank = rank
    end
    return tResult
end

function QueryObj:GetLogParams(log,subtype)
    local mInfo = res["daobiao"]["log"][log][subtype]["log_format"]
    local idlist = {}
    local mBackInfo = {_time=true}
    local mNickName = {}
    for _,mUnit in pairs(mInfo) do
        local id = mUnit.id
        local desc = mUnit.desc
        table.insert(idlist,id)
        mBackInfo[id] = true
        mNickName[id] = desc
    end
    return idlist,mBackInfo,mNickName
end

function QueryObj:QueryLog(mArgs)
    local oBackendObj = global.oBackendObj
    local pid = ( mArgs.pid == "" and nil ) or mArgs.pid
    local serverkeys = mArgs.serverIds or table_key_list(oBackendObj:GetServerList())
    local iStartTime = bkdefines.AnalyTimeStamp2(mArgs.startTime)
    local iEndTime = bkdefines.AnalyTimeStamp2(mArgs.endTime)
    local ilimit = 1000 --bkdefines.limit
    local log = mArgs.logType
    local subtype = mArgs.subType
    if not log or not subtype then
        return {}
    end
    local idlist,mBackInfo,mNickName = self:GetLogParams(log,subtype)
    table.sort(idlist)
    local iBSStartTime = bson.date(iStartTime)
    local iBSEndTime = bson.date(iEndTime)
    local mSearch = {subtype=subtype,_time = {["$gte"]=iBSStartTime,["$lt"]=iBSEndTime}}
    if pid then
        mSearch["pid"] = tonumber(pid)
    end
    if log == "mail" and pid then
        mSearch["pid"] = nil
        mSearch["receiver_id"] = tonumber(pid)
    end
    mSearch["subtype"] = subtype
    if mArgs.platformIds then
        mSearch["platform"] = mArgs.platformIds
    end
    if mArgs.channelIds then
        mSearch["channel"] = mArgs.channelIds
    end

    local tRet = {}
    for iTime=iStartTime,iEndTime,24*3600 do
        local year,month = bkdefines.GetDateInfo(iTime)
        for _,sServer in pairs(serverkeys) do
            local oGameLogDb = self:GetServerGameLogDB(sServer,year,month)
            if oGameLogDb then
                mSearch["_time"] = {["$gte"]=bson.date(iTime),["$lt"]=bson.date(iTime+24*3600)}
                local m = oGameLogDb:Find(log,mSearch,mBackInfo)
                m = m:sort({_time = 1}):limit(ilimit)
                while m:hasNext() do
                    local mData = m:next()
                    local _,time = bson.type(mData._time)
                    local sTmp = ""
                    for _,id in pairs(idlist) do
                        local name = mNickName[id]
                        local value = mData[id]
                        if type(value) == "table" then
                            value = ConvertTblToStr(value)
                        end
                        if sTmp == "" then
                            sTmp = string.format("%s: %s" ,name,tostring(value))
                        else
                            sTmp = string.format("%s  ,  %s: %s" ,sTmp,name,tostring(value))
                        end
                    end
                    table.insert(tRet,{date=bkdefines.FormatTimeToSec(time),slog=sTmp,time=time})
                    if #tRet >= ilimit then
                        break
                    end
                end
            end
            if #tRet >= ilimit then
                break
            end
        end
        if #tRet >= ilimit then
            break
        end
    end

    table.sort( tRet, function ( a , b )
        return a.time < b.time
    end)
    return tRet
end

function QueryObj:QuerySubLogType(mArgs)
    local logtype = mArgs["logtype"]
    local mInfo = res["daobiao"]["log"][logtype]
    local lRet, iCnt = {}, 0
    if mInfo then
        for sSubType, mData in pairs(mInfo) do
            table.insert(lRet, {value=sSubType, text=mData["desc"] or "未知类型", selected=(iCnt==0)})
            iCnt = iCnt + 1
        end
    end
    return lRet
end

function QueryObj:QueryLogType(mArgs)
    local lRet = {}
    for _, lLog in pairs(bkdefines.GAME_LOG_MAP) do
        table.insert(lRet, {value=lLog[1], text=lLog[2], selected=(lLog[1]=="player")})
    end
    return lRet
end

function QueryObj:PullData(sServerKey,sDbname,sTablename)
    local oDbObj
    local iNowTime = get_time()
    local sLogDbName = os.date("%Y%m", iNowTime)
    sLogDbName = "gamelog"..sLogDbName

    if sDbname == "game" then
        oDbObj = self:GetServerGameDB(sServerKey)
    elseif sDbname == sLogDbName then
        local iYear,iMonth = bkdefines.GetDateInfo(iNowTime)
        oDbObj = self:GetServerGameLogDB(sServerKey,iYear,iMonth)
    end
    if not oDbObj then
        return {errcode=1,errmsg="no such dbname"}
    end

    local mData = {}
    local m = oDbObj:Find(sTablename,{})
    while m:hasNext() do
        local mUnit = m:next()
        mUnit._id = nil
        if mUnit._time then
            local _,time = bson.type(mUnit._time)
            mUnit._time = bkdefines.FormatTimeToSec(time)
        end
        table.insert(mData,mUnit)
    end
    return {errcode=0,data=mData}
end