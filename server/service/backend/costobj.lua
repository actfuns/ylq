--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"
local extend = require "base.extend"
local bson = require "bson"
local utf8 = require "utf8"
local mongoop = require "base.mongoop"
local gamedefines = import(lualib_path("public.gamedefines"))

function NewCostObj(...)
    local o = CCostObj:New(...)
    return o
end

CCostObj = {}
CCostObj.__index = CCostObj

function CCostObj:New()
    local o = setmetatable({}, self)
    return o
end

function CCostObj:Init()
end

function CCostObj:GetServerGameDB(sServer)
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj.m_mServers[sServer]
    if not oServer then
        return
    end
    return oServer.m_oGameDb:GetDb()
end

function CCostObj:GetServerGameLogDB(sServer,iYear, iMonth)
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj.m_mServers[sServer]
    if not oServer then
        return
    end
    return oServer.m_oGameLogDb:GetDb(iYear, iMonth)
end

function CCostObj:CountProSale(mAdd,mSub,mRest,mArgs)
    mAdd = mAdd or {}
    mSub = mSub or {}
    local tResult = {}
    for _,info in pairs(mAdd) do
        local _,time = bson.type(info._time)
        time = TimeKey(time)
        tResult[time] = tResult[time] or {product=0,consume=0,inventory=0}

        for _,sAttr in pairs(mArgs.add) do
            tResult[time]["product"] = tResult[time]["product"] + (info[sAttr] or 0)
        end
    end
    for _,info in pairs(mSub) do
        local _,time = bson.type(info._time)
        time = TimeKey(time)
        tResult[time] = tResult[time] or {product=0,consume=0,inventory=0}
        for _,sAttr in pairs(mArgs.sub) do
            tResult[time]["consume"] = tResult[time]["consume"] + (info[sAttr] or 0)
        end
    end
    for _,info in pairs(mRest) do
        local _,time = bson.type(info._time)
        time = TimeKey(time)
        tResult[time] = tResult[time] or {product=0,consume=0,inventory=0}
        tResult[time]["inventory"] = tResult[time]["inventory"] + (tonumber(info["value"]) or 0)
    end

    return tResult
end

function CCostObj:ProSaleUnit(mAdd,mSub,mRest,mArgs)
    mAdd = mAdd or {}
    mSub = mSub or {}
    local tResult,tPlayerVisit,tPlayerVisit2 = {},{},{}
    for _,info in pairs(mSub) do
        local _,time = bson.type(info._time)
        time = TimeKey(time)
        local pid = info.pid
        local reason = info.reason or "未知原因"
        tPlayerVisit[time] = tPlayerVisit[time] or {}
        tResult[time] = tResult[time] or {}
        tResult[time][reason] = tResult[time][reason] or {product=0,consume=0,crolecnt=0,prolecnt=0}
        for _,sAttr in pairs(mArgs.sub) do
            tResult[time][reason]["consume"] = tResult[time][reason]["consume"] + (info[sAttr] or 0)
        end
        if not tPlayerVisit[time][pid] then
            tPlayerVisit[time][pid] = true
            tResult[time][reason]["crolecnt"] = tResult[time][reason]["crolecnt"] + 1
        end
    end
    for _,info in pairs(mAdd) do
        local _,time = bson.type(info._time)
        time = TimeKey(time)
        local pid = info.pid
        local reason = info.reason or "未知原因"
        tPlayerVisit2[time] = tPlayerVisit2[time] or {}
        tResult[time] = tResult[time] or {}
        tResult[time][reason] = tResult[time][reason] or {product=0,consume=0,crolecnt=0,prolecnt=0}
        for _,sAttr in pairs(mArgs.add) do
            tResult[time][reason]["product"] = tResult[time][reason]["product"] + (info[sAttr] or 0)
        end
        if not tPlayerVisit2[time][pid] then
            tPlayerVisit2[time][pid] = true
            tResult[time][reason]["prolecnt"] = tResult[time][reason]["prolecnt"] + 1
        end
    end
    return tResult
end

function CCostObj:ConsumeRoleRank(mAdd,mSub,mRest,mArgs)
    mAdd = mAdd or {}
    mSub = mSub or {}
    local tResult = {}
    for _,info in pairs(mSub) do
        local _,time = bson.type(info._time)
        local time2 = TimeKey(time)
        local pid,name,grade = info.pid,info.name,info.grade
        tResult[time2] = tResult[time2] or {}
        tResult[time2][pid] = tResult[time2][pid] or {time=0,name="",grade=0,consume=0,product=0}
        for _,sAttr in pairs(mArgs.sub) do
            tResult[time2][pid]["consume"] = tResult[time2][pid]["consume"] + (info[sAttr] or 0)
        end
        if time > tResult[time2][pid]["time"] then
            tResult[time2][pid]["time"] = time
            tResult[time2][pid]["name"] = name
            tResult[time2][pid]["grade"] = grade
        end
    end
    for _,info in pairs(mAdd) do
        local _,time = bson.type(info._time)
        local time2 = TimeKey(time)
        local pid,name,grade = info.pid,info.name,info.grade
        tResult[time2] = tResult[time2] or {}
        tResult[time2][pid] = tResult[time2][pid] or {time=0,name="",grade=0,consume=0,product=0}
        for _,sAttr in pairs(mArgs.add) do
            tResult[time2][pid]["product"] = tResult[time2][pid]["product"] + (info[sAttr] or 0)
        end
        if time > tResult[time2][pid]["time"] then
            tResult[time2][pid]["time"] = time
            tResult[time2][pid]["name"] = name
            tResult[time2][pid]["grade"] = grade
        end
    end
    return tResult
end

function CCostObj:ProSaleGrade(mAdd,mSub,mRest,mArgs)
    mAdd = mAdd or {}
    mSub = mSub or {}
    local tResult = {}
    for _,info in pairs(mAdd) do
        local _,time = bson.type(info._time)
        local time2 = TimeKey(time)
        local grade = info.grade // 10 * 10
        tResult[time2] = tResult[time2] or {}
        tResult[time2][grade] = tResult[time2][grade] or {earn=0,consume=0,store=0}
        for _,sAttr in pairs(mArgs.add) do
            tResult[time2][grade]["earn"] = tResult[time2][grade]["earn"] + (info[sAttr] or 0)
        end
    end
    for _,info in pairs(mSub) do
        local _,time = bson.type(info._time)
        local time2 = TimeKey(time)
        local grade = info.grade // 10 * 10
        tResult[time2] = tResult[time2] or {}
        tResult[time2][grade] = tResult[time2][grade] or {earn=0,consume=0,store=0}
        for _,sAttr in pairs(mArgs.sub) do
            tResult[time2][grade]["consume"] = tResult[time2][grade]["consume"] + (info[sAttr] or 0)
        end
    end
    for _,info in pairs(mRest) do
        local _,time = bson.type(info._time)
        local time2 = TimeKey(time)
        local grade = info.grade // 10 * 10
        tResult[time2] = tResult[time2] or {}
        tResult[time2][grade] = tResult[time2][grade] or {earn=0,consume=0,store=0}
        tResult[time2][grade]["store"] = tResult[time2][grade]["store"] + (tonumber(info["value"]) or 0)
    end
    return tResult
end

function CCostObj:MoneyRest(mAdd,mSub,mRest,mArgs)
    local tResult = {}
    local fieldname = mArgs.fieldname or "value"
    for _,info in pairs(mRest) do
        local _,time = bson.type(info._time)
        local time2 = TimeKey(time)
        tResult[time2] = tResult[time2] or {[fieldname]=0}
        tResult[time2][fieldname] = tResult[time2][fieldname] + tonumber(info["value"] or 0)
    end
    return tResult
end

function CCostObj:GetFindLogCondition(iMoneyType,sLogType)
    if iMoneyType == gamedefines.MONEY_TYPE.GOLD then
        if sLogType == "add" then
            local sSubType = "add_gold"
            local tNeed = {pid=true,name=true,grade=true,gold_add=true,gold_now=true,gold_over_now=true,
            reason=true,_time=true,gold_over_old = true
            }
            local tAdd = {"gold_add","gold_over_now"}
            return sSubType,tNeed,tAdd
        elseif sLogType == "sub" then
            local sSubType = "sub_gold"
            local tNeed = {
                pid=true,name=true,grade=true,gold_sub=true,gold_now=true,gold_over_now=true,reason=true,
                _time=true,gold_over_old = true
            }
            local tSub =  {"gold_sub"}
            return sSubType,tNeed,tSub
        elseif sLogType == "rest" then
            local sSubType = "rest_gold"
            local tNeed = {server=true,grade=true,value=true,_time=true}
            return sSubType,tNeed
        end
    elseif iMoneyType == gamedefines.MONEY_TYPE.SILVER then
        if sLogType == "add" then
            local sSubType = "add_silver"
            local tNeed = {pid=true,name=true,grade=true,silver_add=true,silver_now=true,silver_over_now=true,
            reason=true,_time=true,silver_over_old = true
            }
            local tAdd = {"silver_add","silver_over_now"}
            return sSubType,tNeed,tAdd
        elseif sLogType == "sub" then
            local sSubType = "sub_silver"
            local tNeed = {pid=true,name=true,grade=true,silver_sub=true,silver_now=true,silver_over_now=true,
            reason=true,_time=true,silver_over_old = true
            }
            local tSub =  {"silver_sub"}
            return sSubType,tNeed,tSub
        elseif sLogType == "rest" then
            local sSubType = "rest_silver"
            local tNeed = {server=true,grade=true,value=true,_time=true}
            return sSubType,tNeed
        end
    elseif iMoneyType == gamedefines.MONEY_TYPE.GOLDCOIN then
        if sLogType == "add" then
            local sSubType = "add_goldcoin"
            local tNeed = {pid=true,name=true,grade=true,goldcoin_add=true,goldcoin_old=true,goldcoin_now=true,
            reason=true,_time=true
            }
            local tAdd = {"goldcoin_add"}
            return sSubType,tNeed,tAdd
        elseif sLogType == "sub" then
            local sSubType = "sub_goldcoin"
            local tNeed = {pid=true,name=true,grade=true,goldcoin_sub=true,
            rplgoldcoin_sub=true,reason=true,_time=true
            }
            local tSub =  {"goldcoin_sub","rplgoldcoin_sub"}
            return sSubType,tNeed,tSub
        elseif sLogType == "rest" then
            local sSubType = "rest_goldcoin"
            local tNeed = {server=true,grade=true,value=true,_time=true}
            return sSubType,tNeed
        end
    elseif iMoneyType == gamedefines.MONEY_TYPE.RPLGOLD then
        if sLogType == "add" then
            local sSubType = "add_rplgoldcoin"
            local tNeed = {pid=true,name=true,grade=true,rplgoldcoin_add=true,
            reason=true,_time=true
            }
            local tAdd = {"rplgoldcoin_add"}
            return sSubType,tNeed,tAdd
        end
    end
end

function CCostObj:ArrangeData(sServer,iYear,iMonth,sType,mArgs)
    mArgs = mArgs or {}

    local currencyType = mArgs.currencyType
    local oGameLogDb = self:GetServerGameLogDB(sServer,iYear,iMonth)
    if not oGameLogDb then
        return {}
    end
    local tNeed,sSubType
    local mAdd,mSub,mRest = {},{},{}
    if mArgs.needadd then
        sSubType,tNeed,mArgs.add = self:GetFindLogCondition(currencyType,"add")
        local m = oGameLogDb:Find("money", {subtype=sSubType}, tNeed)
        while m:hasNext() do
            local mRet = m:next()
            mongoop.ChangeAfterLoad(mRet)
            table.insert(mAdd, mRet)
        end
        if currencyType == gamedefines.MONEY_TYPE.GOLDCOIN then
            local sSubType2,tNeed2,tAdd2 = self:GetFindLogCondition(gamedefines.MONEY_TYPE.RPLGOLD,"add")
            local m2 = oGameLogDb:Find("money", {subtype=sSubType2}, tNeed2)
            while m2:hasNext() do
                table.insert(mAdd, m2:next())
            end
            list_combine(mArgs.add,tAdd2)
        end
    end

    if mArgs.needsub then
        sSubType,tNeed,mArgs.sub = self:GetFindLogCondition(currencyType,"sub")
        local m = oGameLogDb:Find("money", {subtype=sSubType}, tNeed)
        while m:hasNext() do
            table.insert(mSub, m:next())
        end
    end

    if mArgs.needrest then
        sSubType,tNeed = self:GetFindLogCondition(currencyType,"rest")
        local oLocalGameLogDb = self:GetServerGameLogDB(1,iYear,iMonth)
        local m = oLocalGameLogDb:Find("costcount",{subtype=sSubType,server=sServer},tNeed)
        while m:hasNext() do
            table.insert(mRest, m:next())
        end
    end

    --产销统计
    if sType == "prosale" then
        return self:CountProSale(mAdd,mSub,mRest,mArgs)
    --产销项目
    elseif sType == "prosaleunit" then
        return self:ProSaleUnit(mAdd,mSub,mRest,mArgs)
    --消费角色排行
    elseif sType == "rolerank" then
        return self:ConsumeRoleRank(mAdd,mSub,mRest,mArgs)
    --产销等级分布
    elseif sType == "prosalegrade" then
        return self:ProSaleGrade(mAdd,mSub,mRest,mArgs)
    --货币余量
    elseif sType == "moneyrest" then
        return self:MoneyRest(mAdd,mSub,mRest,mArgs)
    end
end

function CCostObj:PostCostInfo(mArgs)
    local sType = mArgs.sType
    if sType == "prosale" then
        return self:CountProSaleShow(mArgs)
    elseif sType == "prosaleunit" then
        return self:ProSaleUnitShow(mArgs)
    elseif sType == "rolerank" then
        return self:RoleRankShow(mArgs)
    elseif sType == "prosalegrade" then
        return self:ProSaleGradeShow(mArgs)
    elseif sType == "moneyrest" then
        return self:MoneyRestShow(mArgs)
    end
    return {errcode = 1}
end

function CCostObj:CountProSaleShow(mArgs)
    local sServer = "1"
    local sType,currencyType,startTime,endTime = mArgs.sType,mArgs.currencyType,mArgs.startTime,mArgs.endTime
    local startyear,startmonth,startday = AnalyTime(startTime)
    local endyear,endmonth,endday = AnalyTime(endTime)
    mArgs = {needadd=true,needsub=true,needrest=true}
    mArgs.currencyType = currencyType
    local tShow = {errcode=0,data={}}
    local tResult = {}
    for iYear=startyear,endyear do
        local iDown,iUp = 1,12
        if iYear == startyear then
            iDown = startmonth
        end
        if iYear == endyear then
            iUp = endmonth
        end
        for iMonth=iDown,iUp do
            local tTmp = self:ArrangeData(sServer,iYear,iMonth,sType,mArgs)
            tResult = table_combine(tResult,tTmp)
        end
    end

    local sMoneyName = GetMoneyName(currencyType)
    local iStartTime = os.time({year = startyear,month = startmonth,day = startday,hour=0,min=0,sec=0})
    local iEndTime = os.time({year = endyear,month = endmonth,day = endday,hour=23,min=59,sec=59})

    for iTime=iStartTime,iEndTime,24*3600 do
        if tResult[iTime] then
            local info = tResult[iTime]
            table.insert(tShow.data,{
                date=FormatTime(iTime),currencyTypeName=sMoneyName,
                income=info.product,outgo=info.consume,
                inventory=info.inventory,
            })
        end
    end
    return tShow
end

function CCostObj:ProSaleUnitShow(mArgs)
    local sServer = "1"
    local sType,currencyType,startTime,endTime = mArgs.sType,mArgs.cType,mArgs.startTime,mArgs.endTime
    local startyear,startmonth,startday = AnalyTime(startTime)
    local endyear,endmonth,endday = AnalyTime(endTime)
    local isConsume = mArgs.inOrOut
    mArgs = {}
    mArgs.currencyType = currencyType
    if isConsume == 1 then
        mArgs.needsub = true
    else
        mArgs.needadd = true
    end
    local tShow = {errcode=0,data={}}
    local tResult = {}
    for iYear=startyear,endyear do
        local iDown,iUp = 1,12
        if iYear == startyear then
            iDown = startmonth
        end
        if iYear == endyear then
            iUp = endmonth
        end
        for iMonth=iDown,iUp do
            local tTmp = self:ArrangeData(sServer,iYear,iMonth,sType,mArgs)
            tResult = table_combine(tResult,tTmp)
        end
    end

    local iStartTime = os.time({year = startyear,month = startmonth,day = startday,hour=0,min=0,sec=0})
    local iEndTime = os.time({year = endyear,month = endmonth,day = endday,hour=23,min=59,sec=59})

    local sMoneyName = GetMoneyName(currencyType)
    local tTmp = {}
    for iTime=iStartTime,iEndTime,24*3600 do
        if tResult[iTime] then
            for reason,info in pairs(tResult[iTime]) do
                local sumNum,ct = 0,0
                if isConsume == 1 then
                    sumNum = info.consume
                    ct=info.crolecnt
                else
                    sumNum = info.product
                    ct=info.prolecnt
                end
                if sumNum > 0 then
                    tTmp[reason] = tTmp[reason] or {sumNum=0,ct=0}
                    tTmp[reason]["sumNum"] = tTmp[reason]["sumNum"] + sumNum
                    tTmp[reason]["ct"] = tTmp[reason]["ct"] + ct
                end
            end
        end
    end
    for reason,info in pairs(tTmp) do
        table.insert(tShow.data,{
            currencyType=currencyType,currencyTypeName=sMoneyName,
            traceTypeName=reason,sumNum=info.sumNum,ct=info.ct
        })
    end

    table.sort(tShow.data,function (a,b)
        return a.sumNum > b.sumNum
    end)

    return tShow
end

function CCostObj:RoleRankShow(mArgs)
    local sServer = "1"
    local sType,currencyType,startTime,endTime = mArgs.sType,mArgs.cType,mArgs.startTime,mArgs.endTime
    local isConsume = mArgs.inOrOut
    local startyear,startmonth,startday = AnalyTime(startTime)
    local endyear,endmonth,endday = AnalyTime(endTime)
    mArgs = {}
    mArgs.currencyType = currencyType
    if isConsume == 1 then
        mArgs.needsub = true
    else
        mArgs.needadd = true
    end
    local tShow = {errcode=0,data={}}
    local tResult = {}
    for iYear=startyear,endyear do
        local iDown,iUp = 1,12
        if iYear == startyear then
            iDown = startmonth
        end
        if iYear == endyear then
            iUp = endmonth
        end
        for iMonth=iDown,iUp do
            local tTmp = self:ArrangeData(sServer,iYear,iMonth,sType,mArgs)
            tResult = table_combine(tResult,tTmp)
        end
    end

    local iStartTime = os.time({year = startyear,month = startmonth,day = startday,hour=0,min=0,sec=0})
    local iEndTime = os.time({year = endyear,month = endmonth,day = endday,hour=23,min=59,sec=59})

    local sMoneyName = GetMoneyName(currencyType)
    local tTmp = {}
    for iTime=iStartTime,iEndTime,24*3600 do
        if tResult[iTime] then
            for pid,info in pairs(tResult[iTime]) do
                tTmp[pid] = tTmp[pid] or {currencyCount=0}
                tTmp[pid]["name"] = info.name
                tTmp[pid]["grade"] = info.grade
                if isConsume == 1 then
                    tTmp[pid]["currencyCount"] = tTmp[pid]["currencyCount"] + info.consume
                else
                    tTmp[pid]["currencyCount"] = tTmp[pid]["currencyCount"] + info.product
                end
            end
        end
    end

    for pid,info in pairs(tTmp) do
        if info.currencyCount > 0 then
            table.insert(tShow.data,{channel="苹果",server="开发服",
                accountId = tostring(pid), playerId = tostring(pid), nickName = info.name,
                level = info.grade , currnecyTypeName = sMoneyName , currencyCount = tostring(info.currencyCount),
                sumNum = info.currencyCount,
            })
        end
    end

    table.sort(tShow.data,function (a,b)
        return a.sumNum > b.sumNum
    end)

    return tShow
end

function CCostObj:ProSaleGradeShow(mArgs)
    local sServer = "1"
    local sType,currencyType,startTime,endTime = mArgs.sType,mArgs.currencyType,mArgs.startTime,mArgs.endTime
    local startyear,startmonth,startday = AnalyTime(startTime)
    local endyear,endmonth,endday = AnalyTime(endTime)
    mArgs = {needadd=true,needsub=true,needrest=true}
    mArgs.currencyType = currencyType
    local tShow = {errcode=0,data={}}
    local tResult = {}
    for iYear=startyear,endyear do
        local iDown,iUp = 1,12
        if iYear == startyear then
            iDown = startmonth
        end
        if iYear == endyear then
            iUp = endmonth
        end
        for iMonth=iDown,iUp do
            local tTmp = self:ArrangeData(sServer,iYear,iMonth,sType,mArgs)
            tResult = table_combine(tResult,tTmp)
        end
    end

    local iStartTime = os.time({year = startyear,month = startmonth,day = startday,hour=0,min=0,sec=0})
    local iEndTime = os.time({year = endyear,month = endmonth,day = endday,hour=23,min=59,sec=59})

    local tTmp = {}

    for iTime=iStartTime,iEndTime,24*3600 do
        if tResult[iTime] then
            for grade = 10,120,10 do
                if tResult[iTime][grade] then
                    local info = tResult[iTime][grade]
                    table.insert(tShow.data,{statDate=FormatTime(iTime),serverId=sServer,channelId="德米",
                       dataId = grade, spend = info.consume , earn = info.earn, store = info.store,
                    })
                end
            end
        end
    end

    return tShow
end

function CCostObj:MoneyRestShow(mArgs)
    local sServer = "1"
    local sType,startTime,endTime = mArgs.sType,mArgs.startTime,mArgs.endTime
    mArgs = {needrest=true}
    local startyear,startmonth,startday = AnalyTime(startTime)
    local endyear,endmonth,endday = AnalyTime(endTime)
    local tShow = {errcode=0,data={}}
    local tResult = {}
    for iYear=startyear,endyear do
        local iDown,iUp = 1,12
        if iYear == startyear then
            iDown = startmonth
        end
        if iYear == endyear then
            iUp = endmonth
        end
        for iMonth=iDown,iUp do
            local tTmp = {}
            for currencyType=1,3 do
                local sAttr = GetMoneyAttr(currencyType)
                mArgs.currencyType = currencyType
                mArgs.fieldname = sAttr
                local tTmp2 = self:ArrangeData(sServer,iYear,iMonth,sType,mArgs)
                for key,info in pairs(tTmp2) do
                    tTmp[key] = tTmp[key] or {goldcoin=0,silver=0,gold=0}
                    tTmp[key][sAttr] = tTmp[key][sAttr] + (info[sAttr] or 0)
                end
            end
            tResult = table_combine(tResult,tTmp)
        end
    end


    local iStartTime = os.time({year = startyear,month = startmonth,day = startday,hour=0,min=0,sec=0})
    local iEndTime = os.time({year = endyear,month = endmonth,day = endday,hour=23,min=59,sec=59})

    local tTmp = {}

    for iTime=iStartTime,iEndTime,24*3600 do
        if tResult[iTime] then
            local info = tResult[iTime]
            table.insert(tShow.data,{
                statDate=FormatTime(iTime),serverId="开发服",channelId="德米",
                loginPlayer=0,loginPayPlayer=0,totalPayPlayer=0,
                payPlayerCopper="0",payPlayerSilver="0",payPlayerIngot="0",
                loginPlayerCopper=tonumber(info.goldcoin),loginPlayerSilver=tonumber(info.silver),
                loginPlayerIngot=tonumber(info.gold),
            })
        end
    end

    return tShow
end

function CCostObj:NewHour(iDay, iHour)
    if iHour == 23 then
        self:LogPlayerMoneyRest()
    end
end

function CCostObj:LogPlayerMoneyRest()
    local sServer = "1"
    local oGameDb = self:GetServerGameDB(1)
    if not oGameDb then
        return
    end
    local m = oGameDb:Find("player",{},{pid=true,active_info=true,base_info=true})
    local tResult = {}
    while m:hasNext() do
        local mData = m:next()
        mongoop.ChangeAfterLoad(mData)
        table.insert(tResult, mData)
    end
    local tGradeGold = {}
    local tGradeSilver = {}
    for _,info in pairs(tResult) do
        if info.base_info and info.active_info then
            local grade = info.base_info.grade
            grade = grade // 10 * 10
            local nowgold = 0
            nowgold = nowgold + (info.active_info.gold or 0)
            nowgold = nowgold + (info.active_info.gold_over or 0)
            tGradeGold[grade] = tGradeGold[grade] or 0
            tGradeGold[grade] = tGradeGold[grade] + nowgold

            local nowsilver = 0
            nowsilver = nowsilver + (info.active_info.silver or 0)
            nowsilver = nowsilver + (info.active_info.silver_over or 0)
            tGradeSilver[grade] = tGradeSilver[grade] or 0
            tGradeSilver[grade] = tGradeSilver[grade] + nowsilver
        end
    end

    for grade,value in pairs(tGradeGold) do
        if value > 0 then
            record.log_db("costcount","rest_gold",{server=sServer,grade=grade,value=db_key(value)})
        end
    end
    for grade,value in pairs(tGradeSilver) do
        if value > 0 then
            record.log_db("costcount","rest_silver",{server=sServer,grade=grade,value=db_key(value)})
        end
    end

    m = oGameDb:Find("offline",{},{profile_info = true})
    local tResult = {}
    while m:hasNext() do
        local mRet = m:next()
        mongoop.ChangeAfterLoad(mRet)
        table.insert(tResult, mRet)
    end

    local tGradeGoldCoin = {}
    for _,info in pairs(tResult) do
        if info.profile_info then
            local grade = info.profile_info.grade
            grade = grade // 10 * 10
            tGradeGoldCoin[grade] = tGradeGoldCoin[grade] or 0
            tGradeGoldCoin[grade] = tGradeGoldCoin[grade] + (info.profile_info.GoldCoin or 0)
            tGradeGoldCoin[grade] = tGradeGoldCoin[grade] + (info.profile_info.RplGoldCoin or 0)
        end
    end
    for grade,value in pairs(tGradeGoldCoin) do
        if value > 0 then
            record.log_db("costcount","rest_goldcoin",{server=sServer,grade=grade,value=db_key(value)})
        end
    end
end

MONEY_ATTR = {
    "gold","silver","goldcoin"
}

function GetMoneyAttr(iType)
    return MONEY_ATTR[iType]
end

MONEY_NAME={
    "金币","银币","元宝"
}

function GetMoneyName(iType)
    return MONEY_NAME[iType]
end

function AnalyTime(sTime)
    local year,month,day = string.match(sTime,"(%d+)-(%d+)-(%d+)")
    year,month,day = tonumber(year),tonumber(month),tonumber(day)
    return year,month,day
end

function FormatTime(iTime)
    local m = os.date("*t", iTime)
    return string.format("%04d-%02d-%02d",m.year,m.month,m.day)
end

function TimeKey(time)
    local m = os.date("*t", time)
    local time2 = time - (m.hour*3600+m.min*60+m.sec)
    return time2
end