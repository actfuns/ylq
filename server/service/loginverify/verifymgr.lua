--import module

local url = require "http.url"
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local md5 = require "md5"
local cjson = require "cjson"
local record = require "public.record"
local httpuse = require "public.httpuse"
local router = require "base.router"

local urldefines = import(lualib_path("public.urldefines"))
local serverdefines = require "public.serverdefines"
local datactrl = import(lualib_path("public.datactrl"))

MAX_TOKEN_ID = 1000000
VALID_SECOND = 30 * 60

function NewVerifyMgr(...)
    local o = CVerifyMgr:New(...)
    return o
end

CVerifyMgr = {}
CVerifyMgr.__index = CVerifyMgr
inherit(CVerifyMgr, datactrl.CDataCtrl)

function CVerifyMgr:New(iServiceKey)
    local o = super(CVerifyMgr).New(self)
    o.m_mServiceKey = iServiceKey
    o.m_iDispatchMyTokenID = 0
    o.m_mValidLoginToken ={}
    return o
end

function CVerifyMgr:Init()
    self:Schedule()
end

function CVerifyMgr:DispatchMyToken()
    self.m_iDispatchMyTokenID = self.m_iDispatchMyTokenID + 1
    if self.m_iDispatchMyTokenID >= MAX_TOKEN_ID then
        self.m_iDispatchMyTokenID = 1
    end
    local iToken = get_time() * MAX_TOKEN_ID + self.m_iDispatchMyTokenID
    return string.format("%d_%d",iToken,self.m_mServiceKey)
end

function CVerifyMgr:Schedule()
    local f
    f = function()
        self:DelTimeCb("_CheckValidToken")
        self:AddTimeCb("_CheckValidToken", 10*60*1000, f)
        self:_CheckValidToken()
    end
    f()
end

function CVerifyMgr:_CheckValidToken()
    local iTimeOut = 30*60
    local lKey = {}
    for sToken, mData in pairs(self.m_mValidLoginToken) do
        if mData.time + VALID_SECOND < get_time() then
            table.insert(lKey, sToken)
        end
    end
    for _, sToken in ipairs(lKey) do
        self.m_mValidLoginToken[sToken] = nil
    end
end

function CVerifyMgr:KeepTokenAlive(sToken)
    local mData = self.m_mValidLoginToken[sToken]
    if not mData then
        return
    end
    mData.time = get_time()
end

function CVerifyMgr:VerifyMyToken(sToken)
    local mData = self.m_mValidLoginToken[sToken]
    if not mData then
        return nil
    end
    if mData.time + VALID_SECOND < get_time() then
        return nil
    else
        return mData
    end
end

function CVerifyMgr:GenerateMyToken(sAccount,iChannel, sCpsChannel,iPlatform,sPublisher)
    local sToken = self:DispatchMyToken()
    self.m_mValidLoginToken[sToken] = {
        account = sAccount,
        channel = iChannel,
        cps = sCpsChannel,
        platform = iPlatform,
        publisher = sPublisher,
        time = get_time()
    }
    return sToken
end

function CVerifyMgr:TestClientVerifyAccount(sToken, iChannel, sDeviceId, sCpsChannel, sChannelUuid,iPlatform, mOther, endfunc)
    local mResult = {}
    self:SdkVerifyEnd(0, {uid=sChannelUuid,channel=iChannel}, iChannel, sCpsChannel, sChannelUuid,mResult,iPlatform,mOther, endfunc)
end

function CVerifyMgr:ClientVerifyDemiChannel(mData,endfunc)
    local sChannel = mData.sdk_type
    local sCpsChannel = mData.cps
    local mParam = {
        appId = global.oDemiSdk:GetAppId(),
        channel = sChannel,
        p = sCpsChannel,
    }

    local sHost = urldefines.get_out_host()
    local sUrl = urldefines.get_demi_url("channel_verify")
    sUrl = httpuse.mkurl(sUrl,mParam)
    local mHeader = {}
    mHeader["Content-type"] = "application/x-www-form-urlencoded"
    httpuse.get(sHost, sUrl, sParam, function(body, header)
        self:_ClientVerifyDemiChannel(mData,body,sChannel,sCpsChannel,endfunc)
    end, mHeader)
end

function CVerifyMgr:_ClientVerifyDemiChannel(mData,sBody,sChannel,sCpsChannel,endfunc)
    local mRet = httpuse.content_json(sBody)
    if not next(mRet) then
        record.error("DemiChannleVerify %s %s no response", sChannel, sCpsChannel)
        endfunc(601)
        return
    end
    if mRet.code ~= 0 then
        record.error("DemiChannleVerify %s %s retcode:%s, msg:%s", sChannel,sCpsChannel, mRet.code, mRet.msg)
        endfunc(602)
        return
    end
    if not mRet.item or not next(mRet.item) then
        record.error("DemiChannleVerify %s %s item nil", sChannel, sCpsChannel)
        endfunc(603)
        return
    end
    local mDemiData = mRet.item
    local iChannel = mDemiData["channelId"]
    local sToken = mData.token
    local sDeviceId = mData.device_id
    local sCpsChannel = mData.cps
    local sChannelUuid = mData.account
    local iPlatform = mData.platform
    
    local mOther = {
        notice_ver = mData.notice_ver,
        packet_info = mData.packet_info or {},
        publisher = mData.sdk_type or "kaopu",--发行,kaopu or sm
    }
    self:ClientVerifyAccount(sToken, iChannel, sDeviceId, sCpsChannel, sChannelUuid,iPlatform, mOther,endfunc)
end

function CVerifyMgr:ClientVerifyAccount(sToken, iChannel, sDeviceId, sCpsChannel, sChannelUuid,iPlatform,mOther, endfunc)
    local mResult = {}
    if iChannel and iChannel ~= 0 then
        if not sToken or sToken == "" then
            endfunc({errcode = 1})
            return
        end
        local iChannel = tonumber(iChannel)
        self:SdkVerify(sToken, iChannel, sDeviceId, function (errcode, mAccount)
            self:SdkVerifyEnd(errcode, mAccount, iChannel, sCpsChannel, sChannelUuid, mResult, iPlatform,mOther, endfunc)
        end)
    else
        local iChannel = 0
        self:SdkVerifyEnd(0, {uid=sChannelUuid,channel = iChannel}, iChannel, sCpsChannel, sChannelUuid, mResult, iPlatform,mOther, endfunc)
    end
end

function CVerifyMgr:SdkVerify(sToken, iChannel, sDeviceId, func)
    local iRequestId = get_time()
    local mParam = {
        sid = sToken,
        appId = global.oDemiSdk:GetAppId(),
        id = iRequestId,
        p = iChannel,
        deviceId = sDeviceId
    }
    mParam["sign"] = global.oDemiSdk:Sign(mParam)

    local sHost = urldefines.get_out_host()
    local sUrl = urldefines.get_demi_url("login_verify")
    local sParam = httpuse.mkcontent_kv(mParam)
    local mHeader = {}
    mHeader["Content-type"] = "application/x-www-form-urlencoded"
    httpuse.post(sHost, sUrl, sParam, function(body, header)
        self:_SdkVerify1(body, iChannel, sToken, func)
    end, mHeader)
end

function CVerifyMgr:_SdkVerify1(sBody, iChannel, sToken, func)
    local mRet = httpuse.content_json(sBody)
    if not next(mRet) then
        record.error("SdkVerify %s %s no response", iChannel, sToken)
        func(101)
        return
    end
    if mRet.code ~= 0 then
        record.error("SdkVerify %s %s retcode:%s, msg:%s", iChannel, sToken, mRet.code, mRet.msg)
        func(102)
        return
    end
    if not mRet.item or not next(mRet.item) then
        record.error("SdkVerify %s %s item nil", iChannel, sToken)
        func(103)
        return
    end
    func(0, mRet.item)
end

function CVerifyMgr:SdkVerifyEnd(errcode, mAccount, iChannel, sCpsChannel, sChannelUuid, mResult,iPlatform,mOther, endfunc)
    if errcode ~= 0 then
        endfunc({errcode = errcode})
        return
    else
        local sAccount = mAccount.uid
        if not sAccount then
            record.warning(string.format("SdkVerifyEnd demi account err:%s",ConvertTblToStr(mAccount)))
        end
        local sPublisher = mOther.publisher or "kaopu"
        mResult.token = self:GenerateMyToken(sAccount, iChannel, sCpsChannel,iPlatform,sPublisher)

        self:RequestServerInfo(iChannel, iPlatform, sCpsChannel, mOther, function (errcode, mInfo)
            self:OnGetServerList(errcode, mInfo, sAccount, iChannel, iPlatform,mOther, mResult, endfunc)
        end)
    end
end

function CVerifyMgr:RequestRoleInfos(sAccount, iChannel, iPlatform, lServerList,mArgs,func)
    local lChannel = {iChannel}
    if not lChannel or not next(lChannel) or not lServerList or not next(lServerList) then
        func(0, {})
        return
    end
    mArgs = mArgs or {}
    interactive.Request(".datacenter", "common", "GetRoleList", {account=sAccount, channel=lChannel, platform=iPlatform, server=lServerList,args = mArgs},
        function (mRecord, mData)
            self:_RequestRoleInfos1(mRecord, mData, sAccount, lChannel, iPlatform, lServerList, func)
        end
    )
end

function CVerifyMgr:_RequestRoleInfos1(mRecord, mData, sAccount,iChannel,iPlatform,lServerList,func)
    if mData.errcode ~= 0 then
        record.error("RequestRoleInfos err channel:%s, account:%s, retcode:%s",sAccount, iChannel, mData.errcode)
        func(mData.errcode)
    else
        func(0, mData.roles)
    end
end

function CVerifyMgr:OnGetRoleInfos(errcode, mRoles, mResult,endfunc)
    if errcode ~= 0 then
        endfunc({errcode = errcode})
        return
    else
        mResult.role_list = mRoles
        endfunc({errcode = 0, info = mResult})
    end
end

function CVerifyMgr:RequestServerInfo(iChannel,iPlatform,sCpsChannel,mOther, func)
    local mPacketInfo = mOther.packet_info or {}
    local sGameType = mPacketInfo.game_type or "ylq"
    local mContent = {
        version=mOther.notice_ver,
        game_type = sGameType,
        channel = iChannel,
        platform = iPlatform,
        publisher = mOther.publisher,
    }

    local fCallback = function (mRecord,mData)
        if not is_release(self) then
            self:_RequestSeverInfo1(mData,func)
        end
    end
    interactive.Request(".serversetter","common","GetClientServerList",mContent,fCallback)
end

function CVerifyMgr:_RequestSeverInfo1(mData, func)
    if mData.errcode ~= 0 then
        record.error("RequestSeverInfo err retcode:%s", mData.code)
        func(301)
        return
    end
    if not next(mData.data.servers) then
        --record.info("RequestServerInfo err: no server %s", serialize_table(mData))
    end
    func(0, mData.data)
end

function CVerifyMgr:OnGetServerList(errcode, mInfo,sAccount, iChannel, iPlatform,mOther,mResult, endfunc)
    if errcode ~= 0 then
        endfunc({errcode = errcode})
        return
    else
        mResult.server_info = mInfo
        local lServerList = {}
        for _, info in ipairs(mInfo.servers) do
            table.insert(lServerList, get_server_tag(info.linkserver))
        end
        mOther = mOther or {}
        local mArgs = {
            publisher = mOther.publisher or "kaopu"
        }
        self:RequestRoleInfos(sAccount, iChannel, iPlatform, lServerList,mArgs,function (errcode, mRoles)
            self:OnGetRoleInfos(errcode, mRoles, mResult, endfunc)
        end)
    end
end

function CVerifyMgr:ClientQRCodeScan(sAccountToken, sCodeToken, endfunc)
    if not self:VerifyMyToken(sAccountToken) then
        record.info("ClientQRCodeScan err: no such sAccountToken:%s", sAccountToken)
        endfunc(501)
        return
    end

    local qrc_key = string.match(sCodeToken, "^(%w+)%-%d+")
    local iPort = tonumber(string.match(qrc_key, "%a+(%d+)"))
    local sQrcPorts = serverdefines.get_qrcode_ports()
    local lQrcPorts = split_string(sQrcPorts, ",", tonumber)
    if not table_in_list(lQrcPorts,iPort)  then
        record.error("ClientQRCodeScan err: no such qrc_key:%s %s", sCodeToken, qrc_key)
        endfunc(502)
        return
    end
    self:KeepTokenAlive(sAccountToken)
    router.Request("cs", string.format(".%s",qrc_key) , "common", "ScanQRCode", {
        code_token = sCodeToken,
    }, function (mRecord, mData)
        self:_ClientQRCodeScan1(mData, endfunc)
    end)
end

function CVerifyMgr:_ClientQRCodeScan1(mRet, func)
    if mRet.errcode ~= 0 then
        record.error("ClientQRCodeScan err retcode:%s", mRet.errcode)
        func(503)
        return
    end
    func(0)
end

function CVerifyMgr:ClientQRCodeLogin(sAccountToken, sCodeToken, mOther, mTransferInfo, endfunc)
    local mAccountInfo = self:VerifyMyToken(sAccountToken)
    if not mAccountInfo then
        record.info("ClientQRCodeLogin err: no such sAccountToken:%s", sAccountToken)
        endfunc(401)
        return
    end

    local sAccount = mAccountInfo.account
    local iChannel = mAccountInfo.channel
    local sCpsChannel = mAccountInfo.cps
    local iPlatform = mAccountInfo.platform
    local sPublisher = mAccountInfo.publisher or "kaopu"
    
    local func
    func = function (mInfo)
        self:_ClientQRCodeLogin1(sCodeToken, mTransferInfo, mInfo, endfunc)
    end

    local mResult = {
        token = self:GenerateMyToken(sAccount, iChannel, mAccountInfo.cps, iPlatform,sPublisher)
    }
    self:RequestServerInfo(iChannel, iPlatform, sCpsChannel, mOther, function (errcode, mInfo)
        self:OnGetServerList(errcode, mInfo, sAccount, iChannel, iPlatform,mOther,mResult, func)
    end)
end

function CVerifyMgr:_ClientQRCodeLogin1(sCodeToken, mTransferInfo, mInfo, endfunc)
    if mInfo.errcode ~= 0 then
        endfunc(mInfo.errcode)
        return
    end

    local qrc_key = string.match(sCodeToken, "^(%w+)%-%d+")
    local iPort = tonumber(string.match(qrc_key, "%a+(%d+)"))
    local sQrcPorts = serverdefines.get_qrcode_ports()
    local lQrcPorts = split_string(sQrcPorts, ",", tonumber)
    if not table_in_list(lQrcPorts,iPort)  then
        record.error("_ClientQRCodeLogin1 err: no such qrc_key:%s %s", sCodeToken, qrc_key)
        endfunc(402)
        return
    end

    router.Request("cs", string.format(".%s",qrc_key) , "common", "CSSendAccountInfo", {
        code_token = sCodeToken,
        acount_info = httpuse.mkcontent_json(mInfo),
        transfer_info = httpuse.mkcontent_json(mTransferInfo),
    }, function (mRecord, mData)
        self:_ClientQRCodeLogin2(mData, endfunc)
    end)
end

function CVerifyMgr:_ClientQRCodeLogin2(mRet, func)
    if mRet.errcode ~= 0 then
        record.error("_ClientQRCodeLogin2 err retcode:%s", mRet.errcode)
        func(403)
        return
    end
    func(0)
end