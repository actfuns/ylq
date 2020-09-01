--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"
local httpuse = require "public.httpuse"
local router = require "base.router"
local serverdefines = require "public.serverdefines"

local gamedb = import(lualib_path("public.gamedb"))
local account = import(lualib_path("public.account"))
local datactrl = import(lualib_path("public.datactrl"))
local serverinfo = import(lualib_path("public.serverinfo"))
local serverdesc = import(lualib_path("public.serverdesc"))
local gamedefines = import(lualib_path("public.gamedefines"))


function NewSetterMgr(...)
    local o = CSetterMgr:New(...)
    return o
end

CSetterMgr = {}
CSetterMgr.__index = CSetterMgr
CSetterMgr.c_sDbKey = "svrsetter"
inherit(CSetterMgr, datactrl.CDataCtrl)

function CSetterMgr:New()
    local o = super(CSetterMgr).New(self)
    o.m_bLoading = true
    o.m_mServerSettings = {}
    o.m_mServerIndexs = {}
    o.m_iNoticeVer = 0
    o.m_iNoticeId = 0
    o.m_mNotices = {}
    o.m_iWhiteAccountId = 0
    o.m_mWhiteAccounts = {}
    return o
end

function CSetterMgr:Save()
    local mData = {}
    mData.srv = self.m_mServerSettings
    mData.index = self.m_mServerIndexs
    mData.notice_ver = self.m_iNoticeVer
    mData.notice_id = self.m_iNoticeId
    mData.notice = self.m_mNotices
    mData.white_account_id = self.m_iWhiteAccountId
    mData.white_account = self.m_mWhiteAccounts
    return mData
end

function CSetterMgr:Load(mData)
    mData = mData or {}
    self.m_mServerSettings = mData.srv or {}
    self.m_mServerIndexs = mData.index or {}
    self.m_iNoticeVer = mData.notice_ver or 0
    self.m_iNoticeId = mData.notice_id or 0
    self.m_mNotices = mData.notice or {}
    self.m_iWhiteAccountId = mData.white_account_id or 0
    self.m_mWhiteAccounts = mData.white_account or {}
end

function CSetterMgr:IsLoading()
    return self.m_bLoading
end

function CSetterMgr:Init()
    if not self:IsLoading() then return end
    local mData = {
        name = self.c_sDbKey
    }
    local mArgs = {
        module = "global",
        cmd = "LoadGlobal",
        data = mData
    }
    gamedb.LoadDb("setter","common", "LoadDb", mArgs,
        function (mRecord, mData)
            if self:IsLoading() then
                self:Load(mData.data)
                self.m_bLoading = false
                self:ConfigSaveFunc()
                self:AfterLoad()
            end
    end)
end

function CSetterMgr:SaveDb()
    if self:IsDirty() then
        local mData = {
            name = self.c_sDbKey,
            data = self:Save()
        }
        gamedb.SaveDb("setter","common", "SaveDb", {module="global",cmd="SaveGlobal",data = mData})
        self:UnDirty()
    end
end

function CSetterMgr:_CheckSaveDb()
    assert(not self:IsLoading(), "settermgr save fail: is loading")
    self:SaveDb()
end

function CSetterMgr:ConfigSaveFunc()
    -- self:ApplySave(function ()
    --     local obj = global.oSetterMgr
    --     if obj then
    --         obj:_CheckSaveDb()
    --     else
    --         record.warning("settermgr save err: no obj")
    --     end
    -- end)
end

function CSetterMgr:AfterLoad()
    -- body
end

function CSetterMgr:GetServerOpenTime(sTime)
    if sTime then
        local Y = string.sub(sTime, 1, 4)
        local m = string.sub(sTime, 6, 7)
        local d = string.sub(sTime, 9, 10)
        local H = string.sub(sTime, 12, 13)
        local M = string.sub(sTime, 15, 16)
        local S = string.sub(sTime, 18, 19)
        local iOpenTime = os.time({year=Y, month=m, day=d, hour=H, min=M, sec=S})
        return iOpenTime
    end
end

function CSetterMgr:CheckServerMathch(sServerKey, iPlatform, iChannel, sCpsChannel)
    local mSetting = self:GetServerSetting(sServerKey)
    local sServerKey = mSetting["link_server"] or sServerKey
    if not serverinfo.is_matched_platform(iPlatform, sServerKey) then
        return false
    end
    if not serverinfo.is_opened_channel(iChannel, sServerKey) then
        return false
    end

    if not serverinfo.is_opened_cps(sCpsChannel, sServerKey) then
        return false
    end
    return true
end

function CSetterMgr:IsSameGameType(sServerKey,sGameType)
    if not serverinfo.is_matched_game(sGameType,sServerKey) then
        return false
    end
    return true
end

function CSetterMgr:GetClientServerList(mArgs)
    local iChannel = mArgs.channel
    local iPlatform = mArgs.platform
    local sCpsChannel = mArgs.cps or ""
    local iVer = mArgs.version or 0
    local sGameType = mArgs.game_type or ""
    local mRet = {}
    mRet["ports"] = split_string(GS_GATEWAY_PORTS, ",", tonumber)
    mRet["servers"] = {}
    mRet["RecommendServerList"] = {}
    local mHaveGroup = {}
    local iNowTime = get_time()
    local lRecommemd = {}
    for _, mServer in pairs(self:GetServerList()) do
        local sServerKey = mServer["id"]
        if not self:CheckServerMathch(sServerKey, iPlatform, iChannel, sCpsChannel) then
            goto continue
        end
        if not self:IsSameGameType(sServerKey,sGameType) then
            goto continue
        end
        local mData = {
            id = sServerKey,
            group = mServer["index"],
            new = mServer["is_new"],
            name = mServer["name"],
            ip = mServer["ip"],
            platform = mServer["platforms"],
            state = mServer["run_state"],
            linkserver = sServerKey,
        }
        table.insert(mRet["servers"], mData)
        if mServer["index"] then
            mHaveGroup[mServer["index"]] = 1
        end
        local iRecommend = mServer["recommend"]
        if iRecommend and iRecommend > 0 then
            table.insert(lRecommemd, sServerKey)
        end
        ::continue::
    end
    mRet["RecommendServerList"] = lRecommemd
    mRet["groups"] = self:GetServerIndex(mHaveGroup)
    mRet = table_combine(mRet, self:GetClientNotice(iVer, iPlatform, iChannel, sCpsChannel))
    return mRet
end

function CSetterMgr:GetServerInfo(sServerKey)
    local mSetting = self:GetServerSetting(sServerKey)
    local mConfig = serverinfo.get_gs_info(mSetting["link_server"] or sServerKey) or {}
    local mData = {
        id = sServerKey,
        ip = mConfig.client_host,
        name = mSetting.name,
        platforms = tostring(mConfig.desc),
        index = mSetting.index,
        start_time = mSetting.start_time,
        open_time = mSetting.open_time,
        run_state = mSetting.run_state,
        is_new = mSetting.is_new,
        is_show = mSetting.is_show,
        recommend = mSetting.recommend,
        area = mSetting.area,
        desc = mSetting.desc,
        link_server = mSetting.link_server,
    }
    return mData
end

function CSetterMgr:GetServerList()
    local lRet = {}
    for gs_key, info in pairs(serverinfo.GS_INFO) do
        table.insert(lRet, self:GetServerInfo(gs_key))
    end
    return lRet
end

function CSetterMgr:GetServerById(sServer)
    self:GetServerInfo(sServer)
end

function CSetterMgr:GetAllServerSetting()
    local res = require "base.res"
    return res["daobiao"]["serverinfo"][get_server_cluster()] or {}
end

function CSetterMgr:GetServerSetting(sServer)
    local mSettingInfo = self:GetAllServerSetting()
    if not mSettingInfo then
        record.warning("not find server setting error 1 %s", sServer)
        return {}
    end
    if not mSettingInfo[sServer] then
        record.warning("not find server setting error 2 %s", sServer)
        return {}
    end
    return mSettingInfo[sServer]
end

function CSetterMgr:SaveOrUpdateServer(mArgs)
    self:Dirty()
    local mData = mArgs["data"] or {}

    local sServerKey = mData.id
    local mServerInfo = self.m_mServerSettings[sServerKey] or {}
    mServerInfo.serverIndex = mData.serverIndex or mServerInfo.serverIndex
    mServerInfo.openAtStr = mData.openAtStr or mServerInfo.openAtStr
    mServerInfo.openTime = mData.openTime or mServerInfo.openTime
    mServerInfo.runState = mData.runState or mServerInfo.runState
    mServerInfo.isNewServer = mData.isNewServer or mServerInfo.isNewServer
    self.m_mServerSettings[sServerKey] = mServerInfo
    self:SaveDb()

    return self:GetServerList()
end

function CSetterMgr:DeleteServer(ids)
    self:Dirty()
    for _, sServerKey in ipairs(split_string(ids, ",")) do
        self.m_mServerSettings[sServerKey] = nil
    end
    self:SaveDb()
end

function CSetterMgr:GetServerIndex(mHaveGroup)
    local res = require "base.res"
    local mData = res["daobiao"]["servergroup"] or {}
    local lRet = {}
    for _,mInfo in pairs(mData) do
        local iGroup = tonumber(mInfo["id"])
        if mHaveGroup[iGroup] then
            table.insert(lRet, {id = iGroup,name=mInfo["name"]})
        end
    end
    return lRet
end

function CSetterMgr:SaveOrUpdateIndex(mArgs)
    self:Dirty()

    local mData = mArgs["data"] or {}

    local sIndex = mData.id
    local mServerInfo = self.m_mServerIndexs[sIndex] or {}
    mServerInfo.id = sIndex
    mServerInfo.name = mData.name
    self.m_mServerIndexs[sIndex] = mServerInfo
    self:SaveDb()

    return self:GetServerList()
end

function CSetterMgr:DeleteIndex(ids)
    self:Dirty()
    for _, sIndex in ipairs(split_string(ids, ",")) do
        self.m_mServerIndexs[sIndex] = nil
    end
    self:SaveDb()
end

function CSetterMgr:GetWhiteAccountList()
    self:Dirty()
    local lRet = {}
    for id, m in pairs(self.m_mWhiteAccounts) do
        table.insert(lRet, {id=tonumber(id), account=m.account, channel=m.channel})
    end
    return lRet
end

function CSetterMgr:DispatchWhiteAccountID()
    self:Dirty()
    self.m_iWhiteAccountId = self.m_iWhiteAccountId + 1
    return self.m_iWhiteAccountId
end

function CSetterMgr:SaveWhiteAccount(mData)
    self:Dirty()
    local iId = self:DispatchWhiteAccountID()
    self.m_mWhiteAccounts[tostring(iId)] = {
        account = mData.account,
        channel = tonumber(mData.channel)
    }
    self:SaveDb()
end

function CSetterMgr:DeleteWhiteAccount(ids)
    self:Dirty()
    for _, id in ipairs(ids) do
        self.m_mWhiteAccounts[tostring(id)] = nil
    end
    self:SaveDb()
end

function CSetterMgr:GetClientNotice(iVer, iPlatform, iChannel, sCps)
    local iVer = iVer or 0
    local iCurVer = self:GetNoticeVersion()
    local mRet = {notice_version=iCurVer, infoList={}}
    if iVer >= iCurVer then
        return mRet
    end
    mRet.infoList = self:GetPublisNoticeList(iPlatform, iChannel, sCps)
    return mRet
end

function CSetterMgr:DispatchNoticeId()
    self:Dirty()
    self.m_iNoticeId = self.m_iNoticeId + 1
    return self.m_iNoticeId
end

function CSetterMgr:DispatchNoticeVer()
    self:Dirty()
    self.m_iNoticeVer = self.m_iNoticeVer + 1
    return self.m_iNoticeVer
end

function CSetterMgr:GetNoticeVersion()
    return self.m_iNoticeVer
end

function CSetterMgr:GetPublisNoticeList(iPlatform, iChannel, sCps)
    local lRet = {}
    local lOrder = {}
    for id, info in pairs(self.m_mNotices) do
        if self:CheckNotice(info, iPlatform, iChannel, sCps) then
            table.insert(lOrder,{info.order,tonumber(id)})
        end
    end
    if #lOrder > 0 then
        local fSort = function (mData1,mData2)
            if mData1[1] ~= mData2[1] then
                return mData1[1] < mData2[1]
            else
                return mData1[2] < mData2[2]
            end
        end
        table.sort(lOrder,fSort)
        for _,mData in ipairs(lOrder) do
            local iOrder,id = table.unpack(mData)
            local info = self.m_mNotices[tostring(id)]
            if info then
                table.insert(lRet, {title=info.title, content=info.content,hot=info.hot})
            end
        end
    end
    return lRet
end

function CSetterMgr:GetNoticeList()
    local lRet = {}
    local lOrder = {}
    for id, info in pairs(self.m_mNotices) do
        table.insert(lOrder,{info.order,tonumber(id)})
    end
    if #lOrder > 0 then
        local fSort = function (mData1,mData2)
            if mData1[1] ~= mData2[1] then
                return mData1[1] < mData2[1]
            else
                return mData1[2] < mData2[2]
            end
        end
        table.sort(lOrder,fSort)
        for _,mData in ipairs(lOrder) do
            local iOrder,id = table.unpack(mData)
            local info = self.m_mNotices[tostring(id)]
            if info then
                table.insert(lRet, info)
            end
        end
    end
    return lRet
end

function CSetterMgr:ValidNoticeInfo(mInfo)
    local lPlatform = mInfo.platform
    local lChannel = mInfo.channel
    local lCps = mInfo.cps
    if lPlatform and type(lPlatform) ~= "table" then
        record.warning("save or update notice platform err")
        return false
    end
    if lChannel and type(lChannel) ~= "table" then
        record.warning("save or update notice channel err")
        return false
    end
    if lCps and type(lCps) ~= "table" then
        record.warning("save or update notice cps err")
        return false
    end
    if not mInfo.title or not mInfo.content then
        record.warning("save or update notice info err")
        return false
    end
    return true
end

function CSetterMgr:CheckNotice(mInfo, iPlatform, iChannel, sCps)
    if mInfo.state == 0 then
        return false
    end
    if mInfo.platform and not table_in_list(mInfo.platform, iPlatform) then
        return false
    end
    if mInfo.channel and not table_in_list(mInfo.channel, iChannel) then
        return false
    end
    if mInfo.cps and not table_in_list(mInfo.cps, sCps) then
        return false
    end
    return true
end

function CSetterMgr:SaveOrUpdateNotice(mData)
    if not self:ValidNoticeInfo(mData) then return end

    local id = mData["id"]
    if not id or id <= 0 then
        mData["id"] = tostring(self:DispatchNoticeId())
        self.m_mNotices[mData["id"]] = mData
    else
        self.m_mNotices[tostring(mData["id"])] = mData
        self:DispatchNoticeVer()
    end
    self:SaveDb()
end

function CSetterMgr:DeleteNotice(ids)
    self:Dirty()
    for _, id in pairs(ids) do
        self.m_mNotices[tostring(id)] = nil
    end
    self:DispatchNoticeVer()
    self:SaveDb()
end

function CSetterMgr:PublishNotice(ids)
    self:Dirty()
    for _, id in pairs(ids) do
        id = tostring(id)
        if self.m_mNotices[id] then
            self.m_mNotices[id].state = 1
        end
    end
    self:DispatchNoticeVer()
    self:SaveDb()
end

function CSetterMgr:GetChannelList()
    local res = require "base.res"
    local lRet = {}
    for sKey, mData in pairs(res["daobiao"]['demichannel']) do
        table.insert(lRet, {
            id = sKey,
            relatedId = sKey,
            description = mData["name"],
            platforms = gamedefines.GetPlatformNo(mData["platform"]),
            subdescription = {mData["channel_name"]},
        })
    end
    if not is_production_env() then
        table.insert(lRet, {id = 0, relatedId = 0, description = "测试", platforms = 0 , subdescription={""} })
    end
    return lRet
end
