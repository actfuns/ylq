local global = require "global"
local httpuse = require "public.httpuse"
local record = require "public.record"
local md5 = require "md5"
local interactive = require "base.interactive"

local gamedb = import(lualib_path("public.gamedb"))
local urldefines = import(lualib_path("public.urldefines"))

function NewGamePushMgr(...)
    local o = CGamePushMgr:New(...)
    return o
end

CGamePushMgr = {}
CGamePushMgr.__index = CGamePushMgr
inherit(CGamePushMgr, logic_base_cls())

function CGamePushMgr:New()
    local o = super(CGamePushMgr).New(self)
    o.m_mData = {}
    o.m_mToken = {}
    o.m_mErrNotify = {}
    o.m_mMessage = {}
    o.m_mSign = {}
    o:InitData()
    return o
end

function CGamePushMgr:Init()
    self:SetData("android_access_id", 2100266669)
    self:SetData("android_secret_key", "0d2b42f0cb385e4e7118d8977ae823b4")
    self:SetData("ios_access_id",2200266625)
    self:SetData("ios_secret_key", "a63b3284f3f1776b35a93a61ad45f8f6")
end

function CGamePushMgr:InitData()
    local f
    f = function ()
        self:NotifyErr()
        self:DelTimeCb("notifyerr")
        self:AddTimeCb("notifyerr",10*60*1000,f)
    end
    self:AddTimeCb("notifyerr",10*60*1000,f)
    local f2
    f2 = function ()
        self:CheckCleanSign()
        self:DelTimeCb("cleansign")
        self:AddTimeCb("cleansign",60*1000,f2)
    end
    self:AddTimeCb("cleansign",60*1000,f2)
end

function CGamePushMgr:SetData(k, v)
    self.m_mData[k] = v
end

function CGamePushMgr:GetData(k, default)
    return self.m_mData[k] or default
end

function CGamePushMgr:GetPlatformPushParam(iPlatform)
    local mParam = {}
    -- 应用唯一标识符
    mParam.access_id = self:GetData("android_access_id")
    if iPlatform == 3 then
        mParam.access_id = self:GetData("ios_access_id")
        mParam.environment = 1
    end
    return mParam
end

function CGamePushMgr:GetSecretKey(iPlatform)
    local sSecretKey = self:GetData("android_secret_key")
    if iPlatform == 3 then
        sSecretKey = self:GetData("ios_secret_key")
    end
    return sSecretKey
end

function CGamePushMgr:Push(iPid,sTitle,sText)
    local mData = self.m_mToken[iPid]
    if mData then
        local iPlatform = mData["p"]
        local sToken = mData["t"]
        self:PushTrue(iPid,iPlatform,sToken,sTitle,sText)
    else
        local mData = {
            pid = iPid,
        }
        local mArgs = {
            module = "gamepush",
            cmd = "GetXGToken",
            data = mData
        }
        gamedb.LoadDb(iPid,"common", "LoadDb", mArgs, function (mRecord, mData)
            local iPid = mData.pid
            local m = mData.data or {}
            local iPlatform = m.platform
            local sToken = m.token
            if not iPlatform or not sToken then
                return
            end
            if not iPid then
                print("hcdebug,gamepush",mData)
                return
            end
            self:AddToken(iPid,iPlatform,sToken)
            self:PushTrue(iPid,iPlatform,sToken,sTitle,sText)
        end)
    end
end

function CGamePushMgr:PushById(iPid, id)
    local res = require "base.res"
    local mData = res["daobiao"]["gamepush"][id]
    if mData then
        self:Push(iPid, mData.title, mData.text)
    else
        record.error("GamePush, PushById:", iPid, id)
    end
end

function CGamePushMgr:ValidPush(iPlatform)
    if iPlatform == 4 then
        return false
    end
    return true
end

function CGamePushMgr:PushTrue(iPid,iPlatform,sToken,sTitle, sText)
    if not self:ValidPush(iPlatform) then
        return
    end
    local host = urldefines.get_out_host()
    local url = urldefines.get_xg_url("single_device")
    local mParam = self:GetPlatformPushParam(iPlatform)
    mParam.timestamp = get_time()                   -- 请求时间戳
    mParam.device_token = sToken
    mParam.multi_pkg = 1
    mParam.message_type = 1
    mParam.message = self:GetMessage(sTitle,sText)

    local sSignKey = string.format("%s%s%s%s%s",sToken,iPlatform,get_time(),sTitle,sText)
    mParam.sign = self:GetSign(sSignKey,host, url, mParam,iPlatform)
    local mHeader = {}
    mHeader["Content-type"] = "application/x-www-form-urlencoded"
    local func = function (body, header)
        self:PushResult(iPid, body)
    end
    httpuse.post(host, url, httpuse.mkcontent_kv(mParam), func, mHeader)
end

function CGamePushMgr:GetMessage(sTitle,sText)
    local sKey = string.format("%s%s",sTitle,sText)
    if self.m_mMessage[sKey] then
        return self.m_mMessage[sKey]
    end
    local sMessage = httpuse.mkcontent_json({
        title = sTitle,
        content = sText,
        builder_id = 0,
    })
    self.m_mMessage[sKey] = sMessage
    return sMessage
end

function CGamePushMgr:GetSign(sSignKey,host, url, mParam,iPlatform)
    local mSignData = self.m_mSign[sSignKey]
    if mSignData then
        return mSignData.sign
    end
    local sSign = self:Sign(host,url,mParam,iPlatform)
    self.m_mSign[sSignKey] = {
        sign = sSign,
        time = get_time()
    }
    return sSign
end

function CGamePushMgr:Sign(host, url, mParam,iPlatform)
    local sStr = "POSTopenapi.xg.qq.com"..string.sub(url, string.len("/xgpush/"))
    local lKey = table_key_list(mParam)
    table.sort(lKey)
    for _, sKey in ipairs(lKey) do
        sStr = sStr..sKey.."="..mParam[sKey]
    end
    local sSecretKey = self:GetSecretKey(iPlatform)
    sStr = sStr..sSecretKey
    return md5.sumhexa(sStr)
end

function CGamePushMgr:PushResult(iPid, sBody)
    local mBody = httpuse.content_json(sBody)
    if not mBody or mBody.ret_code ~= 0 then
        self:DeleteToken(iPid)
        local sMsg = string.format("XGPush err %s %s", iPid, sBody)
        table.insert(self.m_mErrNotify,sMsg)
    end
end

function CGamePushMgr:OnLogin(iPid,mData)
    local iPlatform = mData["platform"]
    local sToken = mData["token"]
    if table_in_list({"","0","null"},sToken) then
        return
    end
    self:AddToken(iPid,iPlatform,sToken)
    local mData = {
        pid = iPid,
        platform = iPlatform,
        token = sToken,
    }
    gamedb.SaveDb(iPid,"common", "SaveDb",{module = "gamepush",cmd = "SetXGToken",data = mData})
end

function CGamePushMgr:NewHour(iDay,iHour)
    self:CheckActive()
end

function CGamePushMgr:AddToken(iPid,iPlatform,sToken)
    self.m_mToken[iPid]={
        p = iPlatform,
        t = sToken,
        h = get_hourno(),
    }
end

function CGamePushMgr:DeleteToken(iPid)
    self.m_mToken[iPid] = nil
    local mData = {
        pid = iPid,
    }
    gamedb.SaveDb(iPid,"common", "SaveDb",{module = "gamepush",cmd = "DeleteXGToken",data = mData})
end

function CGamePushMgr:GetPlatform(iPid)
    local mData = self.m_mToken[iPid]
    if not mData then
        return
    end
    return mData["p"]
end

function CGamePushMgr:GetXGToken(iPid)
    local mData = self.m_mToken[iPid]
    if not mData then
        return
    end
    return mData["t"]
end

function CGamePushMgr:CheckActive()
    local iNowHourNo = get_hourno()
    local mDelete = {}
    for iPid,mData in pairs(self.m_mToken) do
        local iHourNo = mData["h"]
        if iNowHourNo - iHourNo >= 24  then
            mDelete[iPid] = true
        end
    end
    for iPid,_ in pairs(mDelete) do
        self.m_mToken[iPid] =nil
    end
end

function CGamePushMgr:CheckCleanSign()
    local mDelete = {}
    for sSignKey,mData in pairs(self.m_mSign) do
        local iTime = mData.time or 0
        if get_time() - iTime > 10 then
            table.insert(mDelete,sSignKey)
        end
    end
    for _,sSignKey in pairs(mDelete) do
        self.m_mSign[sSignKey] = nil
    end
end

function CGamePushMgr:NotifyErr()
    if table_count(self.m_mErrNotify) <= 0 then
        return
    end
    local sMsg = ""
    for _,sErr in ipairs(self.m_mErrNotify) do
        sMsg = sMsg .. string.format("%s \n",sErr)
    end
    self.m_mErrNotify = {}
    record.info(sMsg)
end

function CGamePushMgr:CheckAccountToken(sAccount,iPlatform)
    local host = urldefines.get_out_host()
    local url = "/xgpush/v2/application/get_app_account_tokens"
    local mParam = self:GetPlatformPushParam(iPlatform)
    mParam.timestamp = get_time()                   -- 请求时间戳
    mParam.account = sAccount

    mParam.sign = self:Sign(host,url,mParam,iPlatform)
    local mHeader = {}
    mHeader["Content-type"] = "application/x-www-form-urlencoded"
    local func = function (body, header)
        print("hcdebug,xgpush:CheckAccountToken",sAccount,body)
    end
    httpuse.post(host, url, httpuse.mkcontent_kv(mParam), func, mHeader)
end

function CGamePushMgr:CheckToken(sToken,iPlatform)
    local host = urldefines.get_out_host()
    local url = "/xgpush/v2/application/get_app_token_info"
    local mParam = self:GetPlatformPushParam(iPlatform)
    mParam.timestamp = get_time()                   -- 请求时间戳
    mParam.device_token = sToken

    mParam.sign = self:Sign(host,url,mParam,iPlatform)
    local mHeader = {}
    mHeader["Content-type"] = "application/x-www-form-urlencoded"
    local func = function (body, header)
        print("hcdebug,xgpush:CheckToken",body)
    end
    httpuse.post(host, url, httpuse.mkcontent_kv(mParam), func, mHeader)
end