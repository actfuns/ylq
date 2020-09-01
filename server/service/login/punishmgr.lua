--import module

local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local res = require "base.res"
local record = require "public.record"
local router = require "base.router"
local extend = require "base.extend"

function NewPunishMgr(...)
    local o = CPunishMgr:New(...)
    return o
end

CPunishMgr = {}
CPunishMgr.__index = CPunishMgr
inherit(CPunishMgr, logic_base_cls())

function CPunishMgr:New()
    local o = super(CPunishMgr).New(self)
    o.m_BanLoginAct = {}
    o.m_BanLoginRole = {}
    return o
end

function CPunishMgr:Init()
    local f1
    f1 = function ()
        self:DelTimeCb("InitBanInfo")
        self:InitBanInfo()
    end
    self:AddTimeCb("InitBanInfo", 5*1000 , f1)
    self:Schedule()
end

function CPunishMgr:InitBanInfo()
    router.Request("cs",".serversetter", "punish", "GetBanLoginInfo", {}, function (mRecord,mData)
        mData = extend.Table.deserialize(mData)
        self:InitBanInfo2(mData)
    end)
end

function CPunishMgr:InitBanInfo2(mData)
    self.m_BanLoginAct = mData.act or {}
    self.m_BanLoginRole = mData.role or {}
end

function CPunishMgr:InActBan(sAccount)
    local iNowTime = get_time()
    local iEndTime = self.m_BanLoginAct[sAccount] or 0
    if iNowTime < iEndTime then
        return iEndTime - iNowTime
    end
    return false
end

function CPunishMgr:InRoleBan(pid)
    local iNowTime = get_time()
    local iEndTime = self.m_BanLoginRole[tostring(pid)] or 0
    if iNowTime < iEndTime then
        return iEndTime - iNowTime
    end
    return false
end

function CPunishMgr:SyncPunish(mArgs)
    local mList
    if mArgs.type == "banloginact" or mArgs.type == "cancelbanact" then
        mList = self.m_BanLoginAct
    elseif mArgs.type == "banloginrole" or mArgs.type == "cancelbanrole" then
        mList = self.m_BanLoginRole
    end
    mList[mArgs.key] = mArgs.value
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
    local mAttrs = {"m_BanLoginAct","m_BanLoginRole"}
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