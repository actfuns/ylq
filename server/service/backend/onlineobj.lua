 -- module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local record = require "public.record"
local mongo = require "mongo"
local bson = require "bson"
local extend = require "base.extend"
local bkdefines = import(service_path("bkdefines"))
local backendobj = import(service_path("backendobj"))

local pt = extend.Table.print

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

function realTimeOnlineData(mArgs)
    PreProcess(mArgs)
    local iCurTime = get_time()
    local mDate = os.date("*t", iCurTime)
    local iYear = mArgs.year or mDate.year
    local iMonth = mArgs.month or mDate.month

    local oBackendObj = global.oBackendObj
    local mData = {}
    for idx, oServer in pairs(oBackendObj.m_mServers) do
        if oServer then
            local oGameLogDb = oServer.m_oGameLogDb:GetDb(iYear, iMonth)
            if oGameLogDb then
                local m = oGameLogDb:Find("online",{
                    subtype = "online",_time = {["$gte"] = bson.date(iCurTime - 20*60)},platform=mArgs.platformIds,channel=mArgs.channelIds 
                    }, {online_cnt=true,_time=true})
                m = m:sort({_time = -1}):limit(1)
                local mOnline
                while m:hasNext() do
                    mOnline = m:next()
                    mongoop.ChangeAfterLoad(mOnline)
                end
                if mOnline then
                    local _,iLogTime = bson.type(mOnline["_time"])
                    table.insert(mData, {
                        ["name"] = bkdefines.GetServerName(idx) , ["logTime"] = bkdefines.FormatTimeToSec(iLogTime),
                        ["onlineCount"] = mOnline["online_cnt"] or 0}
                    )
                end
            end
        end
    end

    return {["errcode"] = 0, ["data"] = mData}
end

function intervalOnlineStat(mArgs)
    PreProcess(mArgs)
    local sCurDate = mArgs.curDate
    local sCompareDate = mArgs.compareDate
    local mData = {}

    local mCurTimesCounts = calonlineInterval(sCurDate,mArgs)
    local mCompareTimesCounts = calonlineInterval(sCompareDate,mArgs)

    table.insert(mData, {["type"] = sCurDate, ["timeCounts"] = mCurTimesCounts})
    table.insert(mData, {["type"] = sCompareDate, ["timeCounts"] = mCompareTimesCounts})

    return  {errcode = 0, data = mData}
end

function onlineHistory(mArgs)
    PreProcess(mArgs)
    local startTime = bkdefines.AnalyTimeStamp(mArgs.startTime)
    local endTime = bkdefines.AnalyTimeStamp(mArgs.endTime) + 24*3600

    local iFindStart = bson.date(startTime+ 6*3600)
    local iFindEnd = bson.date(endTime+ 6*3600)
    local oBackendObj = global.oBackendObj
    local serverkeys = table_key_list(oBackendObj:GetServerList())

    local mData = get_daytime({day=0})
    local iTodayStart = mData.time
    local iYear = mData.date.year
    local iMonth = mData.date.month
    local iFindLogStart = bson.date(math.max(iTodayStart,startTime))
    local iFindLogEnd =bson.date(endTime)

    local mResult = {}
    for _,key in pairs(serverkeys) do
        local oServer = oBackendObj:GetServerObj(key)
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        if oGameUmDb then
            local m = oGameUmDb:Find("analy", { 
                subtype = "online", _time = {["$gte"] = iFindStart, ["$lte"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds 
                },{interval=true,_time=true})
            while m:hasNext() do
                local mData = m:next()
                local _,time = bson.type(mData._time)
                local dateTime = bkdefines.FormatTime(time-24*3600)
                mResult[dateTime] = mResult[dateTime] or {}
                local interval = mData.interval or {}
                for _,info in pairs(interval) do
                    local cnt = info.cnt or 0
                    local _,ptime = bson.type(info.ptime)
                    local sTime = FormatHourMin(ptime)
                    mResult[dateTime][sTime] = mResult[dateTime][sTime] or 0
                    mResult[dateTime][sTime] = mResult[dateTime][sTime] + cnt
                end
            end
        end
        local oGameLogDb = oServer.m_oGameLogDb:GetDb(iYear, iMonth)
        if oGameLogDb and endTime > iTodayStart then
            local m = oGameLogDb:Find("online", { 
                subtype = "detail", _time = {["$gte"] = iFindLogStart, ["$lte"] = iFindLogEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds 
                },{online_cnt=true,_time=true}
            )
            while m:hasNext() do
                local mData = m:next()
                local cnt = mData.online_cnt
                local _,time = bson.type(mData._time)
                local dateTime = bkdefines.FormatTime(time)
                local sTime = FormatHourMin(time)
                mResult[dateTime] = mResult[dateTime] or {}
                mResult[dateTime][sTime] = mResult[dateTime][sTime] or 0
                mResult[dateTime][sTime] = mResult[dateTime][sTime] + cnt
            end
        end
    end

    local mData = {}
    for dateTime,info in pairs(mResult) do
        local avgCount,playerCount,num = 0,0,0
        for sTime,cnt in pairs(info) do
            avgCount = avgCount + cnt
            num = num + 1
            playerCount = math.max(playerCount,cnt)
        end
        table.insert(mData, {time = bkdefines.AnalyTimeStamp(dateTime) , dateTime = dateTime, 
            avgCount =( avgCount // math.max(num,1) ), playerCount = playerCount
        })
    end

    table.sort(mData,function (a,b)
        return a.time<b.time
    end)

    return {errcode = 0, data = mData}
end

function getCreateSsoAccountCount(mArgs)
    PreProcess(mArgs)
    local iStartTime = mArgs.startTime
    local iEndTime = mArgs.endTime
    local iCnt = getServerRegistryCnt(nil, iStartTime, iEndTime, mArgs) or 0
    return {errcode = 0, data = {count = iCnt}}
end

function CheckServerExist(sServer, mArgs)
    local mDate = os.date("*t", get_time())

    sServer = sServer or "1"
    mArgs = mArgs or {}
    local iYear = mArgs.year or mDate.year
    local iMonth = mArgs.month or mDate.month
    local sServer = mArgs.server or sServer
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj.m_mServers[sServer]
    if not oServer then
        record.info(string.format("server not exist : %d", sServer))
        return 1
    end

    local oGameDb = oServer.m_oGameDb:GetDb()
    if not oGameDb then
        record.info("GameDb not exist!\n")
        return 1
    end

    local oGameLogDb = oServer.m_oGameLogDb:GetDb(iYear, iMonth)
    if not oGameLogDb then
        record.info("GameLogDb not exist!\n")
        return 1
    end

    return 0
end

function calonlineInterval(mDate,mArgs)
    local oBackendObj = global.oBackendObj
    local iTime = bkdefines.AnalyTimeStamp(mDate)
    local iFindStart = bson.date(iTime+24*3600)
    local iFindEnd = bson.date(iTime+30*3600)
    local serverkeys = table_key_list(oBackendObj.m_mServers)

    local iYear,iMonth = bkdefines.GetDateInfo(iTime)
    local iFindToDayStart = bson.date(iTime)
    local iFindToDayEnd = bson.date(iTime + 24*3600)
    local mResult = {}

    local mData = get_daytime({day=0})
    local iTodayStart = mData.time
    local iCurTime = get_time()
    for iTmpTime=iTime,iTime+24*3600,10*60 do
        if iTmpTime < iCurTime then
            local sTime = FormatHourMin(iTmpTime)
            mResult[sTime] = mResult[sTime] or {amount=0}
            mResult[sTime]["time"] = iTmpTime
        end
    end

    for _,sServer in pairs(serverkeys) do
        local oServer = oBackendObj:GetServerObj(sServer)
        if oServer then
            local oGameUmDb = oServer.m_oGameUmDb:GetDb()
            if oGameUmDb then
                local m = oGameUmDb:Find("analy", { 
                    subtype = "online", _time = {["$gte"] = iFindStart, ["$lte"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds 
                    },{interval=true}
                )
                local interval = {}
                while m:hasNext() do
                    local mData = m:next()
                    interval = mData.interval or {}
                    for _,mData in pairs(interval) do
                        local _,time = bson.type(mData.ptime)
                        local sTime = FormatHourMin(time)
                        mResult[sTime] = mResult[sTime] or {amount=0}
                        mResult[sTime]["time"] = time
                        mResult[sTime]["amount"] = mResult[sTime]["amount"] + (mData.cnt or 0)
                    end
                end
            end

            local oGameLogDb = oServer.m_oGameLogDb:GetDb(iYear, iMonth)
            if iTime >= iTodayStart and oGameLogDb then
                local m = oGameLogDb:Find("online", { 
                    subtype = "detail", _time = {["$gte"] = iFindToDayStart, ["$lte"] = iFindToDayEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds 
                    },{online_cnt=true,_time=true}
                )
                while m:hasNext() do
                    local mData = m:next()
                    local _,time = bson.type(mData._time)
                    local sTime = FormatHourMin(time)
                    mResult[sTime] = mResult[sTime] or {amount=0}
                    mResult[sTime]["time"] = time
                    mResult[sTime]["amount"] = mResult[sTime]["amount"] + (mData.online_cnt or 0)
                end
            end
        end
    end

    local mResult2 = {}
    local iAmount = 0
    for sTime,mData in pairs(mResult) do
        table.insert(mResult2, {time = sTime , amount = mData.amount, time2 = mData.time})
    end

    table.sort(mResult2,function (a,b)
        return a.time2 < b.time2
    end)

    return mResult2
end

function getServerRegistryCnt(sServer, iStarttime, iEndtime,mArgs)
    local oBackendObj = global.oBackendObj
    local iCnt = 0
    local iEndtime2 = bkdefines.AnalyTimeStamp( bkdefines.FormatTime(iEndtime) ) + 24*3600

    local iStartFind = bson.date(iStarttime+6*3600)
    local iEndFind = bson.date(iEndtime2+6*3600)

    local mData = get_daytime({day=0})
    local iTodayStart = mData.time
    local iYear = mData.date.year
    local iMonth = mData.date.month
    local iFindLogStart = bson.date(math.max(iTodayStart,iStarttime))
    local iFindLogEnd =bson.date(iEndtime)

    local serverkeys = sServer and {sServer} or oBackendObj:GetServerList()
    for sServer,_ in pairs(serverkeys) do
        local oServer = oBackendObj.m_mServers[sServer]
        local oGameDb = oServer.m_oGameDb:GetDb()
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        if oGameDb and oGameUmDb then
            local m = oGameUmDb:Find("analy",{
                subtype="newaccount",_time = {["$gte"] = iStartFind,["$lt"] = iEndFind},platform=mArgs.platformIds,channel=mArgs.channelIds 
                },{alist=true})
            local alist = {}
            while m:hasNext() do
                local mData = m:next()
                local tmplist = mData.alist or {}
                list_combine(alist,tmplist)
            end
            if iEndtime - iStarttime >= 24*3600 - 1 then
                iCnt = iCnt + #alist
            elseif #alist > 0 then
                local atime = {}
                local m2 = oGameDb:Find("player",{account={["$in"]=alist}},{account=true,base_info=true})
                while m2:hasNext() do
                    local mData = m2:next()
                    mongoop.ChangeAfterLoad(mData)
                    local account = mData.account
                    local createtime = mData.base_info.create_time
                    if account and createtime then
                        atime[account] = atime[account] or createtime
                        atime[account] = math.min(atime[account],createtime)
                    end
                end
                for _,account in pairs(alist) do
                    local time = atime[account]
                    if time and time >= iStarttime and time <= iEndtime then
                        iCnt = iCnt + 1
                    end
                end
            end
        end
        local oGameLogDb = oServer.m_oGameLogDb:GetDb(iYear, iMonth)
        if oGameLogDb and iEndtime > iTodayStart then
            local tAccount = oGameLogDb:GetDB()["account"]
            local iRet = tAccount:find({
                subtype = "create", _time = {['$gte'] = iFindLogStart, ['$lte'] = iFindLogEnd},platform=mArgs.platformIds,channel=mArgs.channelIds 
                }):count()
            iCnt = iCnt + iRet
        end
    end
    return iCnt
end

function FormatHourMin(iTime)
    local mDate = os.date("*t", iTime)
    return string.format("%02d:%02d",mDate.hour,mDate.min)
end