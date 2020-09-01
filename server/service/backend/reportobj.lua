--import module
local global = require "global"
local skynet = require "skynet"
local bson = require "bson"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"
local record = require "public.record"
local router = require "base.router"
local extend = require "base.extend"

local bkdefines = import(service_path("bkdefines"))

local sReportTableName = "report"
local Handle2Name = {
    banloginact = "封禁",
    banloginrole = "封禁",
    banchatact = "禁言",
    banchatrole = "禁言",
    cancelbanact = "解禁",
    cancelbanrole = "解禁",
    rename = "强制改名",
}

function NewReportObj(...)
    local o = CReportObj:New(...)
    return o
end

local REPORT_TYPE = {
    UNTREATED = 1, -- 未处理
    WAITTREATED = 2, -- 待处理
    DONETREATED = 3, -- 已处理
    MALICE = 4, -- 恶意举报
}

CReportObj = {}
CReportObj.__index = CReportObj
inherit(CReportObj, logic_base_cls())

function CReportObj:New()
    local o = super(CReportObj).New(self)
    o.m_iNowId = 0
    o.m_BlackCnt = {}

    o.m_lContent = {}
    o.m_lSortIDList = {}
    return o
end

function CReportObj:Schedule()
    local f1
    f1 = function ()
        self:DelTimeCb("ClearOverTime")
        self:AddTimeCb("ClearOverTime", 50*60*1000 , f1)
        self:ClearOverTime()
        self:ClearOverTime2()
    end
    f1()
end

function CReportObj:ClearOverTime()
    local mList = self.m_lSortIDList
    local mContent = self.m_lContent
    local iNowTime = get_time()
    local iOverTime = 7*24*60*60
    local mDel = {}
    local mRest = {}
    for _,sID in ipairs(mList) do
        local mUnit = mContent[sID]
        if mUnit then
            if iNowTime > mUnit.ptime + iOverTime then
                table.insert(mDel,sID)
            else
                table.insert(mRest,sID)
            end
        end
    end
    local oDbObj = self:GetDbObj()
    for _,sID in ipairs(mDel) do
        mContent[sID] = nil
        oDbObj:Delete(sReportTableName, {id = sID})
    end
    self.m_lSortIDList = mRest
end

function CReportObj:GetDbObj()
    local oBackendObj = global.oBackendObj
    return oBackendObj.m_oBackendDb
end

function CReportObj:LoadDb()
    local iDayNo = get_dayno()
    local oDbObj = self:GetDbObj()
    local m = oDbObj:Find(sReportTableName, {})
    while m:hasNext() do
        local mUnit = m:next()
        mongoop.ChangeAfterLoad(mUnit)
        self:LoadUnit(mUnit,iDayNo)
    end
    self:InitData()
end

function CReportObj:LoadUnit(mUnit,iDayNo)
    local id = mUnit.id
    if id then
        local _,ptime = bson.type(mUnit.ntime)
        mUnit._id = nil
        mUnit.ntime = nil
        mUnit.ptime = ptime
        self.m_lContent[id] = mUnit
        self.m_BlackCnt[mUnit.target] = self.m_BlackCnt[mUnit.target] or 0
        self.m_BlackCnt[mUnit.target] = self.m_BlackCnt[mUnit.target] + 1
        local iDayNo2,iID = string.match(id,"(%d+)-(%d+)")
        iDayNo2 = tonumber(iDayNo2)
        iID = tonumber(iID)
        if iDayNo == iDayNo2 then
            self.m_iNowId = math.max(self.m_iNowId,iID)
        end
        table.insert(self.m_lSortIDList,id)
    end
end

function CReportObj:InitData()
    self.m_BanLoginAct = {}
    self.m_BanLoginRole = {}
    self.m_BanChatAct = {}
    self.m_BanChatRole = {}
    local mContent = self.m_lContent
    table.sort(self.m_lSortIDList,function (a,b)
        local mUnitA = mContent[a]
        local mUnitB = mContent[b]
        return mUnitA.ptime < mUnitB.ptime
    end)
end

function CReportObj:GenReportId()
    local iDayNo = get_dayno()
    self.m_iNowId = self.m_iNowId + 1
    return string.format("%d-%d",iDayNo,self.m_iNowId)
end

function CReportObj:GetUnitSave(mData)
    local mUnit = {
            serverkey = mData.serverkey,
            type = mData.type,
            account = mData.account,
            pid = mData.pid,
            target = mData.target,
            t_account = mData.t_account,
            reason = mData.reason,
            other = mData.other,
            ntime = bson.date(mData.ptime),
            gm = mData.gm,
            tname = mData.tname,
            name = mData.name,
            detail = mData.detail or "无",
            charge = mData.charge,
    }
    mongoop.ChangeBeforeSave(mUnit)
    return mUnit
end

function CReportObj:AddNewReport(mList)
    local oDbObj = self:GetDbObj()
    local mIDList = {}
    for _,mData in pairs(mList) do
        local id = self:GenReportId()
        mData.id = id
        mData.type = REPORT_TYPE.UNTREATED
        mData.gm = 0
        self.m_BlackCnt[mData.target] = self.m_BlackCnt[mData.target] or 0
        self.m_BlackCnt[mData.target] = self.m_BlackCnt[mData.target] + 1
        table.insert(mIDList,id)
        self.m_lContent[id] = mData
        local mUnit = self:GetUnitSave(mData)
        oDbObj:Update(sReportTableName, {id = id}, {["$set"]=mUnit},true)
    end
    self.m_lSortIDList = self:ComeBine(self.m_lSortIDList,mIDList)
end

function CReportObj:ComeBine(mList1,mList2)
    local mContent = self.m_lContent
    local iLen = #mList1 + #mList2
    local iNo1,iNo2 = 1,1
    local mList3 = {}
    for iTot=1,iLen do
        local iID1 = mList1[iNo1] or 0
        local iID2 = mList2[iNo2] or 0
        local mUnit1 = mContent[iID1]
        local mUnit2 = mContent[iID2]
        if mUnit1 and mUnit2 then
            if mUnit1.ptime < mUnit2.ptime then
                iNo1 = iNo1 + 1
                table.insert(mList3,iID1)
            else
                iNo2 = iNo2 + 1
                table.insert(mList3,iID2)
            end
        elseif mUnit1 then
            iNo1 = iNo1 + 1
            table.insert(mList3,iID1)
        elseif mUnit2 then
            iNo2 = iNo2 + 1
            table.insert(mList3,iID2)
        end
    end
    return mList3
end

function CReportObj:ChangeContentType(iID,sTypeName)
    local iType
    if sTypeName == "untreated" then
        iType = REPORT_TYPE.UNTREATED
    elseif sTypeName == "waitreated" then
        iType = REPORT_TYPE.WAITTREATED
    elseif sTypeName == "donetreated" then
        iType = REPORT_TYPE.DONETREATED
    elseif sTypeName == "malice" then
        iType = REPORT_TYPE.MALICE
    end
    local mData = self.m_lContent[iID]
    if not mData or mData.type == iType then
        return
    end
    if iType == REPORT_TYPE.DONETREATED then
        mData.detail = "忽略"
    end
    mData.type = iType
    self.m_lContent[iID] = mData
    local mUnit = self:GetUnitSave(mData)
    local oDbObj = self:GetDbObj()
    oDbObj:Update(sReportTableName, {id = iID}, {["$set"]=mUnit})
end

function CReportObj:ChangeContentGM(iID,gm)
    local mData = self.m_lContent[iID]
    if not mData then
        return
    end
    mData.gm = gm
    mData.type = REPORT_TYPE.UNTREATED
    self.m_lContent[iID] = mData
    local mUnit = self:GetUnitSave(mData)
    local oDbObj = self:GetDbObj()
    oDbObj:Update(sReportTableName, {id = iID}, {["$set"]=mUnit})
end

function CReportObj:DeleteContent(iID)
    local mData = self.m_lContent[iID]
    if not mData then
        return
    end
    local mSortIDList = self.m_lSortIDList
    local ptime = mData.ptime
    local iStart = self:SearchPos(mSortIDList,ptime-1)
    local iEnd = self:SearchPos(mSortIDList,ptime+1)
    local idx
    for iNo=iStart,iEnd do
        if mSortIDList[iNo] == iID then
            idx = iNo
        end
    end
    if not idx then
        record.error("delete err "..iID)
        return
    end
    table.remove(mSortIDList,idx)
    self.m_lContent[iID] = nil
    local oDbObj = self:GetDbObj()
    oDbObj:Delete(sReportTableName, {id = iID})
end

function CReportObj:SearchPos(mList,ptime)
    local iLimit,iCnt = 100,0
    local mContent = self.m_lContent
    local iStart,iEnd = 1,#mList
    while iStart < iEnd do
        iCnt = iCnt + 1
        if iCnt > iLimit then
            break
        end
        local iMiddle = (iStart + iEnd) // 2
        local iID = mList[iMiddle] or 0
        local mUnit = mContent[iID]
        if not mUnit then
            break
        end
        if mUnit.ptime > ptime then
            iEnd = iMiddle
        else
            iStart = iMiddle + 1
        end
    end
    return iEnd
end

function CReportObj:SearchReportInfo(mArgs)
    local iStartTime = mArgs.starttime
    local iEndTime = mArgs.endtime
    local iType
    if mArgs.type == "untreated" then
        iType = REPORT_TYPE.UNTREATED
    elseif mArgs.type == "waitreated" then
        iType = REPORT_TYPE.WAITTREATED
    elseif mArgs.type == "donetreated" then
        iType = REPORT_TYPE.DONETREATED
    elseif mArgs.type == "malice" then
        iType = REPORT_TYPE.MALICE
    end
    local mSearch = {
            type = iType,
            pid = tonumber(mArgs.pid),
            target = tonumber(mArgs.target),
            gm = mArgs.gm,
    }

    if iType == REPORT_TYPE.UNTREATED then
        mSearch.gm = mSearch.gm or 0
    end

    local mContent = self.m_lContent
    local mSortIDList = self.m_lSortIDList
    local iStart,iEnd = 1,#mSortIDList
    if iStartTime then
        iStartTime = bkdefines.AnalyTimeStamp2(iStartTime)
        iStart = self:SearchPos(mSortIDList,iStartTime-1)
    end
    if iEndTime then
        iEndTime = bkdefines.AnalyTimeStamp2(iEndTime)
        iEnd = self:SearchPos(mSortIDList,iEndTime+1)
    end

    local tResult = {}

    for iNo=iStart,iEnd do
        local iID = mSortIDList[iNo] or 0
        local mData = mContent[iID]
        local iFlag = true
        if mData then
            for sAttr,value in pairs(mSearch) do
                if mData[sAttr] ~= value then
                    iFlag = false
                    break
                end
            end
            if iFlag then
                table.insert(tResult,{
                    id = iID,
                    type = mData.type,
                    reporter = {
                        {
                            account = mData.account,
                            pid = mData.pid,
                            reason = mData.reason,
                            other = mData.other,
                            time = bkdefines.FormatTimeToSec(mData.ptime),
                            serverkey = mData.serverkey,
                            name = mData.name or "未知举报人"
                        }
                    },
                    target = mData.target,
                    tname = mData.tname or "未知角色名",
                    t_account = mData.t_account,
                    reason = mData.reason,
                    other = mData.other,
                    serverkey = mData.serverkey,
                    time = bkdefines.FormatTimeToSec(mData.ptime),
                    black = self.m_BlackCnt[mData.target] or 0,
                    status = self:GetStatus(mData.t_account,mData.target),
                    charge = mData.charge or 0,
                    gm = mData.gm,
                    detail = mData.detail or "无",
                })
            end
        end
    end

    return tResult
end

function CReportObj:SearchReporter(mArgs)
    local iStartTime = mArgs.starttime
    local iEndTime = mArgs.endtime
    local mSearch = {
            pid = tonumber(mArgs.target),
    }

    local mContent = self.m_lContent
    local mSortIDList = self.m_lSortIDList
    local iStart,iEnd = 1,#mSortIDList
    if iStartTime then
        iStartTime = bkdefines.AnalyTimeStamp2(iStartTime)
        iStart = self:SearchPos(mSortIDList,iStartTime-1)
    end
    if iEndTime then
        iEndTime = bkdefines.AnalyTimeStamp2(iEndTime)
        iEnd = self:SearchPos(mSortIDList,iEndTime+1)
    end

    local tResult = {}

    for iNo=iStart,iEnd do
        local iID = mSortIDList[iNo] or 0
        local mData = mContent[iID]
        local iFlag = true
        if mData then
            for sAttr,value in pairs(mSearch) do
                if mData[sAttr] ~= value then
                    iFlag = false
                    break
                end
            end
            if iFlag then
                table.insert(tResult,{
                    time = bkdefines.FormatTimeToSec(mData.ptime),
                    pid= mData.pid,
                    reason = mData.reason,
                    other = mData.other,
                    serverkey = mData.serverkey,
                })
            end
        end
    end

    return tResult
end

function CReportObj:GetServerGameDB(sServer)
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj.m_mServers[sServer]
    if not oServer then
        return
    end
    return oServer.m_oGameDb:GetDb()
end

function CReportObj:GetServerChatDb(sServer)
    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj.m_mServers[sServer]
    if not oServer then
        return
    end
    return oServer.m_oChatLogDb:GetDb()
end

local tChannelName = {
    "世界频道",
    "队伍频道",
    "公会频道",
}

function CReportObj:SearchChatInfo(mArgs)
    local pid = tonumber(mArgs.pid)
    if not pid then return {} end

    local iStartTime = bkdefines.AnalyTimeStamp2(mArgs.starttime)
    local iEndTime = bkdefines.AnalyTimeStamp2(mArgs.endtime)

    local oBackendObj = global.oBackendObj
    local serverkeys = oBackendObj:GetServerList()

    local mSearch = {
        subtype = {["$in"]={"chat","friend"}},
        _time = {["$gte"]=bson.date(iStartTime),["$lte"]=bson.date(iEndTime)},
    }
    local tResult = {}
    for sServer,_ in pairs(serverkeys) do
        local oGameDb = self:GetServerGameDB(sServer)
        local m = oGameDb:FindOne("player", {pid = pid}, {pid = true})
        if m and m.pid then
            local oChatLogDb = self:GetServerChatDb(sServer)
            local m = oChatLogDb:Find("chat",mSearch)
            m = m:sort({_time = 1}):limit(1000)
            while m:hasNext() do
                local mData = m:next()
                if mData and mData.text then
                    local sChannelName = tostring(mData.channel)
                    if mData.subtype == "friend" then
                        sChannelName = "好友频道"
                    elseif mData.subtype == "chat" then
                        sChannelName = tChannelName[tonumber(mData.channel)]
                    end
                    local _,time = bson.type(mData._time)
                    table.insert(tResult,{
                        time = bkdefines.FormatTimeToSec(time),
                        text = mData.text,
                        channelname = sChannelName,
                    })
                end
            end
            break
        end
    end

    return tResult
end

function CReportObj:HandlePerson(gm,sID,sServerKey,sType,sKey,Value,mArgs)
    mArgs = mArgs or {}
    if table_in_list({"banloginact","banloginrole","banchatact","banchatrole"},sType) then
        local sData = extend.Table.serialize({
                type=sType,
                key=sKey,
                value=Value,
            })
        router.Send("cs", ".serversetter", "punish", "PunishBadPerson", sData)
        self:AfterHandleBan(sType,sKey,Value)
        if table_in_list({"banloginact","banloginrole"},sType) then
            self:KickPlayer(sServerKey,sType,sKey)
        end
    elseif table_in_list({"cancelbanact","cancelbanrole"},sType) then
        local sData = extend.Table.serialize({
                type=sType,
                key=sKey,
            })
        router.Send("cs", ".serversetter", "punish", "CanCelPerson", sData)
    elseif sType == "warning" then
        self:WarningPlayer(sServerKey,sKey)
    elseif sType == "resumecoin" then
        self:ResumeCoin(sServerKey,sKey,Value)
    elseif sType == "reward" then
        self:RewardCoin(sServerKey,sKey,Value)
    elseif sType == "resetname" then
        router.Request(get_server_tag(sServerKey), ".world", "backend", "RenamePlayer", {
                pid = tonumber(sKey),
                name = Value,
                gold = mArgs.gold or 0,
        },function (mRecord, mData)
        end)
    elseif sType == "banreport" then
        self:BanReport(sServerKey,sKey,Value)
    end
    if table_in_list({"banloginact","banloginrole","banchatact",
        "banchatrole","resetname","cancelbanact","cancelbanrole"},sType) then
        self:ChangeContentAfterHandle(sID,{
            gm=gm,
            type=REPORT_TYPE.DONETREATED,
            detail=Handle2Name[sType],
        })
    end
end

function CReportObj:ChangeContentAfterHandle(iID,mArgs)
    local mData = self.m_lContent[iID]
    if not mData then
        return
    end
    mData.gm = mArgs.gm
    mData.type = mArgs.type
    mData.detail = mArgs.detail or mData.detail
    self.m_lContent[iID] = mData
    local mUnit = self:GetUnitSave(mData)
    local oDbObj = self:GetDbObj()
    oDbObj:Update(sReportTableName, {id = iID}, {["$set"]=mUnit})
end

function CReportObj:KickPlayer(sServerKey,sType,sKey)
    local pid
    if sType == "banloginrole" then
        pid = tonumber(sKey)
    elseif sType == "banloginact" then
        local oBackendObj = global.oBackendObj
        local oServer = oBackendObj:GetServer(sServerKey)
        local oGameDb = oServer.m_oGameDb:GetDb()
        local mInfo = oGameDb:FindOne("player", {account = sKey})
        mongoop.ChangeAfterLoad(mInfo)
        pid = mInfo.pid or 0
    end
    if pid then
        router.Request(get_server_tag(sServerKey),".world","backend","gmbackend",{
            cmd="KickPlayer",
            data={pid=pid},
            },
            function (m1,mRes)
                if mRes.errcode then
                    record.error("after punish error"..sServerKey.."  "..sType.."  "..sKey)
                end
            end
        )
    end
end

function CReportObj:WarningPlayer(sServerKey,pid)
    router.Request(get_server_tag(sServerKey),".world","backend","gmbackend",{
            cmd="ReportWarning",
            data={pid=tonumber(pid)},
            },
            function (m1,mRes)
                if mRes.errcode then
                    record.error("after punish warning error "..sServerKey.."  "..pid)
                end
            end
        )
end

function CReportObj:ResumeCoin(sServerKey,pid,coin)
    router.Request(get_server_tag(sServerKey),".world","backend","gmbackend",{
            cmd="ReportPunish",
            data={pid=tonumber(pid),coin=tonumber(coin)},
            },
            function (m1,mRes)
                if mRes.errcode then
                    record.error("after punish resumecoin error "..sServerKey.."  "..pid)
                end
            end
        )
end

function CReportObj:BanReport(sServerKey,pid,time)
    router.Request(get_server_tag(sServerKey),".world","backend","gmbackend",{
            cmd="BanReport",
            data={pid=tonumber(pid),time=tonumber(time)},
            },
            function (m1,mRes)
                if mRes.errcode then
                    record.error("after punish banreport error "..sServerKey.."  "..pid)
                end
            end
        )
end

function CReportObj:RewardCoin(sServerKey,pid,coin)
    router.Request(get_server_tag(sServerKey),".world","backend","gmbackend",{
            cmd="ReportReward",
            data={pid=tonumber(pid),coin=tonumber(coin)},
            },
            function (m1,mRes)
                if mRes.errcode then
                    record.error("after punish resumecoin error "..sServerKey.."  "..pid)
                end
            end
        )
end

function CReportObj:InitBanInfo()
    local f1
    f1 = function ()
        self:DelTimeCb("InitBanInfo")
        self:InitBanInfo()
    end
    self:AddTimeCb("InitBanInfo", 5*1000 , f1)
end

function CReportObj:InitBanInfo2()
    router.Request("cs",".serversetter", "punish", "GetBanInfo", {}, function (mRecord,mData)
        mData = extend.Table.deserialize(mData)
        self:InitBanInfo3(mData)
    end)
end

function CReportObj:InitBanInfo3(mData)
    self.m_BanLoginAct = mData.banloginact or {}
    self.m_BanLoginRole = mData.banloginrole or {}
    self.m_BanChatAct = mData.banchatact or {}
    self.m_BanChatRole = mData.banchatrole or {}
end

function CReportObj:AfterHandleBan(sType,sKey,iTime)
    local iNowTime = get_time()
    if sType == "banloginact" then
        self.m_BanLoginAct[sKey] = iNowTime + iTime*60
    elseif sType == "banloginrole" then
        self.m_BanLoginRole[sKey] = iNowTime + iTime*60
    elseif sType == "banchatact" then
        self.m_BanChatAct[sKey] = iNowTime + iTime*60
    elseif sType == "banchatrole" then
        self.m_BanChatRole[sKey] = iNowTime + iTime*60
    end
end

function CReportObj:GetStatus(sAccount,iPid)
    local iNowTime = get_time()
    local iTime = self.m_BanLoginAct[sAccount]
    if iTime and iTime > iNowTime then
        return "封禁"
    end
    iTime = self.m_BanChatAct[sAccount]
    if iTime and iTime > iNowTime then
        return "禁言"
    end
    iTime = self.m_BanLoginRole[tostring(iPid)]
    if iTime and iTime > iNowTime then
        return "封禁"
    end
    iTime = self.m_BanChatRole[tostring(iPid)]
    if iTime and iTime > iNowTime then
        return "禁言"
    end
    return "正常"
end

function CReportObj:ClearOverTime2()
    local mAttrs = {"m_BanLoginAct","m_BanLoginRole","m_BanChatAct","m_BanChatRole"}
    local iNowTime = get_time()
    for _,sAttr in pairs(mAttrs) do
        local mDel = {}
        local mContent = self[sAttr] or {}
        for k,v in pairs(mContent) do
            if v < iNowTime then
                table.insert(mDel,k)
            end
        end
        for _,k in pairs(mDel) do
            mContent[k] = nil
        end
    end
end