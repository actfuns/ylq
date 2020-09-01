--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"
local httpuse = require "public.httpuse"
local router = require "base.router"
local extend = require "base.extend"

local gamedb = import(lualib_path("public.gamedb"))
local serverinfo = import(lualib_path("public.serverinfo"))
local datactrl = import(lualib_path("public.datactrl"))

function NewPunishMgr(...)
    local o = CPunishMgr:New(...)
    return o
end

CPunishMgr = {}
CPunishMgr.__index = CPunishMgr
CPunishMgr.c_sDbKey = "punish"
inherit(CPunishMgr, datactrl.CDataCtrl)

function CPunishMgr:New()
    local o = super(CPunishMgr).New(self)
    o.m_bLoading = true
    o.m_BanLoginAct = {}
    o.m_BanLoginRole = {}
    o.m_BanChatAct = {}
    o.m_BanChatRole = {}
    return o
end

function CPunishMgr:Save()
    local mData = {}
    mData.banloginact = self.m_BanLoginAct or {}
    mData.banloginrole = self.m_BanLoginRole or {}
    mData.banchatact = self.m_BanChatAct or {}
    mData.banchatrole = self.m_BanChatRole or {}
    return mData
end

function CPunishMgr:Load(mData)
    mData = mData or {}
    self.m_BanLoginAct = mData.banloginact or {}
    self.m_BanLoginRole = mData.banloginrole or {}
    self.m_BanChatAct = mData.banchatact or {}
    self.m_BanChatRole = mData.banchatrole or {}
end

function CPunishMgr:IsLoading()
    return self.m_bLoading
end

function CPunishMgr:Init()
    if not self:IsLoading() then return end
    local mData = {
        name = self.c_sDbKey
    }
    local mArgs = {
        module = "global",
        cmd = "LoadGlobal",
        data = mData
    }
    gamedb.LoadDb("punish","common", "LoadDb", mArgs,
        function (mRecord, mData)
            if self:IsLoading() then
                self:Load(mData.data)
                self.m_bLoading = false
                self:Schedule()
            end
    end)
end

function CPunishMgr:SaveDb()
    if self:IsDirty() then
        local mData = {
            name = self.c_sDbKey,
            data = self:Save()
        }
        gamedb.SaveDb("punish","common", "SaveDb", {module="global",cmd="SaveGlobal",data = mData})
        self:UnDirty()
    end
end

function CPunishMgr:Schedule()
    local f1
    f1 = function ()
        self:DelTimeCb("ClearOverTime")
        self:AddTimeCb("ClearOverTime", 50*60*1000 , f1)
        self:ClearOverTime()
    end
    f1()
end

function CPunishMgr:ClearOverTime()
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
    self:Dirty()
    self:SaveDb()
end

function CPunishMgr:PunishBadPerson(sType,sKey,iTime)
    iTime = tonumber(iTime)
    if iTime <= 0 or iTime > 7*24*3600 then
        record.warning(sType.." time over : "..iTime)
        return
    end
    local mList
    if sType == "banloginact" then
        mList = self.m_BanLoginAct
    elseif sType == "banloginrole" then
        mList = self.m_BanLoginRole
    elseif sType == "banchatact" then
        mList = self.m_BanChatAct
    elseif sType == "banchatrole" then
        mList = self.m_BanChatRole
    end
    self:Dirty()
    mList[sKey] = get_time() + iTime*60
    self:SaveDb()
    self:SyncPunish(sType,sKey,mList[sKey])
end

function CPunishMgr:CanCelPerson(sType,sKey)
    local mList,mList2
    if sType == "cancelbanact" then
        mList = self.m_BanLoginAct
        mList2 = self.m_BanChatAct
    elseif sType == "cancelbanrole" then
        mList = self.m_BanLoginRole
        mList2 = self.m_BanChatRole
    end
    self:Dirty()
    mList[sKey] = nil
    mList2[sKey] = nil
    self:SaveDb()
    self:SyncPunish(sType,sKey)
end

function CPunishMgr:SyncPunish(sType,sKey,Value)
    local sData = extend.Table.serialize({
                type=sType,
                key=sKey,
                value=Value,
    })
    local mService
    if sType == "banloginact" or sType == "banloginrole" then
        mService = {".login"}
    elseif sType == "banchatact" or sType == "banchatrole" then
        mService = {".world"}
    elseif sType == "cancelbanact" or sType == "cancelbanrole" then
        mService = {".login",".world"}
    end
    if mService then
        local mServer = serverinfo.GS_INFO
        for sServerKey,_ in pairs(mServer) do
            for _,sService in pairs(mService) do
                router.Send(get_server_tag(sServerKey), sService, "punish", "SyncPunish", sData)
            end
        end
    end
end

function CPunishMgr:GetBanLoginInfo()
    return {
        act = self.m_BanLoginAct ,
        role = self.m_BanLoginRole
    }
end

function CPunishMgr:GetBanChatInfo()
    return {
        act = self.m_BanChatAct,
        role = self.m_BanChatRole
    }
end

function CPunishMgr:GetBanInfo()
    return {
        banloginact = self.m_BanLoginAct,
        banloginrole = self.m_BanLoginRole,
        banchatact = self.m_BanChatAct,
        banchatrole = self.m_BanChatRole
    }
end