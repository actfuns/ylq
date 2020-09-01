--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local res = require "base.res"
local net = require "base.net"
local extend = require "base.extend"
local record = require "public.record"
local router = require "base.router"

local gamedb = import(lualib_path("public.gamedb"))
local analy = import(lualib_path("public.dataanaly"))
local ppower = import(lualib_path("public.ppower"))
local gamedefines = import(lualib_path("public.gamedefines"))
local playerobj = import(service_path("playerobj"))
local connectionobj = import(service_path("connectionobj"))
local offline = import(service_path("offline.init"))
local datactrl = import(lualib_path("public.datactrl"))
local sysmailcache = import(service_path("mail.sysmailcache"))
local serverop = import(lualib_path("public.serverop"))

function NewWorldMgr(...)
    local o = CWorldMgr:New(...)
    return o
end

CWorldMgr = {}
CWorldMgr.__index = CWorldMgr
inherit(CWorldMgr, datactrl.CDataCtrl)

function CWorldMgr:New()
    local o = super(CWorldMgr).New(self)
    o.m_bIsOpen = true
    o.m_mOnlinePlayers = {}
    o.m_mLoginPlayers = {}
    o.m_mShowIdPlayers = {}

    o.m_mOfflineProfiles = {}
    o.m_mOfflineFriends = {}
    o.m_mMailBoxs = {}
    o.m_mOfflinePartners={}
    o.m_mConnections = {}
    o.m_mOfflinePrivys = {}
    o.m_mOfflineTravels = {}
    o.m_mWarRom = {}

    o.m_mPlayerPropChange = {}
    o.m_mSummonPropChange = {}
    o.m_mPartnerPropChange = {}
    o.m_oSysMailCache = sysmailcache.NewSysMailCache()

    o.m_iGlobalItemId = 0
    o.m_iGlobalWarFilmId = 0
    o.m_iGlobalIndex = 0
    return o
end

function CWorldMgr:Release()
    for _, v in ipairs({self.m_mOnlinePlayers, self.m_mLoginPlayers}) do
        for _, v2 in pairs(v) do
            baseobj_delay_release(v)
        end
    end
    for _, v in pairs(self.m_mConnections) do
        baseobj_delay_release(v)
    end
    self.m_mOnlinePlayers = {}
    self.m_mShowIdPlayers = {}
    self.m_mOfflineFriends = {}
    self.m_mLoginPlayers = {}
    self.m_mConnections = {}
    self.m_mOfflineProfiles = {}
    self.m_mOfflinePrivys = {}
    self.m_mWarRom = {}
    self.m_mMailBoxs = {}
    self.m_mOfflinePartners = {}
    self.m_mOfflineTravels = {}
    super(CWorldMgr).Release(self)
end

function CWorldMgr:Load(m)
    m = m or {}
    self.m_iServerGrade = m.server_grade or self:GetInitServerGrade()
    self.m_iOpenDays = m.open_days or 0
    self.m_oSysMailCache:Load(m.sysmails)
    self.m_iGlobalWarFilmId = m.war_filmid or 0
    self.m_iGlobalIndex = m.link or 0
    global.oMergerMgr:Load(m.merger)
end

function CWorldMgr:Save()
    local m = {}
    m.server_grade = self.m_iServerGrade
    m.open_days = self.m_iOpenDays
    m.sysmails = self.m_oSysMailCache:Save()
    m.war_filmid = self.m_iGlobalWarFilmId
    m.link = self.m_iGlobalIndex
    m.merger = global.oMergerMgr:Save()
    return m
end

function CWorldMgr:MergeFrom(mData)
    self:Dirty()
    self.m_oSysMailCache:MergeFrom(mData.sysmails)
    return global.oMergerMgr:MergeFrom(mData)
end

function CWorldMgr:GetInitServerGrade()
    local lServerGrade = res["daobiao"]["servergrade"]
    return lServerGrade[1]["server_grade"]
end

function CWorldMgr:UnDirty()
    super(CWorldMgr).UnDirty(self)
    self.m_oSysMailCache:UnDirty()
    global.oMergerMgr:UnDirty()
end

function CWorldMgr:IsDirty()
    local bDirty = super(CWorldMgr).IsDirty(self)
    if bDirty then
        return true
    end
    local bMailDirty = self.m_oSysMailCache:IsDirty()
    if bMailDirty then
        return true
    end
    return global.oMergerMgr:IsDirty()
end

function CWorldMgr:SetServerGrade(i)
    self.m_iServerGrade = i
    self:Dirty()
end

function CWorldMgr:GetServerGrade()
    return self.m_iServerGrade
end


function CWorldMgr:NewLinkID()
    local bReset = false
    self.m_iGlobalIndex = self.m_iGlobalIndex + 1
    if self.m_iGlobalIndex > 2100000000 then
        self.m_iGlobalIndex = 1
        bReset = true
    end
    self:Dirty()
    return self.m_iGlobalIndex,bReset
end

function CWorldMgr:GetMaxPlayerGrade()
    local mGlobalSetting = res["daobiao"]["global"]
    local iBreak = tonumber(mGlobalSetting.canbreak_gradelimit.value)
    local iLimitGrade = tonumber(mGlobalSetting.player_gradelimit.value)
    return math.min(self:GetServerGrade()+iBreak,iLimitGrade)
end

function CWorldMgr:SetOpenDays(i)
    self.m_iOpenDays = i
    self:Dirty()
end

function CWorldMgr:GetOpenDays()
    return self.m_iOpenDays
end

function CWorldMgr:OnLogin(oPlayer, bReEnter)
    oPlayer:Send("GS2CServerGradeInfo", {
        server_grade = self:GetServerGrade(),
        days = self:GetUpGradeLeftDays(),
    })
end

function CWorldMgr:GetConnection(iHandle)
    return self.m_mConnections[iHandle]
end

function CWorldMgr:DelConnection(iHandle)
    local oConnection = self.m_mConnections[iHandle]
    if oConnection then
        self.m_mConnections[iHandle] = nil
        oConnection:Disconnected()
        baseobj_delay_release(oConnection)
    end
end

function CWorldMgr:LoadMailBox(iPid, func)
    self:LoadOfflineBlock("MailBox", iPid, func)
end

function CWorldMgr:GetMailBox(iPid)
    return self:GetOfflineObject("MailBox", iPid)
end

function CWorldMgr:LoadRom(iPid,func)
    return self:LoadOfflineBlock("Rom",iPid,func)
end

function CWorldMgr:FindPlayerAnywayByPid(pid)
    local obj
    for _, m in ipairs({self.m_mLoginPlayers, self.m_mOnlinePlayers}) do
        obj = m[pid]
        if obj then
            break
        end
    end
    return obj
end

function CWorldMgr:FindPlayerAnywayByFd(iHandle)
    local oConnection = self:GetConnection(iHandle)
    if oConnection then
        local iPid = oConnection:GetOwnerPid()
        return self:FindPlayerAnywayByPid(iPid)
    end
end

function CWorldMgr:GetOnlinePlayerByFd(iHandle)
    local oConnection = self:GetConnection(iHandle)
    if oConnection then
        local iPid = oConnection:GetOwnerPid()
        return self.m_mOnlinePlayers[iPid]
    end
end

function CWorldMgr:GetOnlinePlayerByPid(iPid)
    return self.m_mOnlinePlayers[iPid]
end

function CWorldMgr:SetPlayerByShowId(iShowId, oPlayer)
    self.m_mShowIdPlayers[iShowId] = oPlayer
end

function CWorldMgr:GetOnlinePlayerByShowId(iShowId)
    return self.m_mShowIdPlayers[iShowId]
end

function CWorldMgr:IsLogining(iPid)
    if self.m_mLoginPlayers[iPid] then
        return true
    end
    return false
end

function CWorldMgr:GetLoginingPlayerList()
    return self.m_mLoginPlayers
end

function CWorldMgr:IsOnline(iPid)
    local oPlayer = self:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    return true
end

function CWorldMgr:GetOnlinePlayerList()
    return self.m_mOnlinePlayers
end

function CWorldMgr:GetOnlinePlayerCnt()
    return table_count(self.m_mOnlinePlayers)
end

function CWorldMgr:GetNearOnlinePlayerCnt()
    return self.m_NearPlayerCnt or table_count(self.m_mOnlinePlayers)
end

function CWorldMgr:KickConnection(iHandle)
    local oConnection = self:GetConnection(iHandle)
    if oConnection then
        local iGateAddr = oConnection.m_iGateAddr
        self:DelConnection(iHandle)
        skynet.send(iGateAddr, "text", "kick", iHandle)
    end
end

function CWorldMgr:Logout(iPid)
    local oPlayer = self.m_mLoginPlayers[iPid]
    if oPlayer then
        local sToken = oPlayer:GetRoleToken()
        self.m_mLoginPlayers[iPid] = nil
        baseobj_delay_release(oPlayer)
        self:LogoutNotifyGate(iPid, sToken)
        return
    end
    oPlayer = self.m_mOnlinePlayers[iPid]
    if oPlayer then
        local sToken = oPlayer:GetRoleToken()
        oPlayer:OnLogout()
        self.m_mOnlinePlayers[iPid] = nil
        baseobj_delay_release(oPlayer)
        self:LogoutNotifyGate(iPid, sToken)
    end
end

function CWorldMgr:LogoutNotifyGate(pid, sToken)
    interactive.Send(".login", "login", "OnLogout", {pid = pid, token = sToken})
end

function CWorldMgr:Login(mRecord, mConn, mRole)
    local pid = mRole.pid
    local sAccount = mRole.account
    if self.m_mLoginPlayers[pid] then
        interactive.Send(mRecord.source, "login", "LoginResult", {pid = pid, handle = mConn.handle,token = mRole.role_token,errcode = gamedefines.ERRCODE.in_login})
        return
    end

    local oPlayer = self.m_mOnlinePlayers[pid]
    if oPlayer then
        local oOldConn = oPlayer:GetConn()
        if oOldConn and oOldConn.m_iHandle ~= mConn.handle then
            oOldConn:Send("GS2CLoginError", {pid = pid, errcode = gamedefines.ERRCODE.reenter})
            self:KickConnection(oOldConn.m_iHandle)
        end

        local oConnection = connectionobj.NewConnection(mConn, pid,sAccount)
        self.m_mConnections[mConn.handle] = oConnection
        oConnection:Forward()

        oPlayer:ReInitRoleInfo(mConn,mRole)
        oPlayer:OnLogin(true)
        interactive.Send(mRecord.source, "login", "LoginResult", {pid = pid, handle = mConn.handle,token = mRole.role_token,errcode = gamedefines.ERRCODE.ok})
        return
    else
        local oPlayer = playerobj.NewPlayer(mConn, mRole)
        self.m_mLoginPlayers[oPlayer:GetPid()] = oPlayer

        local oConnection = connectionobj.NewConnection(mConn, pid,sAccount)
        self.m_mConnections[mConn.handle] = oConnection
        oConnection:Forward()
        local mData = {
            pid = pid
        }
        local mArgs = {
            module = "playerdb",
            cmd = "GetPlayer",
            data = mData
        }
        gamedb.LoadDb(pid,"common", "LoadDb", mArgs, function (mRecord, mData)
            if not is_release(self) then
                self:_LoginRole1(mRecord, mData)
            end
        end)
        return
    end
end

function CWorldMgr:_LoginRole1(mRecord, mData)
    local pid = mData.pid
    local m = mData.data
    local oPlayer = self.m_mLoginPlayers[pid]
    if not oPlayer then
        return
    end

    if not m then
        self.m_mLoginPlayers[pid] = nil
        local oConn = oPlayer:GetConn()
        if oConn then
            interactive.Send(".login", "login", "LoginResult", {pid = pid, handle = oConn.m_iHandle, token = oPlayer:GetRoleToken(),errcode = gamedefines.ERRCODE.not_exist_player})
        end
        return
    end
    local mData = {
        pid = pid
    }
    local mArgs = {
        module = "playerdb",
        cmd = "LoadPlayerMain",
        data =mData
    }
    gamedb.LoadDb(pid, "common", "LoadDb",mArgs, function (mRecord, mData)
        if not is_release(self) then
            self:_LoginRole2(mRecord, mData)
        end
    end)
end

function CWorldMgr:_LoginRole2(mRecord, mData)
    local pid = mData.pid
    local m = mData.data
    local oPlayer = self.m_mLoginPlayers[pid]
    if not oPlayer then
        return
    end
    oPlayer:Load(m)
    self:_LoginLoadModule(pid)
end

local lLoginLoadInfo = {
    {"LoadPlayerBase", "m_oBaseCtrl"},
    {"LoadPlayerActive", "m_oActiveCtrl"},
    {"LoadPlayerTask", "m_oTaskCtrl"},
    {"LoadPlayerTimeInfo", "m_oTimeCtrl"},
    {"LoadPlayerSchedule", "m_oScheduleCtrl"},
    {"LoadPlayerState", "m_oStateCtrl"},
    {"LoadPlayerPartner", "m_oPartnerCtrl"},
    {"LoadPlayerTitle", "m_oTitleCtrl"},
    {"LoadPlayerHuodongInfo","m_oHuodongCtrl"},
    {"LoadPlayerHandBook", "m_oHandBookCtrl"},
}

function CWorldMgr:_LoginLoadModule(iPid, idx)
    idx = idx or 1
    if idx > #lLoginLoadInfo then
        self:_LoginLoadOfflines(iPid)
        return
    end
    local sLoadFunc, rFunc = table.unpack(lLoginLoadInfo[idx])
    local mData = {
        pid = iPid
    }
    local mArgs = {
        module = "playerdb",
        cmd = sLoadFunc,
        data = mData
    }
    gamedb.LoadDb(iPid,"common","LoadDb",mArgs, function (mRecord, mData)
        self:_LoginLoadModuleCB(rFunc, mRecord, mData)
        if not is_release(self) then
            self:_LoginLoadModule(iPid, idx+1)
        end
    end)
end

function CWorldMgr:_LoginLoadModuleCB(rFunc, mRecord, mData)
    local pid = mData.pid
    local m = mData.data
    local oPlayer = self.m_mLoginPlayers[pid]
    if not oPlayer then
        return
    end
    if type(rFunc) == "string" then
        if oPlayer[rFunc] then
            oPlayer[rFunc]:Load(m)
        else
            self[rFunc](oPlayer, m)
        end
    else
        rFunc(oPlayer, m)
    end
end

function CWorldMgr:_LoginLoadOfflines(iPid)
    local mFunc = {"LoadProfile","LoadFriend","LoadMailBox","LoadPartner","LoadPrivy", "LoadTravel"}
    local mLoad = {}
    for _,sFunc in pairs(mFunc) do
        if self[sFunc] then
            self[sFunc](self,iPid,function(o)
                mLoad[sFunc] = 1
                if table_count(mLoad) >= #mFunc then
                    local fCallback = function (mRecord,mData)
                        self:LoadEnd(iPid,mData)
                    end
                    self:LoadRoleAssist(iPid,fCallback)
                end
            end)
        end
    end
end

function CWorldMgr:LoadRoleAssist(iPid,fCallback)
    local oPlayer = self.m_mLoginPlayers[iPid]
    local iAssistAddr = oPlayer:GetAssistRemote()
    local mData = oPlayer:PackAssistPlayerData()
    interactive.Request(iAssistAddr,"assist","LoadRoleAssist",mData,fCallback)
end

function CWorldMgr:LoadEnd(iPid,mData)
    local oPlayer = self.m_mLoginPlayers[iPid]
    if not oPlayer then
        return
    end
    self.m_mLoginPlayers[iPid] = nil
    self.m_mOnlinePlayers[iPid] = oPlayer
    local iShowId = oPlayer:GetShowId()
    self:SetPlayerByShowId(iShowId, oPlayer)

    oPlayer:ConfigSaveFunc()
    oPlayer:InitShareObj(mData)
    oPlayer:OnLogin(false)
    local oConn = oPlayer:GetConn()
    if oConn then
        interactive.Send(".login", "login", "LoginResult", {pid = iPid, handle = oConn.m_iHandle, token = oPlayer:GetRoleToken(),errcode = gamedefines.ERRCODE.ok})
    end
    self:GetShowIdByPid(iPid)
end

function CWorldMgr:GetShowIdByPid(iPid)
    router.Request("cs", ".idsupply", "common", "GetShowIdByPid", {
        pid = iPid,
        set = 1
    }, function (mRecord, mData)
        local oShowIdMgr = global.oShowIdMgr
        oShowIdMgr:SetShowId(iPid, mData.show_id)
    end)
end

function CWorldMgr:OnLoginFail(pid)
    local oPlayer = self.m_mLoginPlayers[pid]
    if not oPlayer then
        return
    end
    local iHandle = oPlayer:GetNetHandle()
    interactive.Send(".login", "login", "LoginResult", {pid = pid, handle = iHandle, token = oPlayer:GetRoleToken(), errcode = gamedefines.ERRCODE.script_error})
    self.m_mLoginPlayers[pid] = nil
    baseobj_delay_release(oPlayer)
end

function CWorldMgr:GetOfflineMap(sKey)
    if sKey == "Profile" then
        return self.m_mOfflineProfiles
    elseif sKey == "Friend" then
        return self.m_mOfflineFriends
    elseif sKey == "MailBox" then
        return self.m_mMailBoxs
    elseif sKey == "Partner" then
        return self.m_mOfflinePartners
    elseif sKey == "Privy" then
        return self.m_mOfflinePrivys
    elseif sKey == "Travel" then
        return self.m_mOfflineTravels
    elseif sKey == "Rom" then
        return self.m_mWarRom
    end
    assert(false, string.format("CWorldMgr GetOfflineMap fail %s", sKey))
end

function CWorldMgr:GetOfflineObject(sKey, iPid)
    if sKey == "Profile" then
        return self.m_mOfflineProfiles[iPid]
    elseif sKey == "Friend" then
        return self.m_mOfflineFriends[iPid]
    elseif sKey == "MailBox" then
        return self.m_mMailBoxs[iPid]
    elseif sKey == "Partner" then
        return self.m_mOfflinePartners[iPid]
    elseif sKey == "Privy" then
        return self.m_mOfflinePrivys[iPid]
    elseif sKey == "Travel" then
        return self.m_mOfflineTravels[iPid]
    elseif sKey == "Rom" then
        return self.m_mWarRom[iPid]
    end

    assert(false, string.format("CWorldMgr GetOfflineObject fail %s %d", sKey, iPid))
end

function CWorldMgr:SetOfflineObject(sKey, iPid, o)
    if sKey == "Profile" then
        self.m_mOfflineProfiles[iPid] = o
        return
    elseif sKey == "Friend" then
        self.m_mOfflineFriends[iPid] = o
        return
    elseif sKey == "MailBox" then
        self.m_mMailBoxs[iPid] = o
        return
    elseif sKey == "Partner" then
        self.m_mOfflinePartners[iPid] = o
        return
    elseif sKey == "Privy" then
        self.m_mOfflinePrivys[iPid] = o
        return
    elseif sKey == "Travel" then
        self.m_mOfflineTravels[iPid] = o
        return
    elseif sKey == "Rom" then
        self.m_mWarRom[iPid] = o
        return
    end
    assert(false, string.format("CWorldMgr SetOfflineObject fail %s %d", sKey, iPid))
end

function CWorldMgr:DelOfflineObject(sKey, iPid)
    local o
    if sKey == "Profile" then
        o = self.m_mOfflineProfiles[iPid]
        self.m_mOfflineProfiles[iPid] = nil
    elseif sKey == "Friend" then
        o = self.m_mOfflineFriends[iPid]
        self.m_mOfflineFriends[iPid] = nil
    elseif sKey == "MailBox" then
        o = self.m_mMailBoxs[iPid]
        self.m_mMailBoxs[iPid] = nil
    elseif sKey == "Partner" then
        o = self.m_mOfflinePartners[iPid]
        self.m_mOfflinePartners[iPid] = nil
    elseif sKey == "Privy" then
        o = self.m_mOfflinePrivys[iPid]
        self.m_mOfflinePrivys[iPid] = nil
    elseif sKey == "Travel" then
        o = self.m_mOfflineTravels[iPid]
        self.m_mOfflineTravels[iPid] = nil
    elseif sKey == "Rom" then
        o = self.m_mWarRom[iPid]
        self.m_mWarRom[iPid] = nil
    end
    if o then
        baseobj_delay_release(o)
    end
end

function CWorldMgr:NewOfflineObject(sKey, iPid)
    if sKey == "Profile" then
        return offline.NewProfileCtrl(iPid)
    elseif sKey == "Friend" then
        return offline.NewFriendCtrl(iPid)
    elseif sKey == "MailBox" then
        return offline.NewMailBox(iPid)
    elseif sKey == "Partner" then
        return offline.NewPartnerCtrl(iPid)
    elseif sKey == "Privy" then
        return offline.NewPrivyCtrl(iPid)
    elseif sKey == "Travel" then
        return offline.NewTravelCtrl(iPid)
    elseif sKey == "Rom" then
        return offline.NewRomCtrl(iPid)
    end
    assert(false, string.format("CWorldMgr NewOfflineObject fail %s %d", sKey, iPid))
end

function CWorldMgr:LoadOfflineBlock(sKey, iPid, func)
    local o = self:GetOfflineObject(sKey, iPid)
    if o then
        if o:IsLoading() then
            o:AddWaitFunc(func)
        else
            func(o)
            o:SetLastTime()
        end
    else
        o = self:NewOfflineObject(sKey, iPid)
        self:SetOfflineObject(sKey, iPid, o)
        o:AddWaitFunc(func)
        local mData = {
            pid = iPid
        }
        local mArgs = {
            module = "offlinedb",
            cmd = o:GetLoadDbFlag(),
            data = mData
        }
        gamedb.LoadDb(iPid,"common","LoadDb",mArgs, function (mRecord,mData)
            local o = self:GetOfflineObject(sKey, iPid)
            assert(o and o:IsLoading(), string.format("LoadOfflineBlock fail %s %d", sKey, iPid))

            if not mData.success then
                o:LoadFinish()
                o:WakeUpFailFunc()
                self:DelOfflineObject(sKey, iPid)
            else
                local m = mData.data
                o:LoadFinish()
                o:Load(m)
                o:WakeUpFunc()
                o:ConfigSaveFunc()
                o:Schedule()
            end
        end)
    end
end

function CWorldMgr:CleanOfflineBlock(sKey, iPid)
    local o = self:GetOfflineObject(sKey, iPid)
    if o then
        o:OnLogout()
    end
    self:DelOfflineObject(sKey, iPid)
end

function CWorldMgr:LoadProfile(iPid, fCallback)
    self:LoadOfflineBlock("Profile", iPid, fCallback)
end

function CWorldMgr:LoadFriend(iPid, fCallback)
    self:LoadOfflineBlock("Friend", iPid, fCallback)
end

function CWorldMgr:LoadPartner(iPid, fCallback)
    self:LoadOfflineBlock("Partner", iPid, fCallback)
end

function CWorldMgr:LoadPrivy(iPid,fCallback)
    self:LoadOfflineBlock("Privy",iPid,fCallback)
end

function CWorldMgr:LoadTravel(iPid,fCallback)
    self:LoadOfflineBlock("Travel",iPid,fCallback)
end

function CWorldMgr:GetOfflinePartner(iPid)
    return self:GetOfflineObject("Partner", iPid)
end

function CWorldMgr:GetProfile(iPid)
    return self:GetOfflineObject("Profile", iPid)
end

function CWorldMgr:GetFriend(iPid)
    return self:GetOfflineObject("Friend", iPid)
end

function CWorldMgr:GetPrivy(iPid)
    return self:GetOfflineObject("Privy",iPid)
end

function CWorldMgr:GetTravel(iPid)
    return self:GetOfflineObject("Travel",iPid)
end

function CWorldMgr:InitData()
    self:SyncPowerData()
end

function CWorldMgr:Schedule()
    local f1
    f1 = function ()
        local tbl = get_hourtime({factor=1,hour=1})
        local iSecs = tbl.time - get_time()
        if iSecs <= 0 then
            iSecs = 3600
        end
        self:DelTimeCb("NewHour")
        self:AddTimeCb("NewHour", iSecs * 1000, f1)

        local iWeekDay = get_weekday()
        local tbl = get_hourtime({hour=0})
        self:NewHour(iWeekDay,tbl.date.hour)
    end
    local tbl = get_hourtime({factor=1,hour=1})
    local iSecs = tbl.time - get_time()
    if iSecs <= 0 then
        f1()
    else
        self:DelTimeCb("NewHour")
        self:AddTimeCb("NewHour", iSecs * 1000, f1)
    end
    self:CheckOnline()
end

function CWorldMgr:CheckOnline()
    local f2
    f2 = function ()
        self:DelTimeCb("_CheckOnline")
        self:AddTimeCb("_CheckOnline", 60 *1000, f2)
        self:CheckOnline2()
        self:CheckOnline3()
    end
    self:DelTimeCb("_CheckOnline")
    self:AddTimeCb("_CheckOnline", 60*1000, f2)
end

function CWorldMgr:CheckOnline2()
    local tPlayerList = self:GetOnlinePlayerList()
    local total = 0
    local mRet = {}
    for _,oPlayer in pairs(tPlayerList) do
        local platform,channel = oPlayer:GetPlatformName(),oPlayer:GetChannel()
        mRet[platform] = mRet[platform] or {}
        mRet[platform][channel] = mRet[platform][channel] or 0
        mRet[platform][channel] = mRet[platform][channel] + 1
        total = total + 1
    end
    self.m_NearPlayerCnt = total
    record.log_db("online", "online", {online_cnt=total})
    for platform,clist in pairs(mRet) do
        for channel,cnt in pairs(clist) do
            record.log_db("online", "detail", {platform=platform,channel=channel,online_cnt=cnt})
        end
    end
end

function CWorldMgr:CheckOnline3()
    local tPlayerList = self:GetOnlinePlayerList()
    local mRet = {}
    local mRet2 = {}
    for _,oPlayer in pairs(tPlayerList) do
        local platform,channel = oPlayer:GetPlatform(),oPlayer:GetChannel()
        mRet[platform] = mRet[platform] or {}
        mRet[platform][channel] = mRet[platform][channel] or 0
        mRet[platform][channel] = mRet[platform][channel] + 1
        local platform2,channel2 = oPlayer:GetPlatformSign(),oPlayer:GetKPChannel()
        if channel2 then
            mRet2[platform2] = mRet2[platform2] or {}
            mRet2[platform2][channel2] = mRet2[platform2][channel2] or 0
            mRet2[platform2][channel2] = mRet2[platform2][channel2] + 1
        end
    end
    for platform,clist in pairs(mRet) do
        for channel,num in pairs(clist) do
            analy.log_data("OnlinePlayer", {server=MY_SERVER_KEY,plat=platform,app_channel=channel,online_num=num})
        end
    end
    global.oKaopuMgr:OnlineUserNumber(mRet2)
end

function CWorldMgr:ConfigSaveFunc()
    self:ApplySave(function ()
        local oWorldMgr = global.oWorldMgr
        oWorldMgr:SaveDb()
    end)
end

function CWorldMgr:SaveDb()
    if self:IsDirty() then
        local mData = {
            server_id = get_server_tag(),
            data = self:Save()
        }
        gamedb.SaveDb("world", "common", "SaveDb", {module="worlddb",cmd="SaveWorld",data = mData})
        self:UnDirty()
    end
end

function CWorldMgr:CheckUpGrade()
    local lServerGrade = res["daobiao"]["servergrade"]

    local iTargetGrade = self:GetServerGrade()
    if iTargetGrade >= gamedefines.SERVER_GRADE_LIMIT then
        return
    end

    for _, v in ipairs(lServerGrade) do
        if self:GetOpenDays() < v.days then
            break
        end
        if v.server_grade > iTargetGrade then
            iTargetGrade = v.server_grade
        end
    end
    if iTargetGrade ~= self:GetServerGrade() then
        self:SetServerGrade(iTargetGrade)
        local iLeftDays = self:GetUpGradeLeftDays()

        local mData = {
            message = "GS2CServerGradeInfo",
            type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
            id = 1,
            data = {
                server_grade = iTargetGrade,
                days = iLeftDays,
            },
        }
        interactive.Send(".broadcast", "channel", "SendChannel", mData)
    end
end

function CWorldMgr:GetUpGradeLeftDays()
    local lServerGrade = res["daobiao"]["servergrade"]
    local iRet = 0
    local iOpenDays = self.m_iOpenDays
    for _, v in ipairs(lServerGrade) do
        if v.days > iOpenDays then
            iRet = v.days - iOpenDays
            break
        end
    end
    return iRet
end

function CWorldMgr:NewHour(iDay,iHour)
    if iHour == 0 then
        self:SetOpenDays(self:GetOpenDays() + 1)
        self:CheckUpGrade()
        self:NewDay(iDay)
        for _,oPlayer in pairs(self.m_mOnlinePlayers) do
            safe_call(oPlayer.NewDay,oPlayer,iDay)
        end
    elseif iHour == 5 then
        skynet.send(".rt_monitor", "lua", "DayCommandMonitor")
        for _,oPlayer in pairs(self.m_mOnlinePlayers) do
            safe_call(oPlayer.NewHour5,oPlayer,iDay,iHour)
        end
        self:NewHour5(iDay,iHour)
    end

    local oRankMgr = global.oRankMgr
    safe_call(oRankMgr.NewHour,oRankMgr,iDay,iHour)
    local oGamePushMgr = global.oGamePushMgr
    safe_call(oGamePushMgr.NewHour,oGamePushMgr,iDay,iHour)
    local oHuodongMgr = global.oHuodongMgr
    safe_call(oHuodongMgr.NewHour, oHuodongMgr, iDay,iHour)
    local oOrgMgr = global.oOrgMgr
    safe_call(oOrgMgr.NewHour,oOrgMgr,iDay,iHour)
    local oFuliMgr = global.oFuliMgr
    safe_call(oFuliMgr.NewHour,oFuliMgr,iDay,iHour)
    local oHbMgr = global.oHbMgr
    safe_call(oHbMgr.NewHour,oHbMgr,iDay,iHour)
    local oMailMgr = global.oMailMgr
    safe_call(oMailMgr.NewHour,oMailMgr,iDay,iHour)
end

function CWorldMgr:NewDay(iWeekDay)
    local oPartnerCmtMgr = global.oPartnerCmtMgr
    local oAchieveMgr = global.oAchieveMgr
    local oHouseMgr = global.oHouseMgr
    safe_call(oPartnerCmtMgr.NewDay,oPartnerCmtMgr,iWeekDay)
    safe_call(oAchieveMgr.NewDay, oAchieveMgr,iWeekDay)
end

function CWorldMgr:NewHour5(iDay,iHour)
end

function CWorldMgr:IsOpen()
    return self.m_bIsOpen
end

function CWorldMgr:SetOpen(b)
    self.m_bIsOpen = b
end

function CWorldMgr:CloseGS()
    if not self:IsOpen() then
        return
    end

    self:SetOpen(false)

    interactive.Send(".login", "login", "ReadyCloseGS", {})
    self:DelTimeCb("CloseGS2")
    self:AddTimeCb("CloseGS2", 4*1000, function ()
        if not is_release(self) then
            self:CloseGS2()
        end
    end)

    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendSysChat("周知：服务器将进行维护，4秒后将直接下线", 0, 1)
end

function CWorldMgr:CloseGS2()
    save_all()
    local l = {}
    for _, o in pairs(self.m_mOnlinePlayers) do
        table.insert(l, o:GetPid())
    end
    for _, v in ipairs(l) do
        self:Logout(v)
    end
    for _,oProfile in pairs(self.m_mOfflineProfiles) do
        if oProfile and not oProfile:IsLoading() then
            oProfile:OnLogout()
        end
    end
    for _,oPrivy in pairs(self.m_mOfflinePrivys) do
        if oPrivy and not oPrivy:IsLoading() then
            oPrivy:OnLogout()
        end
    end
    for _,oFriend in pairs(self.m_mOfflineFriends) do
        oFriend:OnLogout()
    end
    for _, oTravel in pairs(self.m_mOfflineTravels) do
        oTravel:OnLogout()
    end
    for _, oRom in pairs(self.m_mWarRom) do
        oRom:OnLogout()
    end
    local oWarFilmMgr = global.oWarFilmMgr
    oWarFilmMgr:OnCloseGS()

    interactive.Send(".rank", "dictator", "CloseGS", {})
    global.oAchieveMgr:CloseGS()
    global.oImageMgr:CloseGS()
    global.oAssistMgr:CloseGS()
    global.oOrgMgr:CloseGS()
    global.oHuodongMgr:CloseGS()
    --record.warning("关服完成")
    self:DelTimeCb("CloseGS3")
    self:AddTimeCb("CloseGS3", 4*1000, function ()
        if not is_release(self) then
            self:CloseGS3()
        end
    end)
end

function CWorldMgr:CloseGS3()
    os.exit()
end

function CWorldMgr:SetPlayerPropChange(iPid, l)
    local mNow = self.m_mPlayerPropChange[iPid]
    if not mNow then
        mNow = {}
        self.m_mPlayerPropChange[iPid] = mNow
    end
    for _, v in ipairs(l) do
        mNow[v] = true
    end
end

function CWorldMgr:SetSummonPropChange(iPid, summonid, l)
    local mSummons = self.m_mSummonPropChange[iPid]
    if not mSummons then
        mSummons = {}
        self.m_mSummonPropChange[iPid] = mSummons
    end
    local mProps = mSummons[summonid]
    if not mProps then
        mProps = {}
        self.m_mSummonPropChange[iPid][summonid] = mProps
    end
    for _, v in ipairs(l) do
        mProps[v] = true
    end
end

function CWorldMgr:SetPartnerPropChange(iPid, partnerid, l)
    local mPartners = self.m_mPartnerPropChange[iPid]
    if not mPartners then
        mPartners = {}
        self.m_mPartnerPropChange[iPid] = mPartners
    end
    local mProps = mPartners[partnerid]
    if not mProps then
        mProps = {}
        self.m_mPartnerPropChange[iPid][partnerid] = mProps
    end
    for _, v in ipairs(l) do
        mProps[v] = true
    end
end

function CWorldMgr:SendPlayerPropChange()
    if next(self.m_mPlayerPropChange) then
        local mPlayerPropChange = self.m_mPlayerPropChange
        for k, v in pairs(mPlayerPropChange) do
            local oPlayer = self:GetOnlinePlayerByPid(k)
            if oPlayer and next(v) then
                safe_call(oPlayer.ClientPropChange,oPlayer,v)
            end
        end
        self.m_mPlayerPropChange = {}
    end
end

function CWorldMgr:SendPartnerPropChange()
    if next(self.m_mPartnerPropChange) then
        local mData = table_deep_copy(self.m_mPartnerPropChange)
        self.m_mPartnerPropChange = {}
        for pid, mPartners in pairs(mData) do
            local oPlayer = self:GetOnlinePlayerByPid(pid)
            if oPlayer and next(mPartners) then
                for partnerid, v in pairs(mPartners) do
                    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(partnerid)
                    if oPartner and next(v) then
                        safe_call(oPartner.ClientPropChange,oPartner,oPlayer,v)
                    end
                end
            end
        end
    end
end

function CWorldMgr:WorldDispatchFinishHook()
    self:SendPlayerPropChange()
    self:SendPartnerPropChange()
end

function CWorldMgr:DispatchWarFilmId()
    self:Dirty()
    self.m_iGlobalWarFilmId = self.m_iGlobalWarFilmId + 1
    return string.format("%d%d",get_server_id(),self.m_iGlobalWarFilmId)
end

function CWorldMgr:DispatchItemID()
    local id = self.m_iGlobalItemId + 1
    self.m_iGlobalItemId = id
    return id
end

function CWorldMgr:OnServerStartEnd()
    global.oMergerMgr:OnServerStartEnd()

    interactive.Send(".login", "login", "SetGateOpenStatus", {status = 1})
    global.oHuodongMgr:OnServerStartEnd()
end

--玩法控制
function CWorldMgr:IsClose(sKey)
    local mControlData = res["daobiao"]["global_control"][sKey]
    if not mControlData then
        return true
    end
    local sControl = mControlData["is_open"] or "y"
    if sControl == "n" then
        return true
    end
    return false
end

function CWorldMgr:QueryControl(sPlay,sKey)
    local mControlData = res["daobiao"]["global_control"][sPlay]
    assert(mControlData,string.format("err global_control %s",sPlay))
    local val = mControlData[sKey]
    assert(val,string.format("err global_control key %s %s",sPlay,sKey))
    return val
end

function CWorldMgr:QueryGlobalData(sKey)
    local mControlData = res["daobiao"]["global"][sKey]
    assert(mControlData,string.format("err global data %s",sKey))
    local val = mControlData.value
    assert(val,string.format("err global data %s",sKey,val))
    return val
end

function CWorldMgr:GetNowTime()
    return global.g_TestTime or get_time()
end

function CWorldMgr:RandomName(iSex)
    local mData  = res["daobiao"]["randomname"]
    iSex = iSex or 1
    local f = function ()
        local mName,idx = extend.Random.random_choice(mData)
        local sFirst = mName["firstName"]
        local sMale
        if iSex == 1 then
            sMale = mName["maleName"]
        else
            sMale = mName["femaleName"]
        end
        local sMid = ""
        if #mName["midName"] > 0 and math.random(2) > 1 then
            sMid = extend.Random.random_choice(mName["midName"])
        end
        return sFirst..sMid..sMale
    end
    local sName = "MisakaMikoto"
    for i=1,1000 do
        local sNew = f()

        if string.len(sNew) > 0 and string.len(sNew) < 18 then
            sName = sNew
            break
        end
    end
    return sName
end

function CWorldMgr:RandomVirtualName(iSex)
    local mData  = res["daobiao"]["virtualname"]
    iSex = iSex or 1
    local f = function ()
        local mName,idx = extend.Random.random_choice(mData)
        local sFirst = mName["firstName"]
        local sMale
        if iSex == 1 then
            sMale = mName["maleName"]
        else
            sMale = mName["femaleName"]
        end
        local sMid = ""
        if #mName["midName"] > 0 and math.random(2) > 1 then
            sMid = extend.Random.random_choice(mName["midName"])
        end
        return sFirst..sMid..sMale
    end
    local sName = "MisakaMikoto"
    for i=1,1000 do
        local sNew = f()

        if string.len(sNew) > 0 and string.len(sNew) < 18 then
            sName = sNew
            break
        end
    end
    return sName
end

function CWorldMgr:OnlineAmount()
    return table_count(self.m_mOnlinePlayers)
end

function CWorldMgr:AssistSyncData(mRemoteData)
    for iPid,mChange in pairs(mRemoteData) do
        local oPlayer = self:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local bClientRefresh = false
            for sType,_ in pairs(mChange) do
                if sType == "equip" then
                    oPlayer:UpdateEquipShare()
                    oPlayer:ActivePropChange()
                end
            end
        end
    end
end

function CWorldMgr:SyncPowerData()
    local mPower = res["daobiao"]["school_convert_power"]
    for iSchool,mData in pairs(mPower) do
        ppower.SyncPowerData("school"..iSchool,mData)
    end
end

function CWorldMgr:RecordOpen(sName)
    local oHuodong = global.oHuodongMgr:GetHuodong("rewardback")
    if oHuodong then
        oHuodong:RecordOpen(sName)
    end
end

function CWorldMgr:GetUpDataRes(sDaobiao, idx)
    idx = idx or 0
    local mData = res["daobiao"][sDaobiao]
    mData = mData and mData[idx]
    -- if not mData then
    --     print(debug.traceback(string.format("daobiao:%s,idx:%s not exist", sDaobiao, idx)))
    -- end
    return mData
end