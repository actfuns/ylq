--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local record = require "public.record"
local bson = require "bson"
local extend = require "base.extend"
local res = require "base.res"
local bkdefines = import(service_path("bkdefines"))

function NewPlayerStatObj(...)
    local o = CPlayerStatObj:New(...)
    return o
end

--玩家统计信息
CPlayerStatObj = {}
CPlayerStatObj.__index = CPlayerStatObj

function CPlayerStatObj:New()
    local o = setmetatable({}, self)
    return o
end

function CPlayerStatObj:Init()
end

function CPlayerStatObj:GetServerGameDB(sServer)
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj.m_mServers[sServer]
    if not oServer then
        return
    end
    return oServer.m_oGameDb:GetDb()
end

function CPlayerStatObj:GetServerGameLogDB(sServer, iYear, iMonth)
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj.m_mServers[sServer]
    if not oServer then
        return
    end
    return oServer.m_oGameLogDb:GetDb(iYear, iMonth)
end

function CPlayerStatObj:NewHour(iDay,iHour)
end

function CPlayerStatObj:PreProcess(mArgs)
    mArgs.platformIds = bkdefines.GetPlatformList(mArgs.platformIds)
    mArgs.channelIds = bkdefines.GetChannelList(mArgs.channelIds)
    if mArgs.platformIds then
        mArgs.platformIds = {["$in"]=mArgs.platformIds}
    end
    if mArgs.channelIds then
        mArgs.channelIds = {["$in"]=mArgs.channelIds}
    end
end

--活跃用户
function CPlayerStatObj:ActivePlayer(mArgs)
    self:PreProcess(mArgs)
    local iStartTime = bkdefines.AnalyTimeStamp(mArgs.startTime)
    local iEndTime = bkdefines.AnalyTimeStamp(mArgs.endTime)

    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList()
    local mRet = {}

    for iTime=iStartTime,iEndTime,24*3600 do
        local mUnit = {
            date = bkdefines.FormatTime(iTime) , regAccount = 0 , oldAccountLogin = 0 , accountLogin = 0 , roleLogin = 0,
        }
        local iFindStart = bson.date(iTime+6*3600)
        local iFindEnd = bson.date(iTime+30*3600)
        local tHasAccount = {}
        local tLoginAccount = {}
        for sServer,_ in pairs(serverkeys) do
            local oServer = oBackendObj:GetServerObj(sServer)
            local oGameUmDb = oServer.m_oGameUmDb:GetDb()
            if oGameUmDb then
                local m = oGameUmDb:Find("analy",{
                    subtype="newaccount",_time = {["$gte"] = iFindStart , ["$lt"] = iFindEnd },platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{alist=true}
                )
                while m:hasNext() do
                    local mData = m:next()
                    local alist = mData.alist or {}
                    for _,account in pairs(alist) do
                        tHasAccount[account] = true
                    end
                end
                local m2 = oGameUmDb:Find( "analy",{
                    subtype="loginact",_time = {["$gte"] = iFindStart , ["$lt"] = iFindEnd },platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{alist=true}
                )
                while m2:hasNext() do
                    local mData = m2:next()
                    local alist = mData.alist or {}
                    for _,account in pairs(alist) do
                        if not tHasAccount[account] then
                            mUnit["oldAccountLogin"] = mUnit["oldAccountLogin"] + 1
                        end
                        tLoginAccount[account] = true
                    end
                end
                local m3 = oGameUmDb:Find( "analy",{
                    subtype="loginrole",_time = {["$gte"] = iFindStart , ["$lt"] = iFindEnd },platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{plist=true}
                )
                while m3:hasNext() do
                    local mData = m3:next()
                    local plist = mData.plist or {}
                    mUnit["roleLogin"] = mUnit["roleLogin"] + #plist
                end

            end
        end
        mUnit.regAccount = table_count(tHasAccount)
        mUnit.accountLogin = table_count(tLoginAccount)
        table.insert(mRet,mUnit)
    end
    return {errcode = 0, data = mRet}
end

--账号留存
function CPlayerStatObj:AccountRetention(mArgs)
    self:PreProcess(mArgs)
    local iStartTime = bkdefines.AnalyTimeStamp(mArgs.startTime)
    local iEndTime = bkdefines.AnalyTimeStamp(mArgs.endTime)

    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList()
    local tRecord = {}
    local tCreateTime = {}

    for iTime=iStartTime,iEndTime+30*24*3600,24*3600 do
        local iFindStart = bson.date(iTime+6*3600)
        local iFindEnd = bson.date(iTime+30*3600)
        tRecord[iTime] = { create = 0 , dayCountMap = {} }

        for iNo=1,30 do
            tRecord[iTime]["dayCountMap"][iNo] = {}
        end
        local tHasAccount = {}
        for sServer,oServer in pairs(serverkeys) do
            local oGameUmDb = oServer.m_oGameUmDb:GetDb()
            if oGameUmDb then
                if iTime <= iEndTime then
                    local m = oGameUmDb:Find("analy",{
                        subtype="newaccount",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd },platform=mArgs.platformIds,channel=mArgs.channelIds
                        },{alist=true}
                    )
                    while m:hasNext() do
                        local mData = m:next()
                        local alist = mData.alist or {}
                        for _,account in pairs(alist) do
                            tCreateTime[account] = iTime
                            tHasAccount[account] = true
                        end
                    end
                end
                local m = oGameUmDb:Find("analy",{
                    subtype="loginact",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd },platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{alist=true}
                )
                while m:hasNext() do
                    local mData = m:next()
                    local alist = mData.alist or {}
                    for _,account in pairs(alist) do
                        local iPreTime = tCreateTime[account]
                        if iPreTime then
                            local iDay = ( iTime - iPreTime ) // (24*3600) + 1
                            if iDay >= 1 and iDay <= 30 then
                                tRecord[iPreTime]["dayCountMap"][iDay][account] = true
                            end
                        end
                    end
                end
            end
        end
        tRecord[iTime]["create"] = tRecord[iTime]["create"] + table_count(tHasAccount)
    end
    local mRet = {}
    for iTime=iStartTime,iEndTime,24*3600 do
        local mUnit = tRecord[iTime]
        for iNo = 1 , 30 do
            mUnit["dayCountMap"][iNo] = table_count(mUnit["dayCountMap"][iNo])
        end
        if mUnit then
            mUnit.statDate = bkdefines.FormatTime(iTime)
            table.insert(mRet,mUnit)
        end
    end

    return {errcode = 0, data = mRet}
end

--角色留存
function CPlayerStatObj:RoleRetention(mArgs)
    self:PreProcess(mArgs)
    local iStartTime = bkdefines.AnalyTimeStamp(mArgs.startTime)
    local iEndTime = bkdefines.AnalyTimeStamp(mArgs.endTime)

    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList()
    local tRecord = {}
    local tCreateTime = {}

    for iTime=iStartTime,iEndTime+30*24*3600,24*3600 do
        local iFindStart = bson.date(iTime+6*3600)
        local iFindEnd = bson.date(iTime+30*3600)
        tRecord[iTime] = { create = 0 , dayCountMap = {} }
        for iNo=1,30 do
            tRecord[iTime]["dayCountMap"][iNo] = {}
        end
        for sServer,oServer in pairs(serverkeys) do
            local oGameUmDb = oServer.m_oGameUmDb:GetDb()
            if oGameUmDb then
                if iTime <= iEndTime then
                    local m = oGameUmDb:Find("analy",{
                        subtype="newrole",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd },platform=mArgs.platformIds,channel=mArgs.channelIds
                        },{plist=true}
                    )
                    while m:hasNext() do
                        local mData = m:next()
                        local plist = mData.plist or {}
                        tRecord[iTime]["create"] = tRecord[iTime]["create"] + #plist
                        for _,pid in pairs(plist) do
                            local sPid = string.format("%s-%d",sServer,pid)
                            tCreateTime[sPid] = iTime
                        end
                    end
                end
                local m = oGameUmDb:Find("analy",{
                    subtype="loginrole",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd },platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{plist=true}
                )
                while m:hasNext() do
                    local mData = m:next()
                    local plist = mData.plist or {}
                    for _,pid in pairs(plist) do
                        local sPid = string.format("%s-%d",sServer,pid)
                        local iPreTime = tCreateTime[sPid]
                        if iPreTime then
                            local iDay = ( iTime - iPreTime ) // (24*3600) + 1
                            if iDay >= 1 and iDay <= 30 then
                                tRecord[iPreTime]["dayCountMap"][iDay][sPid] = true
                            end
                        end
                    end
                end
            end
        end
    end
    local mRet = {}
    for iTime=iStartTime,iEndTime,24*3600 do
        local mUnit = tRecord[iTime]
        for iNo = 1 , 30 do
            mUnit["dayCountMap"][iNo] = table_count(mUnit["dayCountMap"][iNo])
        end
        if mUnit then
            mUnit.statDate = bkdefines.FormatTime(iTime)
            table.insert(mRet,mUnit)
        end
    end

    return {errcode = 0, data = mRet}
end

--设备留存
function CPlayerStatObj:DeviceRetention(mArgs)
    self:PreProcess(mArgs)
    local iStartTime = bkdefines.AnalyTimeStamp(mArgs.startTime)
    local iEndTime = bkdefines.AnalyTimeStamp(mArgs.endTime)

    local oBackendObj = global.oBackendObj
    local oBackEndDb = oBackendObj.m_oBackendDb
    local serverkeys = oBackendObj:GetServerList()
    local tRecord = {}
    local tCreateTime = {}

    for iTime=iStartTime,iEndTime+30*24*3600,24*3600 do
        local iFindStart = bson.date(iTime+6*3600)
        local iFindEnd = bson.date(iTime+30*3600)
        tRecord[iTime] = { create = 0 , dayCountMap = {} }
        for iNo=1,30 do
            tRecord[iTime]["dayCountMap"][iNo] = {}
        end
        for sServer,oServer in pairs(serverkeys) do
            local oGameUmDb = oServer.m_oGameUmDb:GetDb()
            if oGameUmDb then
                if iTime <= iEndTime then
                    local m = oGameUmDb:Find("analy",{
                        subtype="newdevice",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd },platform=mArgs.platformIds,channel=mArgs.channelIds
                        } ,{mlist=true}
                    )
                    while m:hasNext() do
                        local mData = m:next()
                        local mlist = mData.mlist or {}
                        tRecord[iTime]["create"] = tRecord[iTime]["create"] + #mlist
                        for _,mac in pairs(mlist) do
                            tCreateTime[mac] = iTime
                        end
                    end
                end
                local m = oGameUmDb:Find("analy",{
                    subtype="logindev",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd },platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{mlist=true}
                )
                while m:hasNext() do
                    local mData = m:next()
                    local mlist = mData.mlist or {}
                    for _,mac in pairs(mlist) do
                        local iPreTime = tCreateTime[mac]
                        if iPreTime then
                            local iDay = ( iTime - iPreTime ) // (24*3600) + 1
                            if iDay >= 1 and iDay <= 30 then
                                tRecord[iPreTime]["dayCountMap"][iDay][mac] = true
                            end
                        end
                    end
                end
            end
        end
    end
    local mRet = {}
    for iTime=iStartTime,iEndTime,24*3600 do
        local mUnit = tRecord[iTime]
        for iNo = 1 , 30 do
            mUnit["dayCountMap"][iNo] = table_count(mUnit["dayCountMap"][iNo])
        end
        if mUnit then
            mUnit.statDate = bkdefines.FormatTime(iTime)
            table.insert(mRet,mUnit)
        end
    end

    return {errcode = 0, data = mRet}
end

tTimeLevel = {  [10] = "10分钟以内",    [30] = "10-30分钟",   [60] = "30-60分钟",
    [120] = "1-2小时",    [180] = "2-3小时",    [240] = "3-4小时",    [360] = "4-6小时",
    [10000000] = "6小时"
}

--在线时长分布
function CPlayerStatObj:OnlineDistribute(mArgs)
    self:PreProcess(mArgs)
    local iTime = bkdefines.AnalyTimeStamp(mArgs.statDate)
    local sType = mArgs.isNew
    local year,month = bkdefines.GetDateInfo(iTime)
    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList()

    local iFindStart = bson.date(iTime+6*3600)
    local iFindEnd = bson.date(iTime+30*3600)

    local timekeylist = table_key_list(tTimeLevel)
    table.sort(timekeylist)
    local tResult = {}
    for _,key in pairs(timekeylist) do
        tResult[key] = { accountcnt = {}, accountrate = "", rolecnt = {}, rolerate = "",}
    end
    for sServer,oServer in pairs(serverkeys) do
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        local oGameDb = oServer.m_oGameDb:GetDb()
        local tNewPlayer = {}
        local tAccount = {}
        if oGameUmDb and oGameDb then
            local m = oGameUmDb:Find("analy",{
                subtype = "newrole", _time = {["$gte"]=iFindStart, ["$lt"] = iFindEnd},platform=mArgs.platformIds,channel=mArgs.channelIds
                } ,{plist=true}
            )
            while m:hasNext() do
                local mData = m:next()
                local plist = mData.plist or {}
                for _,pid in pairs(plist) do
                    tNewPlayer[pid] = true
                end
            end
            local m2 = oGameUmDb:Find("analy",{
                subtype = "duration", _time = {["$gte"]=iFindStart, ["$lt"] = iFindEnd},platform=mArgs.platformIds,channel=mArgs.channelIds
                } ,{plist=true}
            )
            while m2:hasNext() do
                local mData = m2:next()
                local plist = mData.plist or {}
                local tmplist = {}
                for _,info in pairs(plist) do
                    local pid = info.pid
                    if (sType == "all") or (sType == "old" and not tNewPlayer[pid]) or (sType == "new" and tNewPlayer[pid]) then
                        table.insert(tmplist,pid)
                    end
                end

                if #tmplist > 0 then
                    local m3 = oGameDb:Find("player",{pid={["$in"]=tmplist}} ,
                        {pid=true,account=true}
                    )
                    while m3:hasNext() do
                        local mData2 = m3:next()
                        local pid = mData2.pid
                        local account = mData2.account
                        tAccount[pid] = account
                    end
                end

                for _,info in pairs(plist) do
                    local pid = info.pid
                    local tlen = info.tlen
                    local sPid = string.format("%s-%d", sServer, pid)
                    if (sType == "all") or (sType == "old" and not tNewPlayer[pid]) or (sType == "new" and tNewPlayer[pid]) then
                        for _,key in pairs(timekeylist) do
                            if tlen <= key then
                                tResult[key]["rolecnt"][sPid] = true
                                tResult[key]["accountcnt"][tAccount[pid] or pid] = true
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    local iTotalAccount,iTotalRole = 0,0
    local tRet = {}
    for _,key in pairs(timekeylist) do
        local mUnit = tResult[key]
        if mUnit then
            mUnit["timelen"] = tTimeLevel[key]
            mUnit["accountcnt"] = table_count(mUnit["accountcnt"])
            mUnit["rolecnt"] = table_count(mUnit["rolecnt"])
            iTotalAccount = iTotalAccount + mUnit["accountcnt"]
            iTotalRole = iTotalRole + mUnit["rolecnt"]
        end
    end

    for _,key in pairs(timekeylist) do
        local mUnit = tResult[key]
        if mUnit then
            mUnit["accountrate"] = string.format("%.2f",mUnit["accountcnt"]/math.max(iTotalAccount,1)*100.0)
            mUnit["rolerate"] = string.format("%.2f",mUnit["rolecnt"]/math.max(iTotalRole,1)*100.0)
            table.insert(tRet,mUnit)
        end
    end

    return {errcode = 0, data = tRet}
end

--等级分布
function CPlayerStatObj:levelDistribute(mArgs)
    self:PreProcess(mArgs)
    local iStatTime = bkdefines.AnalyTimeStamp(mArgs.statTime)
    local iFindStart1 = bson.date(iStatTime+6*3600)
    local iFindEnd1 = bson.date(iStatTime+30*3600)

    local iStartTime = bkdefines.AnalyTimeStamp(mArgs.createTimeStart)
    local iEndTime = bkdefines.AnalyTimeStamp(mArgs.createTimeEnd)
    local iFindStart2 = bson.date(iStartTime+6*3600)
    local iFindEnd2 = bson.date(iEndTime+30*3600)

    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList()

    local tResult = {}
    local iTotal = 0
    for sServer,oServer in pairs(serverkeys) do
        local tHasPlayer = {}
        local tSchool = {}
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        local oGameDb = oServer.m_oGameDb:GetDb()
        if oGameUmDb and oGameDb then
            local m = oGameUmDb:Find( "analy",{
                subtype="newrole",_time = {["$gte"] = iFindStart2,["$lt"] = iFindEnd2} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true}
            )
            local tmplist = {}
            while m:hasNext() do
                local mData = m:next()
                local plist = mData.plist or {}
                tmplist = list_combine(tmplist,plist)
                for _,pid in pairs(plist) do
                    tHasPlayer[pid] = true
                end
            end

            if #tmplist > 0 then
                local m2 = oGameDb:Find( "player",{pid={["$in"]=tmplist}},{pid=true,base_info=true})
                while m2:hasNext() do
                    local mData = m2:next()
                    mongoop.ChangeAfterLoad(mData)
                    local pid = mData.pid
                    local base_info = mData.base_info or {}
                    local school = base_info.school
                    tSchool[pid] = school
                end
            end

            local m3 = oGameUmDb:Find( "analy",{
                subtype="upgrade",_time = {["$gte"] = iFindStart1,["$lt"] = iFindEnd1} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true}
            )
            while m3:hasNext() do
                local mData = m3:next()
                local plist = mData.plist or {}
                for _,info in pairs(plist) do
                    local pid = info.pid
                    local grade = info.grade
                    if tHasPlayer[pid] then
                        tResult[grade] = tResult[grade] or {level=grade,rolecnt=0,school1=0,school2=0,school3=0}
                        tResult[grade]["rolecnt"] = tResult[grade]["rolecnt"] + 1
                        iTotal = iTotal + 1
                        local school = tSchool[pid]
                        if school then
                            local sSchool = string.format("school%d",school)
                            tResult[grade][sSchool] = tResult[grade][sSchool] + 1
                        end
                    end
                end
            end
        end
    end

    local tRet = {}
    for grade=1,100 do
        local mUnit = tResult[grade]
        if mUnit then
            mUnit.rate = string.format("%.2f",mUnit.rolecnt/math.max(iTotal,1)*100.0)
            table.insert(tRet,mUnit)
        end
    end
    return {errcode = 0, data = tRet }
end

--设备分布
function CPlayerStatObj:ModelDistribute(mArgs)
    self:PreProcess(mArgs)
    local iStartTime = bkdefines.AnalyTimeStamp(mArgs.startTime)
    local iEndTime = bkdefines.AnalyTimeStamp(mArgs.endTime)
    local iFindStart = bson.date(iStartTime + 6*3600)
    local iFindEnd = bson.date(iEndTime + 30*3600)

    local oBackendObj = global.oBackendObj

    local serverkeys = oBackendObj:GetServerList()
    local tResult = {}
    for sServer,oServer in pairs(serverkeys) do
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        if oGameUmDb then
            local m = oGameUmDb:Find("analy",{
                subtype="loginmodel",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd},platform=mArgs.platformIds,channel=mArgs.channelIds
            },{mlist=true})
            while m:hasNext() do
                local mData = m:next()
                local mlist = mData.mlist or {}
                for _,info in pairs(mlist) do
                    local model = info.model
                    local cnt = info.cnt
                    tResult[model] = tResult[model] or 0
                    tResult[model] = tResult[model] + cnt
                end
            end
        end
    end

    local tRet = {}
    for model,cnt in pairs(tResult) do
        table.insert(tRet,{name=model,totalCount=cnt})
    end

    return {errcode = 0, data = tRet }
end

--流失统计
function CPlayerStatObj:DateLoss(mArgs)
    self:PreProcess(mArgs)
    local iStartTime = bkdefines.AnalyTimeStamp(mArgs.startTime)
    local iEndTime = bkdefines.AnalyTimeStamp(mArgs.endTime)
    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList()
    local tRet = {}
    local tDisDay = {3,7,14}
    for iTime=iStartTime,iEndTime,24*3600 do
        local mUnit = {
            loginCount=0,lossOldCount3=0,lossNewCount3=0,lossOldCount7=0,lossNewCount7=0,
            lossOldCount14=0,lossNewCount14=0,date=bkdefines.FormatTime(iTime)
        }
        local iFindStart = bson.date(iTime+6*3600)
        local iFindEnd = bson.date(iTime+30*3600)
        local tLoginRole,tCreateRole= {},{} --当天登录和创建的账号
        for sServer,oServer in pairs(serverkeys) do
            local oGameUmDb = oServer.m_oGameUmDb:GetDb()
            if oGameUmDb then
                local m = oGameUmDb:Find( "analy",{
                    subtype="loginrole",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd},platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{plist=true})
                while m:hasNext() do
                    local mData = m:next()
                    local plist = mData.plist or {}
                    for _,pid in pairs(plist) do
                        local sPid = string.format("%s-%d",sServer,pid)
                        tLoginRole[sPid] = true
                    end
                end
                local m2 = oGameUmDb:Find( "analy",{
                    subtype="newrole",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd},platform=mArgs.platformIds,channel=mArgs.channelIds
                    },{plist=true})
                while m2:hasNext() do
                    local mData = m2:next()
                    local plist = mData.plist or {}
                    for _,pid in pairs(plist) do
                        local sPid = string.format("%s-%d",sServer,pid)
                        tCreateRole[sPid] = true
                    end
                end
            end
        end
        mUnit.loginCount = table_count(tLoginRole)
        for iNo,iDay in pairs(tDisDay) do
            local iBeforDay = tDisDay[iNo-1] or 1
            local iFindLoginStart = bson.date(iTime+iBeforDay*24*3600+6*3600)
            local iFindLoginEnd = bson.date(iTime+iDay*24*3600+6*3600)
            for sServer,oServer in pairs(serverkeys) do
                local oGameUmDb = oServer.m_oGameUmDb:GetDb()
                if oGameUmDb then
                    local m = oGameUmDb:Find( "analy",
                        {subtype="loginrole",_time = {["$gte"] = iFindLoginStart,["$lt"] = iFindLoginEnd},platform=mArgs.platformIds,channel=mArgs.channelIds
                        },{plist=true})
                    while m:hasNext() do
                        local mData = m:next()
                        local plist = mData.plist or {}
                        for _,pid in pairs(plist) do
                            local sPid = string.format("%s-%d",sServer,pid)
                            tLoginRole[sPid] = nil
                        end
                    end
                end
            end
            for sPid,_ in pairs(tLoginRole) do
                local sOldKey = string.format("lossOldCount%d",iDay)
                local sNewKey = string.format("lossNewCount%d",iDay)
                if tCreateRole[sPid] then
                    mUnit[sNewKey] = mUnit[sNewKey] + 1
                else
                    mUnit[sOldKey] = mUnit[sOldKey] + 1
                end
            end
        end
        mUnit.lossCount3 = mUnit.lossOldCount3 + mUnit.lossNewCount3
        mUnit.lossCount7 = mUnit.lossOldCount7 + mUnit.lossNewCount7
        mUnit.lossCount14 = mUnit.lossOldCount14 + mUnit.lossNewCount14
        table.insert(tRet,mUnit)
    end
    return {errcode = 0, data = tRet}
end

--等级流失
function CPlayerStatObj:LevelLoss(mArgs)
    self:PreProcess(mArgs)
    local iStatType = tonumber(mArgs.statType)
    local iStartTime = bkdefines.AnalyTimeStamp(mArgs.statTime)
    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList()

    local iFindStart = bson.date(iStartTime+6*3600)
    local iFindEnd = bson.date(iStartTime+30*3600)
    local tLoginRole,tGrade,tSchool = {},{},{}
    for sServer,oServer in pairs(serverkeys) do
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        local oGameDb = self:GetServerGameDB(sServer)
        if oGameUmDb and oGameDb then
           local m = oGameUmDb:Find( "analy",{
                subtype="loginrole",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true})
           local tmplist = {}
           while m:hasNext() do
                local mData = m:next()
                local plist = mData.plist or {}
                for _,pid in pairs(plist) do
                    local sPid = string.format("%s-%d",sServer,pid)
                    tLoginRole[sPid] = true
                    table.insert(tmplist,pid)
                end
            end
            local m2 = oGameUmDb:Find( "analy",{
                subtype="upgrade",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true})
            while m2:hasNext() do
                local mData = m2:next()
                local plist = mData.plist or {}
                for _,info in pairs(plist) do
                    local pid,grade = info.pid,info.grade
                    local sPid = string.format("%s-%d",sServer,pid)
                    tGrade[sPid] = grade
                end
            end
            if #tmplist > 0 then
                local m3 = oGameDb:Find("player",{pid={["$in"]=tmplist}}, {pid=true,base_info=true})
                while m3:hasNext() do
                    local mData = m3:next()
                    local pid = mData.pid
                    local base_info = mData.base_info or {}
                    local school = base_info.school
                    local sPid = string.format("%s-%d",sServer,pid)
                    tSchool[sPid] = school
                end
            end
        end
    end

    local iFindLoginStart = bson.date(iStartTime+1*24*3600+6*3600)
    local iFindLoginEnd = bson.date(iStartTime+iStatType*24*3600+6*3600)
    for sServer,oServer in pairs(serverkeys) do
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        if oGameUmDb then
            local m = oGameUmDb:Find( "analy",
                {subtype="loginrole",_time = {["$gte"] = iFindLoginStart,["$lt"] = iFindLoginEnd},platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true})
            while m:hasNext() do
                local mData = m:next()
                local plist = mData.plist or {}
                for _,pid in pairs(plist) do
                    local sPid = string.format("%s-%d",sServer,pid)
                    tLoginRole[sPid] = nil
                    tGrade[sPid] = nil
                    tSchool[sPid] = nil
                end
            end
        end
    end
    local tResult,iLossCnt = {},0
    for sPid,_ in pairs(tLoginRole) do
        local grade = tGrade[sPid] --or 0
        local school = tSchool[sPid] --or 1
        tResult[grade] = tResult[grade] or {lossCount = 0,lossRate = "",school1 = 0,school2 = 0,school3 = 0}
        local sSchKey = string.format("school%d",school)
        tResult[grade][sSchKey] = tResult[grade][sSchKey] + 1
        tResult[grade]["lossCount"] = tResult[grade]["lossCount"] + 1
        iLossCnt = iLossCnt + 1
    end

    local tRet = {}
    local gradelist = table_key_list(tResult)
    table.sort(gradelist)
    for _,level in pairs(gradelist) do
        local mUnit = tResult[level]
        mUnit.level = level
        mUnit.lossRate = string.format("%.2f",mUnit["lossCount"]/math.max(iLossCnt,1)*100.0)
        table.insert(tRet,mUnit)
    end

    return { errcode = 0 , data =  tRet }
end

--创角天数流失
function CPlayerStatObj:createDayLoss(mArgs)
    self:PreProcess(mArgs)
    local iStatType = tonumber(mArgs.statType)
    local iStartTime = bkdefines.AnalyTimeStamp(mArgs.statTime)
    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList()

    local iFindStart = bson.date(iStartTime+6*3600)
    local iFindEnd = bson.date(iStartTime+30*3600)
    local tLoginRole,tCreateTime = {},{}
    for sServer,oServer in pairs(serverkeys) do
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        local oGameDb = self:GetServerGameDB(sServer)
        if oGameUmDb and oGameDb then
            local m = oGameUmDb:Find( "analy",{
                subtype="loginrole",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd},platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true}
            )
            local tmplist = {}
            while m:hasNext() do
                local mData = m:next()
                local plist = mData.plist or {}
                for _,pid in pairs(plist) do
                    local sPid = string.format("%s-%d",sServer,pid)
                    tLoginRole[sPid] = true
                    table.insert(tmplist,pid)
                end
            end
            if #tmplist > 0 then
                local m3 = oGameDb:Find("player",{pid={["$in"]=tmplist}}, {pid=true,base_info=true})
                while m3:hasNext() do
                    local mData = m3:next()
                    local pid = mData.pid
                    local base_info = mData.base_info or {}
                    local create_time = base_info.create_time
                    local sPid = string.format("%s-%d",sServer,pid)
                    tCreateTime[sPid] = create_time
                end
            end
        end
    end

    local iFindLoginStart = bson.date(iStartTime+1*24*3600+6*3600)
    local iFindLoginEnd = bson.date(iStartTime+iStatType*24*3600+6*3600)
    for sServer,oServer in pairs(serverkeys) do
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        if oGameUmDb then
            local m = oGameUmDb:Find( "analy",
                {subtype="loginrole",_time = {["$gte"] = iFindLoginStart,["$lt"] = iFindLoginEnd},platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true})
            while m:hasNext() do
                local mData = m:next()
                local plist = mData.plist or {}
                for _,pid in pairs(plist) do
                    local sPid = string.format("%s-%d",sServer,pid)
                    tLoginRole[sPid] = nil
                    tCreateTime[sPid] = nil
                end
            end
        end
    end

    local tResult,iTotal = {},0
    for sPid,_ in pairs(tLoginRole) do
        if tCreateTime[sPid] then
            local time = math.min(tCreateTime[sPid],iStartTime)
            local iDay = math.ceil( (iStartTime - time) // (24*3600) + 1 )
            tResult[iDay] = tResult[iDay] or 0
            tResult[iDay] = tResult[iDay] + 1
            iTotal = iTotal + 1
        end
    end

    iTotal = math.max(iTotal,1)
    local tRet = {}
    local daylist = table_key_list(tResult)
    table.sort(daylist)
    for _,day in pairs(daylist) do
        if tResult[day] then
            local mUnit = {day = day, lossCount = tResult[day], lossRate = string.format("%.2f",tResult[day]/iTotal*100.0) }
            table.insert(tRet,mUnit)
        end
    end
    return { errcode = 0 , data =  tRet }
end

--任务流失
function CPlayerStatObj:missionLoss(mArgs)
    self:PreProcess(mArgs)
    local iStatType = tonumber(mArgs.statType)
    local iStartTime = bkdefines.AnalyTimeStamp(mArgs.statTime)
    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList()

    local iFindStart = bson.date(iStartTime+6*3600)
    local iFindEnd = bson.date(iStartTime+30*3600)
    local tLoginRole,tTask = {},{}
    for sServer,oServer in pairs(serverkeys) do
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        local oGameDb = self:GetServerGameDB(sServer)
        if oGameUmDb and oGameDb then
            local m = oGameUmDb:Find( "analy",{
                subtype="loginrole",_time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true}
            )
            while m:hasNext() do
                local mData = m:next()
                local plist = mData.plist or {}
                for _,pid in pairs(plist) do
                    local sPid = string.format("%s-%d",sServer,pid)
                    tLoginRole[sPid] = true
                end
            end
            local m2 =oGameUmDb:Find("analy",{
                subtype="storytask", _time = {["$gte"] = iFindStart,["$lt"] = iFindEnd} ,platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true})
             while m2:hasNext() do
                local mData = m2:next()
                local plist = mData.plist or {}
                for _,info in pairs(plist) do
                    local taskid = info.taskid
                    local pid = info.pid
                    local sPid = string.format("%s-%d",sServer,pid)
                    tTask[sPid] = taskid
                end
            end
        end
    end

    local iFindLoginStart = bson.date(iStartTime+1*24*3600+6*3600)
    local iFindLoginEnd = bson.date(iStartTime+iStatType*24*3600+6*3600)
    for sServer,oServer in pairs(serverkeys) do
        local oGameUmDb = oServer.m_oGameUmDb:GetDb()
        if oGameUmDb then
            local m = oGameUmDb:Find( "analy",
                {subtype="loginrole",_time = {["$gte"] = iFindLoginStart,["$lt"] = iFindLoginEnd},platform=mArgs.platformIds,channel=mArgs.channelIds
                },{plist=true})
            while m:hasNext() do
                local mData = m:next()
                local plist = mData.plist or {}
                for _,pid in pairs(plist) do
                    local sPid = string.format("%s-%d",sServer,pid)
                    tLoginRole[sPid] = nil
                    tTask[sPid] = nil
                end
            end
        end
    end

    local iTotal,tResult = 0,{}
    for sPid,_ in pairs(tLoginRole) do
        local taskid = tTask[sPid] or 10001 --(10000 + math.random(6))
        tResult[taskid] = tResult[taskid] or 0
        tResult[taskid] = tResult[taskid] + 1
        iTotal = iTotal + 1
    end
    iTotal = math.max(iTotal,1)
    local tRet = {}
    local tasklist = table_key_list(tResult)
    table.sort(tasklist)
    for _,taskid in pairs(tasklist) do
        if tResult[taskid] and taskid ~= 0 then
            local mUnit = {
                missionId = taskid, missionName=self:GetTaskName(taskid) ,
                count = tResult[taskid], rate = string.format("%.2f",tResult[taskid]/iTotal*100.0)
            }
            table.insert(tRet,mUnit)
        end
    end

    return { errcode = 0 , data = tRet }
end

function CPlayerStatObj:GetTaskName(taskid)
    if not res["daobiao"]["task"]["story"]["task"][taskid] then
        return string.format("未知任务%d",taskid)
    end
    return res["daobiao"]["task"]["story"]["task"][taskid]["name"]
end