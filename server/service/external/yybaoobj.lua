--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local record = require "public.record"
local cjson = require "cjson"
local bson = require "bson"
local httpuse = require "public.httpuse"
local router = require "base.router"

local gamedb = import(lualib_path("public.gamedb"))
local serverinfo = import(lualib_path("public.serverinfo"))
local timectrl = import(lualib_path("public.timectrl"))
local defines = import(service_path("defines"))

function NewYYBaoObj(...)
    local o = CYYBaoObj:New(...)
    return o
end

function NewThisTemp(...)
    local o = timectrl.CThisTemp:New(...)
    return o
end

CYYBaoObj = {}
CYYBaoObj.__index = CYYBaoObj

function CYYBaoObj:New()
    local o = setmetatable({}, self)
    o.m_oThisTemp = NewThisTemp()
    o.m_GiftList = {}
    o.m_IOSGiftList = {}
    return o
end

function CYYBaoObj:Init()
    self:Schedule()
    self:LoadGift()
    self:LoadGiftIOS()
end

function CYYBaoObj:Schedule()
    local f1
    f1 = function ()
        skynet.timeout(10 * 60 * 100, f1)
        self:CheckCaChe()
    end
    f1()
end

function CYYBaoObj:CheckCaChe()
    local mKey = table_key_list(self.m_oThisTemp.m_mKeepList)
    for _,sKey in pairs(mKey) do
        self.m_oThisTemp:Validate(sKey)
    end
end

function CYYBaoObj:DesEncode(mRet)
    mRet.data = global.oYYBaoSdk:Encode( cjson.encode(mRet.data) )
end

function CYYBaoObj:GetServerConfig(sServerKey)
    return serverinfo.get_gs_info(sServerKey)
end

function CYYBaoObj:GetServerInfo(mRet,mArgs,callback)
    router.Request("cs", ".serversetter", "common", "GetServerList", {}, function (r, d)
        self:GetServerInfo2(d.data,mRet,callback)
    end)
end

function CYYBaoObj:GetServerInfo2(mServerInfo,mRet,callback)
    local mBackInfo = self.m_oThisTemp:Query("ServerInfo")
    if mBackInfo then
        mRet.data = mBackInfo
        callback(mRet)
        return
    end
    mRet.data = {rdata={}}
    for _,info in pairs(mServerInfo) do
        table.insert(mRet.data.rdata,{
            ServerName = info.name or "未知服务器",
            ServeID = info.id,
            ServerAttach = "给应用宝用",
            ServerRange = 3,
            OpenServerTime = defines.FormatTimeToSec(info.open_time),
        })
    end
    self:DesEncode(mRet)
    self.m_oThisTemp:Set("ServerInfo",mRet.data,10*60)
    callback(mRet)
end

function CYYBaoObj:GetRoleInfo(mRet,mArgs,callback)
    local sAccount = mArgs.openid
    if not sAccount then
        mRet.code = 0
        mRet.msg = "not have openid"
        callback(mRet)
        return
    end
    sAccount = string.lower(sAccount)
    local sServerKey = mArgs.serverid
    if not sServerKey then
        mRet.code = 0
        mRet.msg = "not have serverid"
        callback(mRet)
        return
    end
    if not self:GetServerConfig(sServerKey) then
        mRet.code = 0
        mRet.msg = "not have this server"
        callback(mRet)
        return
    end
    local mRoleInfo = self.m_oThisTemp:Query(sServerKey..sAccount)
    if mRoleInfo then
        mRet.data = mRoleInfo
        callback(mRet)
        return
    end
    local mArgs = {
        serverkey = sServerKey,
        dbname = "game",
        tablename = "player",
        search = {account=sAccount},
        back = {pid=true, name=true, account=true, base_info=true},
    }
    mRet.data = {rdata={}}
    gamedb.LoadDb("yybao","common","QuerySlaveDb", mArgs, function (mRecord,mData)
        mData = mData or {}
        for _,mUnit in pairs(mData) do
            table.insert(mRet.data.rdata,{
                OpenID = mUnit.account,
                ServeID = sServerKey,
                RoleID = mUnit.pid,
                RoleName = mUnit.name,
                CreateTime = defines.FormatTimeToSec(mUnit.base_info.create_time)
            })
        end
        if #mRet.data.rdata <= 0 then
            mRet.data = nil
            mRet.code = 101
            mRet.msg = "您登录的游戏帐号没有创建角色"
            callback(mRet)
            return
        end
        self:DesEncode(mRet)
        self.m_oThisTemp:Set(sServerKey..sAccount,mRet.data,5*60)
        callback(mRet)
    end)
end


function CYYBaoObj:RewardCurrency(mRet,mArgs,callback)
    -- print ("reward_currency----",mArgs)
    -- mRet.data = {LogId="12345"}
    -- callback(mRet)
end

function CYYBaoObj:LoadGift()
    gamedb.LoadDb("yybao","yybao", "LoadPlayerGift", {}, function (mRecord, mData)
        self:LoadGiftFinish(mData.data)
    end)
end

function CYYBaoObj:LoadGiftFinish(mData)
    mData = mData or {}
    for _,mInfo in pairs(mData) do
        local pid = mInfo.pid
        local mGift = mInfo.gift
        if pid and mGift then
            self.m_GiftList[pid] = mGift
        end
    end
end

function CYYBaoObj:SavePlayerGift(pid)
    local mGift = self.m_GiftList[pid]
    if not mGift then return end
    gamedb.SaveDb("yybao","yybao","SavePlayerGift",{
        pid = pid,
        gift = mGift,
    })
end

function CYYBaoObj:UpdateGift(pid,gid,val)
    local mGift = self.m_GiftList[pid] or {}
    mGift[gid] = val
    self.m_GiftList[pid] = mGift
    self:SavePlayerGift(pid)
end

function CYYBaoObj:GetPlayerGiftVal(pid,gid)
    local mGift = self.m_GiftList[pid] or {}
    return mGift[gid]
end

function CYYBaoObj:RewardHDGift(mRet,mArgs,callback)
    local sDevice = mArgs.device
    if not table_in_list({"ios","android"},sDevice) then
        mRet.code = 103
        mRet.msg = "无该设备礼包奖励"
        callback(mRet)
        return
    end
    local res = require "base.res"
    local mDbGift = {}
    if sDevice == "android" then
        mDbGift = res["daobiao"]["yybaogift"]
    elseif sDevice == "ios" then
        mDbGift = res["daobiao"]["qqgift"]
    end
    local gid = mArgs.taskid
    if not gid or not mDbGift[gid] then
        mRet.code = 103
        mRet.msg = "无该礼包奖励"
        callback(mRet)
        return
    end
    local openid = mArgs.openid or ""
    openid = string.lower(openid)
    local serverid = mArgs.serverid
    local sFlag = "Role_"..openid
    if serverid then
        sFlag = sFlag .. "_" .. serverid
    end
    local mQuery = self.m_oThisTemp:Query(sFlag)
    if not mQuery then
        gamedb.LoadDb("yybao","yybao", "QueryRoleList", {account=openid,serverid=serverid},
        function (mRecord, mData)
            local mQuery = mData.data or {}
            self.m_oThisTemp:Set(sFlag,mQuery,10*60)
            if sDevice == "android" then
                self:RewardHDGift2(mRet,mArgs,callback,mQuery)
            elseif sDevice == "ios" then
                self:RewardHDGiftIOS(mRet,mArgs,callback,mQuery)
            end
        end)
    else
        if sDevice == "android" then
            self:RewardHDGift2(mRet,mArgs,callback,mQuery)
        elseif sDevice == "ios" then
            self:RewardHDGiftIOS(mRet,mArgs,callback,mQuery)
        end
    end
end

function CYYBaoObj:DispatchId()
    self.m_DispatchLogID = self.m_DispatchLogID or 0
    self.m_DispatchLogID = self.m_DispatchLogID + 1
    return self.m_DispatchLogID
end

function CYYBaoObj:RewardHDGift2(mRet,mArgs,callback,mQuery)
    mQuery = mQuery or {}
    if #mQuery < 1 then
        mRet.code = 101
        mRet.msg = "您登录的游戏账号没有创建角色"
        callback(mRet)
        return
    end
    local mRole = {}
    for _,info in pairs(mQuery) do
        local pid,sServerKey = table.unpack(info)
        mRole[pid] = sServerKey
    end
    local roleid = mArgs.roleid
    if roleid then
        if not mRole[roleid] then
            mRet.code = 103
            mRet.msg = "错误角色ID"
            callback(mRet)
            return
        end
        mRole = {[roleid]=mRole[roleid]}
    end
    local sDevice = mArgs.device
    local gid = mArgs.taskid
    local res = require "base.res"
    local mDbGift = res["daobiao"]["yybaogift"]
    local bSuc = false
    local iDayNo = get_dayno()
    local mRData = {}
    for pid,sServerKey in pairs(mRole) do
        local iVal = self:GetPlayerGiftVal(pid,gid)
        local mUnit = mDbGift[gid] or {}
        if mUnit.stype == "day" then
            if iVal ~= iDayNo then
                bSuc = true
                self:RewardHDGiftFinnal(pid,sServerKey,gid,iDayNo)
                local LogId = "".. pid .."_" .. gid .."_".. iDayNo
                table.insert(mRData,{LogId=LogId})
            end
        elseif mUnit.stype == "test" then
            bSuc = true
            self:RewardHDGiftFinnal(pid,sServerKey,gid,iDayNo)
            local LogId = "" .. pid .."_"..gid.."_".. iDayNo.."_s"..self:DispatchId()
            table.insert(mRData,{LogId=LogId})
        else
            if not iVal then
                bSuc = true
                self:RewardHDGiftFinnal(pid,sServerKey,gid,iDayNo)
                local LogId = "".. pid .."_" .. gid .."_".. iDayNo
                table.insert(mRData,{LogId=LogId})
            end
        end
    end
    if bSuc then
        if #mRData > 1 then
            mRet.data = {rdata=mRData}
        else
            mRet.data = mRData[1]
        end
        self:DesEncode(mRet)
        callback(mRet)
    else
        mRet.code = 102
        mRet.msg = "该步骤奖励已发放过"
        callback(mRet)
    end
end

function CYYBaoObj:RewardHDGiftFinnal(pid,sServerKey,gid,iDayNo)
    self:UpdateGift(pid,gid,iDayNo)
    router.Send(get_server_tag(sServerKey), ".world", "backend", "RewardYYBaoGift", {
        pid=pid,
        gid=gid,
    })
end

function CYYBaoObj:LoadGiftIOS()
    gamedb.LoadDb("yybao","yybao", "LoadPlayerIOSGift", {}, function (mRecord, mData)
        self:LoadGiftIOSFinish(mData.data)
    end)
end

function CYYBaoObj:LoadGiftIOSFinish(mData)
    mData = mData or {}
    for _,mInfo in pairs(mData) do
        local pid = mInfo.pid
        local mGift = mInfo.iosgift
        if pid and mGift then
            self.m_IOSGiftList[pid] = mGift
        end
    end
end

function CYYBaoObj:SavePlayerIOSGift(pid)
    local mGift = self.m_IOSGiftList[pid]
    if not mGift then return end
    gamedb.SaveDb("yybao","yybao","SavePlayerIOSGift",{
        pid = pid,
        iosgift = mGift,
    })
end

function CYYBaoObj:UpdateGiftIOS(pid,gid,val)
    local mGift = self.m_IOSGiftList[pid] or {}
    mGift[gid] = val
    self.m_IOSGiftList[pid] = mGift
    self:SavePlayerIOSGift(pid)
end

function CYYBaoObj:GetPlayerGiftIOSVal(pid,gid)
    local mGift = self.m_IOSGiftList[pid] or {}
    return mGift[gid]
end

function CYYBaoObj:RewardHDGiftIOS(mRet,mArgs,callback,mQuery)
    mQuery = mQuery or {}
    if #mQuery < 1 then
        mRet.code = 101
        mRet.msg = "您登录的游戏账号没有创建角色"
        callback(mRet)
        return
    end
    local mRole = {}
    for _,info in pairs(mQuery) do
        local pid,sServerKey = table.unpack(info)
        mRole[pid] = sServerKey
    end
    local roleid = mArgs.roleid
    if roleid then
        if not mRole[roleid] then
            mRet.code = 103
            mRet.msg = "错误角色ID"
            callback(mRet)
            return
        end
        mRole = {[roleid]=mRole[roleid]}
    end
    local sDevice = mArgs.device
    local gid = mArgs.taskid
    local res = require "base.res"
    local mDbGift = res["daobiao"]["qqgift"]
    local bSuc = false
    local iDayNo = get_dayno()
    local mRData = {}

    for pid,sServerKey in pairs(mRole) do
        local iVal = self:GetPlayerGiftIOSVal(pid,gid)
        local mUnit = mDbGift[gid] or {}
        local sType = mUnit.stype

        if table_in_list({"newman","supervip","openvip"},sType) then
            if not iVal then
                bSuc = true
                self:RewardHDGiftIOSFinnal(pid,sServerKey,gid,iDayNo)
                local LogId = "".. pid .."_" .. gid .."_".. iDayNo
                table.insert(mRData,{LogId=LogId})
            end
        elseif sType == "test" then
            bSuc = true
            self:RewardHDGiftIOSFinnal(pid,sServerKey,gid,iDayNo)
            local LogId = "" .. pid .."_"..gid.."_".. iDayNo.."_s"..self:DispatchId()
            table.insert(mRData,{LogId=LogId})
        elseif table_in_list({"specialvip1","specialvip2"},sType) then
            bSuc = true
            self:RewardHDGiftIOSFinnal(pid,sServerKey,gid,iDayNo)
            local LogId = "".. pid .."_" .. gid .."_".. iDayNo.."_nl"..self:DispatchId()
            table.insert(mRData,{LogId=LogId})
        end
    end
    if bSuc then
        if #mRData > 1 then
            mRet.data = {rdata=mRData}
        else
            mRet.data = mRData[1]
        end
        self:DesEncode(mRet)
        callback(mRet)
    else
        mRet.code = 102
        mRet.msg = "该步骤奖励已发放过"
        callback(mRet)
    end
end

function CYYBaoObj:RewardHDGiftIOSFinnal(pid,sServerKey,gid,iDayNo)
    self:UpdateGiftIOS(pid,gid,iDayNo)
    router.Send(get_server_tag(sServerKey), ".world", "backend", "RewardIOSGift", {
        pid=pid,
        gid=gid,
    })
end