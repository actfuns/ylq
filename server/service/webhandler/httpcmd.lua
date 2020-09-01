--import module
local global = require "global"
local skynet = require "skynet"
local cjson = require "cjson"
local interactive = require "base.interactive"
local record = require "public.record"
local serverdefines = require "public.serverdefines"
local httpuse = require "public.httpuse"

local analy = import(lualib_path("public.dataanaly"))

Method = {}

Method.backend = {
    POST = true
}
function backend(oHttp)
    local br, mData = pcall(cjson.decode, oHttp:GetBody())
    if not br then
        record.error("httpcmd backend error body null")
        oHttp:Finish()
        return
    end
    local sModule = mData.module
    local sCmd = mData.cmd
    local mArgs = mData.args
    if sModule and sCmd then
        interactive.Request(".backend", sModule, sCmd, mArgs, function (mRecord, mData)
            local sRes = cjson.encode(mData)
            oHttp:Response(sRes)
            oHttp:Finish()
        end)
    else
        oHttp:Finish()
    end
end

local function get_loginverify_service(sToken)
    local iNo
    if sToken then
        iNo = string.match(sToken, "%w+_(%d+)")
    else
        iNo = math.random(1, VERIFY_SERVICE_COUNT)
    end
    return string.format(".loginverify%s",iNo)
end

Method.loginverify = {
    POST = true
}
function loginverify(oHttp)
    local sMethod = oHttp:GetAddress()[1]
    local br, mArgs = pcall(cjson.decode, oHttp:GetBody())
    if not br then
        record.error(string.format("httpcmd loginverify error body null Method:%s", sMethod))
        oHttp:Finish()
        return
    end
    if sMethod == "verify_account" then
        local sServiceName = string.format(".loginverify%d",math.random(VERIFY_SERVICE_COUNT))
        interactive.Request(sServiceName, "common", "ClientVerifyAccount", mArgs,
        function(mRecord, mData)
            local sRes = cjson.encode(mData)
            oHttp:Response(sRes)
            oHttp:Finish()
        end)
    elseif sMethod == "qrcode_scan" then
        local sServiceName = get_loginverify_service(mArgs.account_token)
        interactive.Request(sServiceName, "common", "ClientQRCodeScan", mArgs,
        function(mRecord, mData)
            local sRes = cjson.encode(mData)
            oHttp:Response(sRes)
            oHttp:Finish()
        end)
    elseif sMethod == "qrcode_login" then
        local sServiceName = get_loginverify_service(mArgs.account_token)
        interactive.Request(sServiceName, "common", "ClientQRCodeLogin", mArgs,
        function(mRecord, mData)
            local sRes = cjson.encode(mData)
            oHttp:Response(sRes)
            oHttp:Finish()
        end)
    end
end

Method.paycb = {
    POST = true
}
function paycb(oHttp)
    local mBody = httpuse.content_kv(oHttp:GetBody())
    if mBody and next(mBody) then
        local service = string.format(".pay%s", math.random(1, PAY_SERVICE_COUNT))
        interactive.Request(service, "common", "PayCallback", mBody,
        function(mRecord, mData)
            oHttp:Response(mData.ret)
            oHttp:Finish()
        end)
    else
        record.error("httpcmd paycb error body null")
        oHttp:Finish()
    end
end

Method.clientdata = {
    POST = true
}
function clientdata(oHttp)
    local br, mLog = pcall(cjson.decode, oHttp:GetBody())
    if not br then
        record.error("httpcmd clientdata error body null")
        oHttp:Finish()
        return
    end
    mLog = mLog or {}
    local sName = mLog.logname
    mLog.logname = nil
    local sLogName = sName
    local sChannel = mLog.app_channel
    if sChannel ~= "sm" then
        sLogName = "CBT" .. sName
    end
    if  sName and table_in_list({"RoleUi","UpdateGameStart","UpdateGameEnd","StartGame"},sName) then
        analy.log_data(sLogName,mLog)
        local sRes = cjson.encode({ret=0})
        oHttp:Response(sRes)
        oHttp:Finish()
    else
        local sRes = cjson.encode({ret=-1})
        oHttp:Response(sRes)
        oHttp:Finish()
    end
end

Method.notice = {
    POST = true,
    GET = true
}

local AnalyQuery = function (sQuery)
    local mData = {}
    local l1 = split_string(sQuery,"&")
    for k,v in pairs(l1) do
        local l2 = split_string(v,"=")
        mData[l2[1]] = tonumber(l2[2]) or l2[2]
    end
    return mData
end

function notice(oHttp)
    local bSuc,msg = true,""
    local mAddress = oHttp:GetAddress()
    if not mAddress then
        bSuc = false
        msg = "httpcmd notice error address null"
    end
    local sModule,sCmd = mAddress[1],mAddress[2]
    if not sModule then
        bSuc = false
        msg = "httpcmd notice error module null"
    end
    if not sCmd then
        bSuc = false
        msg = "httpcmd notice error cmd null"
    end
    if not bSuc then
        oHttp:Finish()
        return
    end
    if sModule == "yybao" then
        yybao(oHttp,sModule,sCmd)
    end
end

function yybao(oHttp,sModule,sCmd)
    local mArgs = {}
    if oHttp:GetMethod() == "GET" then
        mArgs = AnalyQuery(oHttp:GetQuery()) --GetQuery
    elseif oHttp:GetMethod() == "POST" then
        mArgs = AnalyQuery(oHttp:GetBody())
    end
    local mData = {args=mArgs,cmd=sCmd}
    if mData then
        local iNo = math.random(2,EXTERNAL_SERVICE_COUNT)
        local sService = ".external"..iNo
        if sCmd == "RewardHDGift" then
            sService = ".external1"
        end
        interactive.Request(sService, sModule, "ForwardCmd", mData, function (mRecord, mBack)
            local sRes = cjson.encode(mBack)
            oHttp:Response(sRes)
            oHttp:Finish()
        end)
    else
        oHttp:Finish()
    end
end