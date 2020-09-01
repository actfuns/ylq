--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"
local extend = require "base.extend"
local bson = require "bson"
local mongoop = require "base.mongoop"

local bkdefines = import(service_path("bkdefines"))
local gamedefines = import(lualib_path("public.gamedefines"))

local pt = extend.Table.print

local tModel = {
   ["iPhone7"]=30,
    ["小米3"]=30,
    ["iphone7P"]=30,
    ["HUAWEIP10"]=30,
}

local tPlatform = {
    ["苹果"]=20,
    ["安卓"]=20,
}

local tChannel = {
    ["多玩"]=30,
    ["YY蚂蚁"]=30,
    ["进击"]=30
}

local tShape = {
    [110]=30,[120]=30,[130]=30,
    [140]=30,[150]=30,[160]=30,
}

local tShape2No = {
    [110]=1,[120]=2,[130]=3,
    [140]=4,[150]=5,[160]=6,
}

local tOrgName = {
    ["天下无双"]=30,["风花雪月"]=30,["毕海阁"]=30,
}

function PostOverViewData(mArgs)
    local oOverViewObj = global.oOverViewObj
    local sType = mArgs.sType
    local mData = {}
    local iStartTime = bkdefines.AnalyTimeStamp(mArgs.startTime)
    local iEndTime = bkdefines.AnalyTimeStamp(mArgs.endTime)
    mArgs.platformIds = bkdefines.GetPlatformList(mArgs.platformIds)
    mArgs.channelIds = bkdefines.GetChannelList(mArgs.channelIds)
    if mArgs.platformIds then
        mArgs.platformIds = {["$in"]=mArgs.platformIds}
    end
    if mArgs.channelIds and not table_in_list({"allchannel"},sType) then
        mArgs.channelIds = {["$in"]=mArgs.channelIds}
    end
    if sType == "allserver" then
        mData = oOverViewObj:AllServerViewData(iStartTime,iEndTime,mArgs)
    elseif sType == "allchannel" then
        mData = oOverViewObj:AllChannelViewData(iStartTime,iEndTime,mArgs)
    elseif sType == "everyday" then
        mData = oOverViewObj:EveryDayViewData(iStartTime,iEndTime,mArgs)
    elseif sType == "detail_server" then
        mData = oOverViewObj:DetailByServerData(iStartTime,iEndTime,mArgs)
    elseif sType == "detail_channel" then
        mData = oOverViewObj:DetailByChannelData(iStartTime,iEndTime,mArgs)
    elseif sType == "detail_date" then
        mData = oOverViewObj:DetailByDateData(iStartTime,iEndTime,mArgs)
    elseif sType == "realday" then
        mData = oOverViewObj:RealDayViewData(iStartTime,iEndTime,mArgs)
    end
    return {errcode=0,data=mData}
end

function NewOverViewObj(...)
    local o = OverViewObj:New(...)
    return o
end

OverViewObj = {}
OverViewObj.__index = OverViewObj

function OverViewObj:New()
    local o = setmetatable({}, self)
    return o
end

function OverViewObj:Init()
end

function OverViewObj:GetServerGameDB(sServer)
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj.m_mServers[sServer]
    if not oServer then
        return
    end
    return oServer.m_oGameDb:GetDb()
end

function OverViewObj:GetServerGameLogDB(sServer, iYear, iMonth)
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj.m_mServers[sServer]
    if not oServer then
        return
    end
    return oServer.m_oGameLogDb:GetDb(iYear, iMonth)
end

function OverViewObj:AllServerViewData(iStartTime,iEndTime,mArgs)
    local oBackendObj = global.oBackendObj
    local serverkeys = serverkeys or table_key_list(oBackendObj.m_mServers)
    local iFindStart = bson.date(iStartTime+6*3600)
    local iFindEnd = bson.date(iEndTime+30*3600)

    local tResult = {}

    for _,sServer in pairs(serverkeys) do
        local mUnit = {totalAccount = 0 , newAccount = 0 , oldAccount = 0 , newPlayer = 0 , oldPlayer = 0 ,avgOnline = 0 , mins = 0 ,}
        local oServer = oBackendObj:GetServerObj(sServer)
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()

        if oGameUmDb then
            local m = oGameUmDb:Find("analy",{
                subtype="newaccount",_time = {["$lt"] = iFindStart } ,platform=mArgs.platformIds,channel=mArgs.channelIds
                },{alist=true})
            while m:hasNext() do
                local mData = m:next()
                local alist = mData.alist or {}
                mUnit["oldAccount"] = mUnit["oldAccount"] + #alist
            end
            m = oGameUmDb:Find("analy",{
                subtype="newaccount",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd },platform=mArgs.platformIds,channel=mArgs.channelIds
                },{alist=true})
            while m:hasNext() do
                local mData = m:next()
                local alist = mData.alist or {}
                mUnit["newAccount"] = mUnit["newAccount"] + #alist
            end
            local m2 = oGameUmDb:Find("analy",{
                subtype="newrole",_time = {["$lt"] = iFindStart } ,platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true})
            while m2:hasNext() do
                local mData = m2:next()
                local plist = mData.plist or {}
                mUnit["oldPlayer"] = mUnit["oldPlayer"] + #plist
            end
            m2 = oGameUmDb:Find("analy",{
                subtype="newrole",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true})
            while m2:hasNext() do
                local mData = m2:next()
                local plist = mData.plist or {}
                mUnit["newPlayer"] = mUnit["newPlayer"] + #plist
            end

            local m3 = oGameUmDb:Find("analy",{
                subtype="online",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                },{interval=true})
            local avgOnline,tTime = 0,{}
            while m3:hasNext() do
                local mData = m3:next()
                local interval = mData.interval or {}
                for _,info in pairs(interval) do
                    local cnt = info.cnt or 0
                    local _,ptime = bson.type(info.ptime)
                    avgOnline = avgOnline + cnt
                    tTime[ptime] = true
                end
            end

            local m4 = oGameUmDb:Find("analy",{
                subtype="duration",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true})
            local iCnt,tPid = 0,{}
            while m4:hasNext() do
                local mData = m4:next()
                local plist = mData.plist or {}
                for _,pinfo in pairs(plist) do
                    local pid = pinfo.pid
                    iCnt = iCnt + (pinfo.tlen or 0)
                    tPid[pid] = true
                end
            end
            mUnit["avgOnline"] = avgOnline // math.max(table_count(tTime),1)
            mUnit["mins"] = iCnt // (math.max(table_count(tPid),1))
            mUnit["totalAccount"] = mUnit["oldAccount"] + mUnit["newAccount"]
            mUnit["server"] = bkdefines.GetServerName(sServer)
            mUnit["openAt"] = bkdefines.GetServerOpenTime(sServer)
            table.insert(tResult,mUnit)
        end
    end
    return tResult
end

function OverViewObj:AllChannelViewData(iStartTime,iEndTime,mArgs)
    local oBackendObj = global.oBackendObj
    local serverkeys = table_key_list(oBackendObj.m_mServers)
    local channels = mArgs.channelIds or bkdefines.GetAllChannelList()
    local iFindStart = bson.date(iStartTime+6*3600)
    local iFindEnd = bson.date(iEndTime+30*3600)

    local tResult = {}
    for _,channel in pairs(channels) do
        local mUnit = {totalAccount = 0 , newAccount = 0 , oldAccount = 0 , newPlayer = 0 , oldPlayer = 0 ,avgOnline = 0 , mins = 0 ,totalLogin = 0, loginPlayer = 0}
        local iCnt,iTotal = 0,0
        local mOnline = {}
        for _,key in pairs(serverkeys) do
            local oServer = oBackendObj:GetServerObj(key)
            local oGameUmDb = oServer.m_oGameUmDb:GetDb()
            if oGameUmDb then
                local m = oGameUmDb:Find("analy",{
                    subtype="newaccount",channel=channel,_time = {["$lt"] = iFindStart } ,platform=mArgs.platformIds
                    },{alist=true})
                while m:hasNext() do
                    local mData = m:next()
                    local alist = mData.alist or {}
                    mUnit["oldAccount"] = mUnit["oldAccount"] + #alist
                end
                m = oGameUmDb:Find("analy",{
                    subtype="newaccount",channel=channel,_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds
                    },{alist=true})
                while m:hasNext() do
                    local mData = m:next()
                    local alist = mData.alist or {}
                    mUnit["newAccount"] = mUnit["newAccount"] + #alist
                end
                local m2 = oGameUmDb:Find("analy",{
                    subtype="newrole",channel=channel,_time = {["$lt"] = iFindStart } ,platform=mArgs.platformIds
                    },{plist=true})
                while m2:hasNext() do
                    local mData = m2:next()
                    local plist = mData.plist or {}
                    mUnit["oldPlayer"] = mUnit["oldPlayer"] + #plist
                end
                m2 = oGameUmDb:Find("analy",{
                    subtype="newrole",channel=channel,_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds
                    },{plist=true})
                while m2:hasNext() do
                    local mData = m2:next()
                    local plist = mData.plist or {}
                    mUnit["newPlayer"] = mUnit["newPlayer"] + #plist
                end

                local m3 = oGameUmDb:Find("analy",{
                    subtype="online",channel=channel,_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds
                    },{interval=true})

                while m3:hasNext() do
                    local mData = m3:next()
                    local interval = mData.interval or {}
                    for _,info in pairs(interval) do
                        local cnt = info.cnt or 0
                        local _,ptime = bson.type(info.ptime)
                        local sTime = string.format("%s-%s",bkdefines.FormatTime(ptime),bkdefines.FormatHourMin(ptime))
                        mOnline[sTime] = mOnline[sTime] or 0
                        mOnline[sTime] = mOnline[sTime] + cnt
                    end
                end

                local m4 = oGameUmDb:Find("analy",{
                    subtype="duration",channel=channel,_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds
                    },{plist=true})

                while m4:hasNext() do
                    local mData = m4:next()
                    local plist = mData.plist or {}
                    for _,pinfo in pairs(plist) do
                        iCnt = iCnt + (pinfo.tlen or 0)
                        iTotal = iTotal + 1
                    end
                end

                local m5 = oGameUmDb:Find("analy",{
                    subtype="loginact",channel=channel,_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds
                    },{alist=true})
                while m5:hasNext() do
                    local mData = m5:next()
                    local alist = mData.alist
                    mUnit["totalLogin"] = mUnit["totalLogin"] + #alist
                end

                local m6 = oGameUmDb:Find("analy",{
                    subtype="loginrole",channel=channel,_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds
                    },{plist=true})
                while m6:hasNext() do
                    local mData = m6:next()
                    local plist = mData.plist
                    mUnit["loginPlayer"] = mUnit["loginPlayer"] + #plist
                end
            end
        end
        local avgOnline,num = 0,0
        for _,cnt in pairs(mOnline) do
            avgOnline = avgOnline + cnt
            num = num + 1
        end
        mUnit["avgOnline"] = avgOnline // math.max(num,1)
        mUnit["mins"] = iCnt // (math.max(iTotal,1))
        mUnit["totalAccount"] = mUnit["oldAccount"] + mUnit["newAccount"]
        mUnit["totalPlayer"] = mUnit["oldPlayer"] + mUnit["newPlayer"]
        mUnit["channel"] = channel
        table.insert(tResult,mUnit)
    end
    return tResult
end

function OverViewObj:EveryDayViewData(iStartTime,iEndTime,mArgs)
    local oBackendObj = global.oBackendObj
    local serverkeys = table_key_list(oBackendObj.m_mServers)
    local channels = channels or table_key_list(tChannel)

    local tResult = {}
    for iTime=iStartTime,iEndTime,24*3600 do
        local iFindStart = bson.date(iTime+6*3600)
        local iFindEnd = bson.date(iTime+30*3600)
        local mUnit = {totalAccount = 0 , newAccount = 0 , oldAccount = 0 , newPlayer = 0 , oldPlayer = 0 ,avgOnline = 0 , mins = 0 ,maxOnline = 0, totalLogin = 0, loginPlayer = 0}
        local mOnline = {}
        local iCnt,iTotal = 0,0,0,0
        for _,key in pairs(serverkeys) do
            local oServer = oBackendObj:GetServerObj(key)
            local oGameUmDb = oServer.m_oGameUmDb:GetDb()
            if oGameUmDb then
                local m = oGameUmDb:Find("analy",{
                    subtype="newaccount",_time = {["$lt"] = iFindStart } ,platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{alist=true})
                while m:hasNext() do
                    local mData = m:next()
                    local alist = mData.alist or {}
                    mUnit["oldAccount"] = mUnit["oldAccount"] + #alist
                end
                m = oGameUmDb:Find("analy",{
                    subtype="newaccount",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{alist=true})
                while m:hasNext() do
                    local mData = m:next()
                    local alist = mData.alist or {}
                    mUnit["newAccount"] = mUnit["newAccount"] + #alist
                end
                local m2 = oGameUmDb:Find("analy",{
                    subtype="newrole",_time = {["$lt"] = iFindStart } ,platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{plist=true})
                while m2:hasNext() do
                    local mData = m2:next()
                    local plist = mData.plist or {}
                    mUnit["oldPlayer"] = mUnit["oldPlayer"] + #plist
                end
                m2 = oGameUmDb:Find("analy",{
                    subtype="newrole",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{plist=true})
                while m2:hasNext() do
                    local mData = m2:next()
                    local plist = mData.plist or {}
                    mUnit["newPlayer"] = mUnit["newPlayer"] + #plist
                end

                local m3 = oGameUmDb:Find("analy",{
                    subtype="online",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{interval=true})

                while m3:hasNext() do
                    local mData = m3:next()
                    local interval = mData.interval or {}
                    for _,info in pairs(interval) do
                        local cnt = info.cnt or 0
                        local _,ptime = bson.type(info.ptime)
                        local sTime = bkdefines.FormatHourMin(ptime)
                        mOnline[sTime] = mOnline[sTime] or 0
                        mOnline[sTime] = mOnline[sTime] + cnt
                    end
                end

                local m4 = oGameUmDb:Find("analy",{
                    subtype="duration",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{plist=true})

                while m4:hasNext() do
                    local mData = m4:next()
                    local plist = mData.plist or {}
                    for _,pinfo in pairs(plist) do
                        iCnt = iCnt + (pinfo.tlen or 0)
                        iTotal = iTotal + 1
                    end
                end

                local m5 = oGameUmDb:Find("analy",{
                    subtype="loginact",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{alist=true})
                while m5:hasNext() do
                    local mData = m5:next()
                    local alist = mData.alist
                    mUnit["totalLogin"] = mUnit["totalLogin"] + #alist
                end

                local m6 = oGameUmDb:Find("analy",{
                    subtype="loginrole",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{plist=true})
                while m6:hasNext() do
                    local mData = m6:next()
                    local plist = mData.plist
                    mUnit["loginPlayer"] = mUnit["loginPlayer"] + #plist
                end
            end
        end
        local avgOnline,maxOnline,num = 0,0,0
        for _,cnt in pairs(mOnline) do
            avgOnline = avgOnline + cnt
            num = num + 1
            maxOnline = math.max(maxOnline,cnt)
        end
        mUnit["avgOnline"] = avgOnline // math.max(num,1)
        mUnit["maxOnline"] = maxOnline
        mUnit["mins"] = iCnt // (math.max(iTotal,1))
        mUnit["totalAccount"] = mUnit["oldAccount"] + mUnit["newAccount"]
        mUnit["totalPlayer"] = mUnit["oldPlayer"] + mUnit["newPlayer"]
        mUnit["time"] = bkdefines.FormatTime(iTime)
        table.insert(tResult,mUnit)
    end
    return tResult
end

function OverViewObj:DetailByServerData(iStartTime,iEndTime)
    local oBackendObj = global.oBackendObj
    local serverkeys = serverkeys or table_key_list(oBackendObj.m_mServers)
    local iFindStart = bson.date(iStartTime+6*3600)
    local iFindEnd = bson.date(iEndTime+30*3600)
    local tResult = {}

    for _,sServer in pairs(serverkeys) do
        local mUnit = {
            accountAmt = 0,playerAmt = 0,faction1Amt=0,faction2Amt=0,faction3Amt=0,
            mainChar1Amt = 0,mainChar2Amt = 0,mainChar3Amt = 0,mainChar4Amt = 0,mainChar5Amt = 0,mainChar6Amt = 0,
        }
        local oServer = oBackendObj:GetServerObj(sServer)
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        local oGameDb = oServer.m_oGameDb:GetDb()
        if oGameUmDb and oGameDb then
            local m = oGameUmDb:Find("analy",{subtype="newaccount",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} },{alist=true})
            while m:hasNext() do
                local mData = m:next()
                local alist = mData.alist or {}
                mUnit["accountAmt"] = mUnit["accountAmt"] + #alist
            end
            local m2 = oGameUmDb:Find("analy",{subtype="newrole",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} },{plist=true})
            local tmplist = {}
            while m2:hasNext() do
                local mData = m2:next()
                local plist = mData.plist or {}
                mUnit["playerAmt"] = mUnit["playerAmt"] + #plist
                tmplist = list_combine(tmplist,plist)
            end
            if #tmplist > 0 then
                local m3 = oGameDb:Find("player",{pid={["$in"]=tmplist}},{pid=true,base_info=true})
                while m3:hasNext() do
                    local mData = m3:next()
                    mongoop.ChangeAfterLoad(mData)
                    local base_info = mData.base_info or {}
                    local model_info = base_info.model_info or {}
                    local pid = mData.pid
                    local school = base_info.school
                    local shape = model_info.shape
                    if school and shape then
                        local sSchoolKey = string.format("faction%dAmt",school)
                        local sShapeKey = string.format("mainChar%dAmt",tShape2No[shape])
                        mUnit[sSchoolKey] = mUnit[sSchoolKey] + 1
                        mUnit[sShapeKey] = mUnit[sShapeKey] + 1
                    end
                end
            end
        end
        mUnit["serverId"] = bkdefines.GetServerName(sServer)
        table.insert(tResult,mUnit)
    end
    return tResult
end

function OverViewObj:DetailByChannelData(iStartTime,iEndTime)
    local oBackendObj = global.oBackendObj
    local serverkeys = table_key_list(oBackendObj.m_mServers)
    local channels = bkdefines.GetAllChannelList()
    local iFindStart = bson.date(iStartTime+6*3600)
    local iFindEnd = bson.date(iEndTime+30*3600)

    local tResult = {}
    for _,channel in pairs(channels) do
        local tHasAccount = {}
        local tHasPlayer = {}
        local mUnit = {accountAmt = 0,playerAmt = 0, faction1Amt=0 , faction2Amt=0 , faction3Amt=0,
            mainChar1Amt = 0,mainChar2Amt = 0,mainChar3Amt = 0,
            mainChar4Amt = 0,mainChar5Amt = 0,mainChar6Amt = 0,
        }
        for _,sServer in pairs(serverkeys) do
            local oServer = oBackendObj:GetServerObj(sServer)
            local oGameUmDb = oServer.m_oGameUmDb:GetDb()
            local oGameDb = oServer.m_oGameDb:GetDb()
            if oGameUmDb and oGameDb then
                local m = oGameUmDb:Find("analy",{subtype="newaccount",channel=channel,_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} },{alist=true})
                while m:hasNext() do
                    local mData = m:next()
                    local alist = mData.alist or {}
                    mUnit["accountAmt"] = mUnit["accountAmt"] + #alist
                end
                local m2 = oGameUmDb:Find("analy",{subtype="newrole",channel=channel,_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} },{plist=true})
                local tmplist = {}
                while m2:hasNext() do
                    local mData = m2:next()
                    local plist = mData.plist or {}
                    mUnit["playerAmt"] = mUnit["playerAmt"] + #plist
                    tmplist = list_combine(tmplist,plist)
                end
                if #tmplist > 0 then
                    local m3 = oGameDb:Find("player",{pid={["$in"]=tmplist}},{pid=true,base_info=true})
                    while m3:hasNext() do
                        local mData = m3:next()
                        mongoop.ChangeAfterLoad(mData)
                        local base_info = mData.base_info or {}
                        local model_info = base_info.model_info or {}
                        local pid = mData.pid
                        local school = base_info.school
                        local shape = model_info.shape
                        if school and shape then
                            local sSchoolKey = string.format("faction%dAmt",school)
                            local sShapeKey = string.format("mainChar%dAmt",tShape2No[shape])
                            mUnit[sSchoolKey] = mUnit[sSchoolKey] + 1
                            mUnit[sShapeKey] = mUnit[sShapeKey] + 1
                        end
                    end
                end
            end
        end
        mUnit["channelId"] = channel
        table.insert(tResult,mUnit)
    end
    return tResult
end

function OverViewObj:DetailByDateData(iStartTime,iEndTime)
    local oBackendObj = global.oBackendObj
    local serverkeys = table_key_list(oBackendObj.m_mServers)
    local channels = channels or table_key_list(tChannel)

    local tResult = {}
    for iTime=iStartTime,iEndTime,24*3600 do
        local tHasAccount = {}
        local tHasPlayer = {}
        local mUnit = {accountAmt = 0,playerAmt = 0, faction1Amt=0 , faction2Amt=0 , faction3Amt=0 ,
            mainChar1Amt = 0, mainChar2Amt = 0, mainChar3Amt = 0,
            mainChar4Amt = 0, mainChar5Amt = 0, mainChar6Amt = 0,
        }
        local iFindStart = bson.date(iTime+6*3600)
        local iFindEnd = bson.date(iTime+30*3600)
        for _,sServer in pairs(serverkeys) do
            local oServer = oBackendObj:GetServerObj(sServer)
            local oGameUmDb = oServer.m_oGameUmDb:GetDb()
            local oGameDb = oServer.m_oGameDb:GetDb()
            if oGameUmDb and oGameDb then
                local m = oGameUmDb:Find("analy",{subtype="newaccount",channel=channel,_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} },{alist=true})
                while m:hasNext() do
                    local mData = m:next()
                    local alist = mData.alist or {}
                    mUnit["accountAmt"] = mUnit["accountAmt"] + #alist
                end
                local m2 = oGameUmDb:Find("analy",{subtype="newrole",channel=channel,_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} },{plist=true})
                local tmplist = {}
                while m2:hasNext() do
                    local mData = m2:next()
                    local plist = mData.plist or {}
                    mUnit["playerAmt"] = mUnit["playerAmt"] + #plist
                    tmplist = list_combine(tmplist,plist)
                end
                if #tmplist > 0 then
                    local m3 = oGameDb:Find("player",{pid={["$in"]=tmplist}},{pid=true,base_info=true})
                    while m3:hasNext() do
                        local mData = m3:next()
                        mongoop.ChangeAfterLoad(mData)
                        local base_info = mData.base_info or {}
                        local model_info = base_info.model_info or {}
                        local pid = mData.pid
                        local school = base_info.school
                        local shape = model_info.shape
                        if school and shape then
                            local sSchoolKey = string.format("faction%dAmt",school)
                            local sShapeKey = string.format("mainChar%dAmt",tShape2No[shape])
                            mUnit[sSchoolKey] = mUnit[sSchoolKey] + 1
                            mUnit[sShapeKey] = mUnit[sShapeKey] + 1
                        end
                    end
                end
            end
        end
        mUnit["createTime"] = bkdefines.FormatTime(iTime)
        table.insert(tResult,mUnit)
    end
    return tResult
end

function OverViewObj:RealDayViewData(iStartTime,iEndTime,mArgs)
    local oBackendObj = global.oBackendObj
    local serverkeys = table_key_list(oBackendObj.m_mServers)

    local mData = get_daytime({day=0})
    local iTodayStart = mData.time
    local iYear = mData.date.year
    local iMonth = mData.date.month
    local tRet = {}
    for iTime=iStartTime,iEndTime,24*3600 do
        local mUnit = {time=bkdefines.FormatTime(iTime)}
        local tCreateAct,tLoginAct = {},{}
        local iStartFind = bson.date(iTime+6*3600)
        local iEndFind = bson.date(iTime+30*3600)
        for _,sServer in pairs(serverkeys) do
            local oServer = oBackendObj:GetServerObj(sServer)
            local oGameUmDb = oServer.m_oGameUmDb:GetDb()
            if oGameUmDb then
                local m = oGameUmDb:Find("analy",{
                    subtype="newaccount",_time = {["$gte"] = iStartFind,["$lt"] = iEndFind} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{alist=true})
                while m:hasNext() do
                    local mData = m:next()
                    local alist = mData.alist or {}
                    for _,act in pairs(alist) do
                        tCreateAct[act] = true
                    end
                end
                local m2 = oGameUmDb:Find("analy",{
                    subtype="loginact",_time = {["$gte"] = iStartFind,["$lt"] = iEndFind} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{alist=true})
                while m2:hasNext() do
                    local mData = m2:next()
                    local alist = mData.alist or {}
                    for _,act in pairs(alist) do
                        tLoginAct[act] = true
                    end
                end
            end
            local iFindLogStart = bson.date(math.max(iTodayStart,iTime))
            local iFindLogEnd =bson.date(iTime+24*3600)
            local oGameLogDb = oServer.m_oGameLogDb:GetDb(iYear, iMonth)
            if oGameLogDb and iTime+24*3600 > iTodayStart then
                local m = oGameLogDb:Find("account",{
                    subtype="create",_time = {["$gte"] = iFindLogStart,["$lt"] = iFindLogEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{account=true})
                while m:hasNext() do
                    local mData = m:next()
                    local act = mData.account
                    if act then
                        tCreateAct[act] = true
                    end
                end
                local m2 = oGameLogDb:Find("player",{
                    subtype="login",_time = {["$gte"] = iFindLogStart,["$lt"] = iFindLogEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{account=true})
                while m2:hasNext() do
                    local mData = m2:next()
                    mongoop.ChangeAfterLoad(mData)
                    local act = mData.account
                    if act then
                        tLoginAct[act] = true
                    end
                end
            end
        end
        mUnit.createact = table_count(tCreateAct)
        mUnit.loginact = table_count(tLoginAct)
        for iDay=1,7 do
            local iLoginStartTime = iTime + iDay * 24 * 3600
            local iLoginEndTime = iTime + (iDay+1) * 24 * 3600
            local iFindUmLoginStart = bson.date(iLoginStartTime + 6*3600)
            local iFindUmLoginEnd = bson.date(iLoginEndTime + 6*3600)
            local iFindLogStart = bson.date(math.max(iTodayStart,iLoginStartTime))
            local iFindLogEnd =bson.date(iLoginEndTime)
            local tRest = {}
            for _,sServer in pairs(serverkeys) do
                local oServer = oBackendObj:GetServerObj(sServer)
                local oGameUmDb = oServer.m_oGameUmDb:GetDb()
                if oGameUmDb then
                    local m = oGameUmDb:Find("analy",{subtype="loginact",
                        _time = {["$gte"] = iFindUmLoginStart,["$lt"] = iFindUmLoginEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                        },{alist=true})
                    while m:hasNext() do
                        local mData = m:next()
                        local alist = mData.alist or {}
                        for  _,act in pairs(alist) do
                            if tCreateAct[act] then
                                tRest[act] = true
                            end
                        end
                    end
                end
                local oGameLogDb = oServer.m_oGameLogDb:GetDb(iYear, iMonth)
                if oGameLogDb and iLoginEndTime > iTodayStart then
                    local m = oGameLogDb:Find("player",{subtype="login",
                        _time = {["$gte"] = iFindLogStart,["$lt"] = iFindLogEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                        },{account=true})
                    while m:hasNext() do
                        local mData = m:next()
                        mongoop.ChangeAfterLoad(mData)
                        local act = mData.account
                        if act and tCreateAct[act] then
                            tRest[act] = true
                        end
                    end
                end
            end
            local sKey = string.format("keep%d",(iDay+1))
            local iRest = table_count(tRest)
            mUnit[sKey] = string.format("%d(%.2f%%)",iRest,iRest/math.max(mUnit.createact,1)*100.0)
        end
        table.insert(tRet,mUnit)
    end
    return tRet
end

function OverViewObj:TmpLiuCun()
    local oBackendObj = global.oBackendObj

    local mData = get_daytime({day=0})
    local iTime = mData.time
    local iYear = mData.date.year
    local iMonth = mData.date.month
    local iStartFind = bson.date(iTime)
    local iEndFind = bson.date(iTime+6*3600)

    local serverkeys = table_key_list(oBackendObj.m_mServers)
    local tmplist = {}
    local mPlayer = {}
    for _,sServer in pairs(serverkeys) do
        local oServer = oBackendObj:GetServerObj(sServer)
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        if oGameUmDb then
            local m = oGameUmDb:Find( "analy",{
                subtype="upgrade",_time = {["$gte"] = iStartFind,["$lt"] = iEndFind}
            },{plist=true})
            while m:hasNext() do
                local mData = m:next()
                local plist = mData.plist or {}
                for _,info in pairs(plist) do
                    local pid = info.pid
                    local grade = info.grade
                    if grade and grade > 5 then
                        table.insert(tmplist,pid)
                    end
                end
            end
        end
        local oGameLogDb = oServer.m_oGameLogDb:GetDb(iYear, iMonth)
        if oGameLogDb and #tmplist > 0 then
            local m = oGameLogDb:Find("player",{pid={["$in"]=tmplist},subtype="login",_time = {["$gte"] = iStartFind}},{pid=true})
            while m:hasNext() do
                local mData = m:next()
                mongoop.ChangeAfterLoad(mData)
                local pid = mData.pid
                if pid then
                    mPlayer[pid] = true
                end
            end
        end
    end
    local iRest = table_count(mPlayer)
    local iTotal = #tmplist
    print ("*****",iTotal,string.format("%d(%.2f%%)",iRest,iRest/math.max(iTotal,1)*100.0))
end