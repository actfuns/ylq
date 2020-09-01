--import module

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local extype = require "base.extype"
local res = require "base.res"
local record = require "public.record"
local cjson = require "cjson"
local router = require "base.router"

local gamedb = import(lualib_path("public.gamedb"))
local analy = import(lualib_path("public.dataanaly"))
local status = import(lualib_path("base.status"))
local bigpacket = import(lualib_path("public.bigpacket"))
local gamedefines = import(lualib_path("public.gamedefines"))
local serverop = import(lualib_path("public.serverop"))
local whiteaccount = import(service_path("whiteaccount"))
local version = import(lualib_path("public.version"))
local account = import(lualib_path("public.account"))
local serverinfo = import(lualib_path("public.serverinfo"))
local ipoperate = import(lualib_path("public.ipoperate"))

LOGIN_QUEUE_LIMIT = 100
WAIT_PUSH_NUM = 200

lBanDevice = {
    "00:81:5d:10:3f:40",
}

function NewGateMgr(...)
    local o = CGateMgr:New(...)
    return o
end

function NewGate(...)
    local o = CGate:New(...)
    return o
end

function NewConnection(...)
    local o = CConnection:New(...)
    return o
end

CConnection = {}
CConnection.__index = CConnection
inherit(CConnection, logic_base_cls())

function CConnection:New(source, handle, ip, port)
    local o = super(CConnection).New(self)
    o.m_iGateAddr = source
    o.m_iHandle = handle

    o.m_sIP = ip
    o.m_iPort = port
    o.m_sAccount = nil
    o.m_iChannel = 0
    o.m_sCpsChannel = ""
    o.m_sClientOs = ""
    o.m_sAccountToken = nil
    o.m_iRoleCnt = 0
    o.m_oBigPacketMgr = bigpacket.CBigPacketMgr:New()

    o.m_oStatus = status.NewStatus()
    o.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.no_account)

    return o
end

function CConnection:Release()
    baseobj_safe_release(self.m_oStatus)
    super(CConnection).Release(self)
end

function CConnection:GetNetHandle()
    return self.m_iHandle
end

function CConnection:Send(sMessage, mData)
    net.Send({gate = self.m_iGateAddr, fd = self.m_iHandle}, sMessage, mData)
end

function CConnection:SendBig(sMessage,mData)
    bigpacket.SendBig({gate = self.m_iGateAddr, fd = self.m_iHandle}, sMessage, mData)
end

function CConnection:SetAccount(sAccount)
    self.m_sAccount = sAccount
end

function CConnection:GetAccount()
    return self.m_sAccount
end

function CConnection:SetChannel(iChannel)
    self.m_iChannel = iChannel
end

function CConnection:GetChannel()
    return self.m_iChannel or 0
end

function CConnection:SetCpsChannel(sCps)
    self.m_sCpsChannel = sCps
end

function CConnection:GetCpsChannel()
    return self.m_sCpsChannel
end

function CConnection:SetPlatform(iPlatform)
    self.m_iPlatform = iPlatform or 0
end

function CConnection:GetPlatform()
    return self.m_iPlatform or 0
end

--创角时平台,手盟发行混服角色可以互通
function CConnection:SetBornPlatform(iPlatform)
    self.m_iBornPlatform = iPlatform or self.m_iPlatform
end

function CConnection:GetBornPlatform()
    return self.m_iBornPlatform or self.m_iPlatform
end

function CConnection:SetPublisher(sPublisher)
    self.m_sPublisher = sPublisher or "kaopu"
end

function CConnection:GetPublisher()
    return self.m_sPublisher or "kaopu"
end

function CConnection:GetPlatformName()
    local sName = gamedefines.GetPlatformName(self.m_iPlatform)
    return sName or string.format("未知平台%s",self.m_iPlatform)
end

function CConnection:SetClientOs(sOs)
    self.m_sClientOs = sOs or self.m_sClientOs
end

function CConnection:GetClientOs(sOs)
    return self.m_sClientOs
end

function CConnection:SetDevice(sDevice)
    self.m_sDevice = sDevice or ""
end

function CConnection:GetDevice()
    return self.m_sDevice or ""
end

function CConnection:SetMac(sMac)
    self.m_sMac = sMac or ""
end

function CConnection:GetMac()
    return self.m_sMac or ""
end

function CConnection:SetUdid(sUdid)
    self.m_sUdid = sUdid
end

function CConnection:GetUdid()
    return self.m_sUdid or ""
end

function CConnection:SetClientVersion(sClientVersion)
    self.m_sClientVersion = sClientVersion
end

function CConnection:GetClientVersion()
    return self.m_sClientVersion
end

function CConnection:SetAccountToken(sToken)
    self.m_sAccountToken = sToken
end

function CConnection:GetAccountToken()
    return self.m_sAccountToken
end

function CConnection:SetIMEI(sIMEI)
    self.m_sIMEI = sIMEI
end

function CConnection:GetIMEI()
    return self.m_sIMEI
end

--是否扫码登录
function CConnection:SetQrcode(iQrcode)
    self.m_iQrcode = iQrcode
end

function CConnection:GetQrcode()
    return self.m_iQrcode
end

function CConnection:SetRoleCount(iRoleCnt)
    self.m_iRoleCnt = iRoleCnt
end

function CConnection:GetRoleCount()
    return self.m_iRoleCnt
end

function CConnection:QueryLogin(mData)
    local iHandle = self:GetNetHandle()
    local fCallback = function (mRecord,mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:QueryLogin2(mData)
        end
    end
    interactive.Request(".clientupdate","common","QueryLogin",mData,fCallback)
end

function CConnection:QueryLogin2(mData)
    local mClientResInfo = mData["res_file"] or {}
    if table_count(mClientResInfo["res_file"]) > 0 or mClientResInfo["code"] then
        self:SendBig("GS2CQueryLogin",{delete_file = mClientResInfo["delete_file"],res_file = mClientResInfo["res_file"],code=mClientResInfo["code"]})
    else
        self:Send("GS2CQueryLogin",{delete_file = mClientResInfo["delete_file"],res_file = mClientResInfo["res_file"],code =mClientResInfo["code"]})
    end
end

function CConnection:LoginAccount(mData)
    local sAccount = mData.account
    local sToken = mData.token
    if (not sToken or sToken == "") and (is_production_env() or not sAccount or sAccount == "") then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.error_account_env})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end
    local iClientVersion = mData.client_svn_version
    if iClientVersion ~= version.CLIENT_VERSION and is_production_env() then
        self:Send("GS2CLoginError",{pid = 0,errcode = gamedefines.ERRCODE.client_version_error})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local iStatus = self.m_oStatus:Get()
    assert(iStatus, "connection status is nil")
    local oGateMgr = global.oGateMgr
    if iStatus ~= gamedefines.LOGIN_CONNECTION_STATUS.no_account then
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    self:SetMac(mData.mac)
    self:SetDevice(mData.device)
    self:SetPlatform(mData.platform)
    self:SetClientOs(mData.os)
    self:SetUdid(mData.udid)
    self:SetClientVersion(mData.client_version)
    self:SetIMEI(mData.imei)
    self:SetQrcode(mData.is_qrcode)

    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.in_login_account)
    if sToken and sToken ~= "" then
        self:SetAccountToken(sToken)
        local iHandle = self:GetNetHandle()
        self:InitAccountInfo(sToken, function (errcode)
            local oConn = global.oGateMgr:GetConnection(iHandle)
            if oConn then
                oConn:_LoginAccount1(errcode)
            end
        end)
    else
        self:SetChannel(0)
        self:SetAccount(sAccount)
        self:_LoginAccount1(0)
    end
end

function CConnection:InitAccountInfo(sToken, endfunc)
    local mContent = {
        token = sToken,
    }
    local iHandle = self:GetNetHandle()
    local fCallback = function (mRecord,mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_InitAccountInfo1(mData,sToken,endfunc)
        end
    end
    local iNo = string.match(sToken, "%w+_(%d+)")
    local sServiceName = string.format(".loginverify%s",iNo)
    router.Request("cs",sServiceName,"common","GSGetVerifyAccount",mContent,fCallback)
end

function CConnection:_InitAccountInfo1(mData, sToken, endfunc)
    if mData.errcode ~= 0 then
        endfunc(2)
        return
    end
    local mAccount = mData.account

    self:SetAccount(mAccount.account)
    self:SetChannel(mAccount.channel)
    self:SetCpsChannel(mAccount.cps)
    self:SetBornPlatform(mAccount.platform)
    self:SetPublisher(mAccount.publisher)
    endfunc(0)
end

function CConnection:_LoginAccount1(errcode)
    if errcode ~= 0 then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.invalid_token})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local iPlatform = self:GetPlatform()
    local iChannel = self:GetChannel()
    if iPlatform and not serverinfo.is_matched_platform(iPlatform) then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.invalid_platform})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end
    if iChannel ~= 0 and not serverinfo.is_opened_channel(iChannel) then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.invalid_channel})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local oGateMgr = global.oGateMgr
    local sAccount = self:GetAccount()

    if not oGateMgr:IsOpen() and not oGateMgr:ValidPlayerLogin(sAccount, iChannel, self.m_sIP) then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.in_maintain})
        return
    end

    local bNeedInviteCode = res["daobiao"]["global_control"]["invitecode"]["is_open"]
    if bNeedInviteCode == "y" and is_production_env() then
        self:CheckInviteCode()
    else
        self:_CheckInviteCodeEnd(1,"邀请码验证已关闭")
    end
end

function CConnection:CheckInviteCode()
    local sAccount = self:GetAccount()
    local iHandle = self:GetNetHandle()
    local mData = {
        account = sAccount,
    }
    local mArgs = {
        module = "invitecodedb",
        cmd = "GetAcountInviteCode",
        data = mData
    }
    gamedb.LoadDb("login","common", "LoadDb", mArgs, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_CheckInviteCode1(mRecord, mData)
        end
    end)
end

function CConnection:_CheckInviteCode1(mRecord,mData)
    local sInviteCode = mData.data and mData.data.invitecode or nil
    if not sInviteCode then
        self:_CheckInviteCodeEnd(false,"")
        return
    end
    local iInvitetime = mData.data.createtime
    local iLastDay = mData.data.lastday
    local iTime = get_time()
    if (iTime - iInvitetime) > iLastDay*24*60*60 then
        self:_CheckInviteCodeEnd(false,"邀请码已过期,请输入新的邀请码")
        return
    end
    self:_CheckInviteCodeEnd(true,"邀请码有效")
end

function CConnection:_CheckInviteCodeEnd(bResult,sMsg)
    if not bResult then
        self:Send("GS2CCheckInviteCodeResult", {result = 0, msg = sMsg})
        return
    end
    self:Send("GS2CCheckInviteCodeResult", {result = 1, msg = sMsg})
    self:JumpInviteCode()
end

function CConnection:JumpInviteCode()
    local sAccount = self:GetAccount()
    local iChannel = self:GetChannel()
    local iPlatform = self:GetBornPlatform()
    local iHandle = self:GetNetHandle()
    local mData = {
        account = sAccount,
        channel = iChannel,
        platform = iPlatform,
        publisher = self:GetPublisher(),
    }
    local mArgs = {
        module = "playerdb",
        cmd = "GetPlayerListByAccount",
        data = mData
    }
    gamedb.LoadDb("login","common", "LoadDb", mArgs, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_LoginAccount2(mRecord, mData)
        end
    end)
end

function CConnection:_LoginAccount2(mRecord, mData)
    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)
    local iChannel = self:GetChannel()
    local lRet = {}
    local lData = mData.data
    for _, v in ipairs(lData) do
        if not v.deleted then
            local iPlatform = v.platform
            if serverinfo.is_matched_platform(iPlatform) then
                local mBase = v.base_info or {}
                local mModelInfo = mBase.model_info or {}
                local mModel = {
                    shape = mModelInfo.shape,
                    scale = mModelInfo.scale,
                    color = mModelInfo.color,
                    mutate_texture = mModelInfo.mutate_texture,
                    weapon = mModelInfo.weapon,
                    adorn = mModelInfo.adorn,
                }
                table.insert(lRet, {pid = v.pid, grade = mBase.grade, name = mBase.name, model_info = mModel})
            end
        end
    end
    self.m_HistoryRoleCnt = #lData
    local iRoleCnt = table_count(lRet)
    self:SetRoleCount(iRoleCnt)
    self:Send("GS2CLoginAccount", {account = mData.account,channel = self:GetChannel(),role_list = lRet})
    analy.log_data("LoginAccount",self:GetPubAnalyData())
end

--账号对应角色数目
function CConnection:CheckAccountRoleAmount(fCallback)
    local sAccount = self:GetAccount()
    local iChannel = self:GetChannel()
    local iPlatform = self:GetBornPlatform()
    local iHandle = self:GetNetHandle()
    local mData = {
        account = sAccount,
        channel = iChannel,
        platform = iPlatform,
        publisher = self:GetPublisher(),
    }
    local mArgs = {
        module = "playerdb",
        cmd = "GetPlayerListByAccount",
        data = mData
    }
    gamedb.LoadDb("login","common", "LoadDb", mArgs, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:CheckAccountRoleAmount2(mRecord, mData,fCallback)
        end
    end)
end

function CConnection:CheckAccountRoleAmount2(mRecord,mData,fCallback)
    local iCnt = 0
    local lData = mData.data or {}
    for _, v in ipairs(lData) do
        if not v.deleted then
            local iPlatform = v.platform
            if serverinfo.is_matched_platform(iPlatform) then
                iCnt = iCnt + 1
            end
        end
    end
    if iCnt >=1 then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.role_max_limit})
        return
    else
        fCallback()
    end
end

function CConnection:CreateRole(mData)
    local iHandle = self:GetNetHandle()
    local fCallback = function ()
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:TrueCreateRole(mData)
        end
    end
    self:CheckAccountRoleAmount(fCallback)
end

function CConnection:TrueCreateRole(mData)
    local iStatus = self.m_oStatus:Get()
    assert(iStatus, "connection status is nil")
    local oGateMgr = global.oGateMgr

    if iStatus ~= gamedefines.LOGIN_CONNECTION_STATUS.login_account then
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    if self:GetRoleCount() >= 1 then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.role_max_limit})
        return
    end
    if not global.oGateMgr:IsValidName(mData.name) then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.name_exist})
        return
    end
    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.in_create_role)

    local sAccount = mData.account
    local iRoleType = mData.role_type
    local sName = mData.name

    local mRoleType = res["daobiao"]["roletype"]
    local mInfo = mRoleType[iRoleType]
    if not mInfo or sAccount ~= self:GetAccount() then
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end
    local iHandle = self:GetNetHandle()
    local mData = {
        name = sName
    }
    local mRequstData = {
        module = "namecounter",
        cmd = "InsertNewNameCounter",
        data = mData
    }
    gamedb.LoadDb("login","common", "LoadDb",mRequstData, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_CreateRole1(mRecord, mData, iRoleType, sName)
        end
    end)
end

function CConnection:_CreateRole1(mRecord,mData,iRoleType, sName)
    if not mData.success then
        self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.name_exist})
        return
    end
    local mRoleType = res["daobiao"]["roletype"]
    local mInfo = mRoleType[iRoleType]
    local iSchool = mInfo.school

    local mContent = {
        server = get_server_tag(),
        born_server = get_server_tag(),
        account = self:GetAccount(),
        channel = self:GetChannel(),
        platform = self:GetBornPlatform(),
        publisher = self:GetPublisher(),
        name = sName,
        school = iSchool,
        icon = mInfo.shape,
    }
    local iHandle = self:GetNetHandle()
    local fCallback = function (mRecord,mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_CreateRole2(mData,iRoleType,sName,iSchool)
        end
    end
    router.Request("cs",".datacenter","common","TryCreateRole",mContent,fCallback)
end

function CConnection:_CreateRole2(mData, iRoleType, sName)
    local id = mData.id
    if not id then
        self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.error_id})
        return
    end
    local mRoleType = res["daobiao"]["roletype"]
    local mInfo = mRoleType[iRoleType]


    local mCreateInfo = self:GetCreateInfo(self:GetAccount(), id, mInfo)
    mCreateInfo.name = sName
    local mData = {
        data = mCreateInfo,
    }
    gamedb.SaveDb("login", "common", "SaveDb", {
        module = "playerdb",
        cmd = "CreatePlayer",
        data = mData,
    })
    mData = {
        data = {
            pid = id,
        }
    }
    gamedb.SaveDb("login","common", "SaveDb", {
        module = "offlinedb",
        cmd = "CreateOffline",
        data = mData
    })
    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)

    self:Send("GS2CCreateRole", {account = self:GetAccount(),channel = self:GetChannel(), role = {
        pid = id,
        grade = mCreateInfo.base_info.grade,
        name = sName,
        model_info = {
            shape = mCreateInfo.base_info.model_info.shape,
            scale = mCreateInfo.base_info.model_info.scale,
            color = mCreateInfo.base_info.model_info.color,
            mutate_texture = mCreateInfo.base_info.model_info.mutate_texture,
            weapon = mCreateInfo.base_info.model_info.weapon,
            adorn = mCreateInfo.base_info.model_info.adorn,
        }
    }})
    local iRoleCnt = self:GetRoleCount()
    if iRoleCnt and iRoleCnt == 0 then
        record.user("account","create",{ account=self:GetAccount(),platform=self:GetPlatformName(),channel=self:GetChannel() })
        analy.log_data("RegisterAccount",self:GetPubAnalyData())
    end
    self:SetRoleCount(iRoleCnt + 1)
    record.user("player","newrole",{
        pid=id,
        platform=self:GetPlatformName(),
        channel=self:GetChannel(),
        account=self:GetAccount(),
        name = sName,
        grade = mCreateInfo.base_info.grade,
        school = mCreateInfo.base_info.school,
        shape = mCreateInfo.base_info.model_info.shape,
    })
    local mLog = self:GetPubAnalyData()
    mLog["role_id"] = mCreateInfo.pid
    mLog["role_name"] = sName
    mLog["role_level"] = mCreateInfo.base_info.grade
    mLog["fight_point"] = 0
    mLog["profession"] = mCreateInfo.base_info.school
    mLog["outside"] = tostring(mCreateInfo.base_info.model_info.shape)
    analy.log_data("CreatRole",mLog)
end

function CConnection:GetPubAnalyData()
    return {
        account_id = self:GetAccount(),ip = self.m_sIP,
        device_model = self:GetDevice(),udid = self:GetUdid(),
        os = self:GetClientOs(),version = "1.0",
        app_channel = self:GetChannel(),sub_channel = self:GetCpsChannel(),
        server = MY_SERVER_KEY,plat = self:GetBornPlatform(),is_qrcode = self:GetQrcode(),
    }
end

function CConnection:GetCreateInfo(sAccount, iPid, mExtend)
    mExtend = mExtend or {}
    local mData = {
            pid = iPid,
            account = sAccount,
            channel = self:GetChannel(),
            platform = self:GetBornPlatform(),
            born_server = get_server_tag(),
            now_server = get_server_tag(),
            publisher = self:GetPublisher(),
            deleted = false,
            base_info = {
                grade = 1,
                sex = mExtend.sex,
                school = mExtend.school,
                name = string.format("DEBUG%d", iPid),
                model_info = {
                    shape = mExtend.shape,
                    scale = 0,
                    color = {0,},
                    mutate_texture = 0,
                    weapon = 0,
                    adorn = 0,
                },
                create_time = get_time(),
                platform = self:GetPlatformName(),
            },
            active_info = { scene_info = {
                map_id = 101000,
                pos = {
                    x = 27,
                    y = 25,
                    z = 0,
                    face_x = 0,
                    face_y = 0,
                    face_z = 0,
                },
            }},
        }
        return mData
end

function CConnection:LoginRole(mData)
    local iStatus = self.m_oStatus:Get()
    assert(iStatus, "connection status is nil")
    local oGateMgr = global.oGateMgr

    if iStatus ~= gamedefines.LOGIN_CONNECTION_STATUS.login_account then
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local iChannel = self:GetChannel()
    local iPlatform = self:GetPlatform()
    if iChannel ~= 0 and not serverinfo.is_opened_channel(iChannel) then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.invalid_channel})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end
    if iPlatform and not serverinfo.is_matched_platform(iPlatform) then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.invalid_platform})
        global.oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.in_login_role)

    local pid = mData.pid

    local iHandle = self:GetNetHandle()
    local mData = {
        pid = pid
    }
    gamedb.LoadDb("login","common", "LoadDb", {module = "playerdb",cmd="GetPlayer",data = mData}, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_LoginRole1(mRecord,mData)
        end
    end)
end

function CConnection:InBanLogin(sAccount,iPid)
    local oPunishMgr = global.oPunishMgr
    local iTime = oPunishMgr:InActBan(sAccount)
    if iTime then
        self:Send("GS2CNotify", {
            cmd = "您的账号处于封禁状态，将于"..get_second2string(iTime).."后解除",
        })
        return true
    end
    local iTime = oPunishMgr:InRoleBan(iPid)
    if iTime then
        self:Send("GS2CNotify", {
            cmd = "您的角色处于封禁状态，将于"..get_second2string(iTime).."后解除",
        })
        return true
    end
    if table_in_list(lBanDevice,self:GetMac()) then
        self:Send("GS2CNotify", {
            cmd = "网络异常，请检查网络",
        })
        return true
    end
    return false
end

function CConnection:_LoginRole1(mRecord, mData)
    local oGateMgr = global.oGateMgr

    local m = mData.data
    if not m or (m and m.account ~= self:GetAccount() and m.channel ~= self:GetChannel()) then
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    if m.ban_time and m.ban_time > get_time() then
        self:Send("GS2CNotify", {
            cmd = "账号已被封停，请联系客服",
        })
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    if self:InBanLogin(m.account,mData.pid) then
        oGateMgr:KickConnection(self.m_iHandle)
        return
    end

    local sAccountToken = self:GetAccountToken()
    local sRoleToken = oGateMgr:DispatchRoleToken()

    local mBaseData = m.base_info or {}
    oGateMgr:EnterLoginQueue(mData.pid,{
        conn = {
            handle = self.m_iHandle,
            gate = self.m_iGateAddr,
            ip = self.m_sIP,
            port = self.m_iPort,
        },
        role = {
            account = self:GetAccount(),
            pid = mData.pid,
            born_server = m.born_server,
            account_token = sAccountToken,
            role_token = sRoleToken,
            channel = self:GetChannel(),
            cps = self:GetCpsChannel(),
            mac = self:GetMac(),
            device = self:GetDevice(),
            imei = self:GetIMEI(),
            platform = self:GetPlatform(),
            born_platform = self:GetBornPlatform(),
            is_qrcode = self:GetQrcode(),
            publisher = self:GetPublisher(),
            create_time = mBaseData.create_time,
            scene_model = mData.scene_model or 1,
            client_version = self:GetClientVersion(),
            client_os = self:GetClientOs(),
            udid = self:GetUdid(),
        }
    })
end

function CConnection:LoginResult(mData)
    local iErrcode = mData.errcode
    local pid = mData.pid
    local sToken = mData.token
    local oGateMgr = global.oGateMgr
    oGateMgr:LeaveLoginQueue(pid)
    if iErrcode == gamedefines.ERRCODE.ok then
        self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_role)
        self:Add2TokenCache(pid,sToken)
    else
        self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)
        self:Send("GS2CLoginError", {pid = pid, errcode = iErrcode})
    end
end

function CConnection:SetInviteCode(mData)
    local sInviteCode = mData.invitecode
    sInviteCode = string.upper(sInviteCode)
    local mInviteCode = res["daobiao"]["invitecode"]
    if not mInviteCode[sInviteCode] then
        self:Send("GS2CSetInviteCodeResult",{result=0,msg="邀请码不存在"})
        return
    end
    local iLastTime = tonumber(mInviteCode[sInviteCode]["lastday"])
    local iCreateTime = getTimeByDate(mInviteCode[sInviteCode]["create_time"])
    local iNowTime = get_time()
    if (iNowTime - iCreateTime) > iLastTime*24*60*60 then
        self:Send("GS2CSetInviteCodeResult",{result=0,msg="邀请码已过期"})
        return
    end

    local iHandle = self:GetNetHandle()
    local mData = {
        invitecode = sInviteCode,
    }
    gamedb.LoadDb("login","common", "LoadDb", {module="invitecodedb",cmd="GetInviteCode",data=mData}, function (mRecord, mData)
        local oConn = global.oGateMgr:GetConnection(iHandle)
        if oConn then
            oConn:_SetInviteCode1(mRecord, mData,sInviteCode,iLastTime,iCreateTime,iNowTime)
        end
    end)
end

function CConnection:_SetInviteCode1(mRecord, mData,sInviteCode,iLastTime,iCreateTime,iNowTime)
    if mData.data and mData.data.account then
        self:Send("GS2CSetInviteCodeResult",{result=0,msg="邀请码已被使用"})
        return
    end
    local mData = {
        data = {account = self:GetAccount(),invitecode=sInviteCode,createtime = iCreateTime,lastday=iLastTime,usetime=iNowTime}
    }
    gamedb.SaveDb("login","common", "SaveDb", {
        module = "invitecodedb",
        cmd = "SetAccountInviteCode",
        data = mData
    })
    self:Send("GS2CSetInviteCodeResult",{result=1,msg="设置邀请码成功"})
end

function CConnection:ReLoginRole(mData)
    local pid = mData.pid
    local role_token = mData.role_token

    local oGateMgr = global.oGateMgr
    local mInfo = oGateMgr:GetCacheInfo(pid, role_token)
    if not mInfo then
        self:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.invalid_role_token})
        return
    end

    self:SetAccount(mInfo.account)
    self:SetChannel(mInfo.channel)
    self:SetMac(mInfo.mac)
    self:SetDevice(mInfo.device)
    self:SetPlatform(mInfo.platform)

    self.m_oStatus:Set(gamedefines.LOGIN_CONNECTION_STATUS.login_account)
    self:LoginRole(mData)
end

function CConnection:Add2TokenCache(pid, sToken)
    local oGateMgr = global.oGateMgr
    local mRoleInfo = {
        pid = pid,
        channel = self:GetChannel(),
        account = self:GetAccount(),
        mac = self:GetMac(),
        device = self:GetDevice(),
        platform = self:GetPlatform(),
    }
    local sToken = oGateMgr:Add2TokenCache(pid, sToken, mRoleInfo)
    return sToken
end


CGate = {}
CGate.__index = CGate
inherit(CGate, logic_base_cls())

function CGate:New(iPort)
    local o = super(CGate).New(self)
    local iAddr = skynet.launch("zinc_gate", "S", skynet.address(MY_ADDR), iPort, extype.ZINC_CLIENT, 10000,version.XOR_KEY)
    o.m_iAddr = iAddr
    o.m_iPort = iPort
    o.m_mConnections = {}
    return o
end

function CGate:Release()
    for _, v in pairs(self.m_mConnections) do
        baseobj_safe_release(v)
    end
    self.m_mConnections = {}
    super(CGate).Release(self)
end

function CGate:GetConnection(fd)
    return self.m_mConnections[fd]
end

function CGate:AddConnection(oConn)
    self.m_mConnections[oConn.m_iHandle] = oConn
    local oGateMgr = global.oGateMgr
    oGateMgr:SetConnection(oConn.m_iHandle, oConn)

    skynet.send(self.m_iAddr, "text", "forward", oConn.m_iHandle, skynet.address(MY_ADDR), skynet.address(self.m_iAddr))
    skynet.send(self.m_iAddr, "text", "start", oConn.m_iHandle)
    oConn:Send("GS2CHello", {time = math.floor(get_time())})
end

function CGate:DelConnection(iHandle)
    local oConn = self.m_mConnections[iHandle]
    if oConn then
        self.m_mConnections[iHandle] = nil
        baseobj_delay_release(oConn)
        local oGateMgr = global.oGateMgr
        oGateMgr:SetConnection(iHandle, nil)
    end
end

function CGate:GetConnectAmount()
    local iCount = 0
    for _,oConn in pairs(self.m_mConnections) do
        if oConn.m_oStatus:Get() == gamedefines.LOGIN_CONNECTION_STATUS.login_role then
            iCount = iCount + 1
        end
    end
    return iCount
end


MAX_ROLE_TOKEN_ID = 10000

CGateMgr = {}
CGateMgr.__index = CGateMgr
inherit(CGateMgr, logic_base_cls())

function CGateMgr:New()
    local o = super(CGateMgr).New(self)
    o.m_iOpenStatus = 0
    o.m_mGates = {}
    o.m_mNoteConnections = {}

    o.m_iRoleTokenID = 0
    o.m_mRoleTokenCache = {}

    o.m_iLoginCnt = 0
    o.m_mRoleLoginQueue = {}        --　登录队列
    o.m_mRoleWaitQueue = {}         --　等待队列
    o.m_mUnValidName = {}
    return o
end

function CGateMgr:Init()
    self:StartCheckWaitQueue()
end

function CGateMgr:StartCheckWaitQueue()
    local f1
    f1 = function ()
        self:DelTimeCb("CheckPushWaitQueue")
        self:AddTimeCb("CheckPushWaitQueue", 1000, f1)
        self:CheckPushWaitQueue()
    end
    f1()
    local f2
    f2 = function ()
        self:DelTimeCb("ClearNoValidLogin")
        self:AddTimeCb("ClearNoValidLogin", 10 * 60 * 1000, f2)
        self:ClearNoValidLogin()
    end
    f2()
end

function CGateMgr:EnterLoginQueue(iPid,mData)
    if self.m_iLoginCnt < LOGIN_QUEUE_LIMIT then
        self:Send2WorldLogin(iPid,mData)
    else
        self:EnterWaitQueue(iPid,mData)
    end
end

function CGateMgr:EnterWaitQueue(iPid,mData)
    local mRoleWait = self.m_mRoleWaitQueue
    mRoleWait[iPid] = mData
end

function CGateMgr:Send2WorldLogin(iPid,mData)
    local mRoleLogin = self.m_mRoleLoginQueue
    if not mRoleLogin[iPid] then
        self.m_iLoginCnt = self.m_iLoginCnt + 1
    end
    mRoleLogin[iPid] = get_time()
    interactive.Send(".world", "login", "LoginPlayer", mData)
end

function CGateMgr:LeaveLoginQueue(iPid)
    local mRoleLogin = self.m_mRoleLoginQueue
    if mRoleLogin[iPid] then
        self.m_iLoginCnt = self.m_iLoginCnt - 1
    end
    mRoleLogin[iPid] = nil
end

function CGateMgr:CheckPushWaitQueue()
    local mRoleWait = self.m_mRoleWaitQueue
    local mPush,iCnt = {},0
    for iPid,mData in pairs(mRoleWait) do
        mPush[iPid] = mData
        iCnt = iCnt + 1
        if iCnt >= WAIT_PUSH_NUM then
            break
        end
    end
    for iPid,mData in pairs(mPush) do
        mRoleWait[iPid] = nil
        self:Send2WorldLogin(iPid,mData)
    end
end

function CGateMgr:ClearNoValidLogin()
    local mRoleLogin = self.m_mRoleLoginQueue
    local mDel = {}
    local iNowTime = get_time()
    for iPid,iTime in pairs(mRoleLogin) do
        local iOverTime = iNowTime - iTime
        if iOverTime > 10*60 then
            mDel[iPid] = iOverTime
        end
    end
    for iPid,iOverTime in pairs(mDel) do
        mRoleLogin[iPid] = nil
        record.warning("loginresult back too later pid " .. iPid .. " overtime: ".. iOverTime)
    end
end

function CGateMgr:Release()
    for _, v in pairs(self.m_mGates) do
        baseobj_safe_release(v)
    end
    self.m_mGates = {}
    super(CGateMgr).Release(self)
end

function CGateMgr:IsMaintain()
    return self.m_iOpenStatus == 0
end

function CGateMgr:IsOpen()
    return self.m_iOpenStatus == 2
end

function CGateMgr:IsLimit()
    local iAmount = 0
    for _,oGate in pairs(self.m_mGates) do
        iAmount = iAmount + oGate:GetConnectAmount()
    end
    if iAmount < 6000 then
        return false
    end
    return true
end

function CGateMgr:SetOpenStatus(iStatus)
    self.m_iOpenStatus = iStatus
end

function CGateMgr:AddGate(oGate)
    self.m_mGates[oGate.m_iAddr] = oGate
end

function CGateMgr:GetGate(iAddr)
    return self.m_mGates[iAddr]
end

function CGateMgr:GetConnection(iHandle)
    return self.m_mNoteConnections[iHandle]
end

function CGateMgr:SetConnection(iHandle, oConn)
    self.m_mNoteConnections[iHandle] = oConn
end

function CGateMgr:KickConnection(iHandle)
    local oConnection = self:GetConnection(iHandle)
    if oConnection then
        skynet.send(oConnection.m_iGateAddr, "text", "kick", oConnection.m_iHandle)
        local oGate = self:GetGate(oConnection.m_iGateAddr)
        if oGate and oGate:GetConnection(iHandle) then
            oGate:DelConnection(iHandle)
        end
    end
end

function CGateMgr:DispatchRoleToken()
    self.m_iRoleTokenID = self.m_iRoleTokenID + 1
    if self.m_iRoleTokenID >= MAX_ROLE_TOKEN_ID then
        self.m_iRoleTokenID = 1
    end
    local iToken = get_time() * MAX_ROLE_TOKEN_ID + self.m_iRoleTokenID
    return tostring(iToken)
end

function CGateMgr:Add2TokenCache(iPid, sToken, mRoleInfo)
    mRoleInfo.token = sToken
    self.m_mRoleTokenCache[iPid] = mRoleInfo
    return sToken
end

function CGateMgr:GetCacheInfo(iPid, sToken)
    local mData = self.m_mRoleTokenCache[iPid]
    if not mData then
        return
    end
    if mData.token ~= sToken then
        return
    end
    return mData
end

function CGateMgr:ClearCacheInfo(iPid, sToken)
    local mData = self.m_mRoleTokenCache[iPid]
    if mData.token == sToken then
        self.m_mRoleTokenCache[iPid] = nil
    end
end

function CGateMgr:OnLogout(mData)
    local iPid = mData.pid
    local sToken = mData.token
    self:ClearCacheInfo(iPid, sToken)
end

function CGateMgr:ValidPlayerLogin(sAccount, iChannel, sIP)
    if self:IsMaintain() then
        return false
    elseif self:IsOpen() then
        return true
    else
        if self:IsWhiteListAccount(sAccount) then
            return true
        elseif ipoperate.is_white_ip(sIP) then
                return true
        else
            return false
        end
    end
end

function CGateMgr:IsWhiteListAccount(sAccount)
    local mWhiteAccount = whiteaccount.GetWhiteAccount()
    if table_in_list(mWhiteAccount,sAccount) then
        return true
    end
    return false
end


function CGateMgr:AddUnvalidName(sName)
    self.m_mUnValidName[sName] = true
end

function CGateMgr:CleanUnValidName(sName)
    self.m_mUnValidName = nil
end

function CGateMgr:IsValidName(sName)
    return not self.m_mUnValidName[sName]
end