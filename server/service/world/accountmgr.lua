--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local gamedb = import(lualib_path("public.gamedb"))
local gamedefines = import(lualib_path("public.gamedefines"))
local datactrl = import(lualib_path("public.datactrl"))

function NewAccountMgr(...)
    local o = CAccountMgr:New(...)
    return o
end

function NewAccount(...)
    local o = CAccount:New(...)
    return o
end

CAccountMgr = {}
CAccountMgr.__index = CAccountMgr
inherit(CAccountMgr, datactrl.CDataCtrl)

function CAccountMgr:New(lAssistRemote)
    local o = super(CAccountMgr).New(self)
    o.m_mAccount = {}
    o:InitData()
    return o
end

function CAccountMgr:InitData()
    local mData = {
        name = "player_account",
    }
    local mArg = {
        module = "global",
        cmd = "LoadGlobal",
        data = mData,
    }
    gamedb.LoadDb("account","common", "LoadDb",mArg, function (mRecord, mData)
        if not is_release(self) then
            local m = mData.data
            self:Load(m)
            self:OnLoaded()
        end
    end)
end

function CAccountMgr:ConfigSaveFunc()
    self:ApplySave(function ()
        local oAccountMgr = global.oAccountMgr
        oAccountMgr:CheckSaveDb()
    end)
end

function CAccountMgr:CheckSaveDb()
    if self:IsDirty() then
        local mData = {
            name = "player_account",
            data = self:Save(),
        }
        gamedb.SaveDb("account","common","SaveDb",{
            module = "global",
            cmd = "SaveGlobal",
            data = mData
        })
        self:UnDirty()
    end
end

function CAccountMgr:Save()
    local mData = {}
    local mAccountData = {}
    for sAccount,oAccount in pairs(self.m_mAccount) do
        mAccountData[sAccount] = oAccount:Save()
    end
    mData["account"] = mAccountData
    return mData
end

function CAccountMgr:Load(m)
    m = m or {}
    local mData = m["account"] or {}
    for sAccount,mAccountData in pairs(mData) do
        local oAccount = NewAccount(sAccount)
        oAccount:Load(mAccountData)
        self.m_mAccount[sAccount] = oAccount
    end
end

function CAccountMgr:MergeFrom(mFromData)
    self:Dirty()
    mFromData = mFromData or {}
    for sAccount,mAccountData in pairs(mFromData) do
        local oAccount = self:GetAccount(sAccount)
        if oAccount then
            oAccount:MergeFrom(mAccountData)
        else
            local oAccount = NewAccount(sAccount)
            oAccount:Load(mAccountData)
            self.m_mAccount[sAccount] = oAccount
        end
    end
    return true
end

function CAccountMgr:GetAccount(sAccount)
    return self.m_mAccount[sAccount]
end

function CAccountMgr:AccountBuyCZJJ(sAccount)
    self:Dirty()
    if not self.m_mAccount[sAccount] then
        self.m_mAccount[sAccount] = NewAccount(sAccount)
    end
    local oAccount = self:GetAccount(sAccount)
    oAccount:AccountBuyCZJJ()
end

function CAccountMgr:AccountIsBuyCZJJ(sAccount)
    local oAccount = self.m_mAccount[sAccount]
    if not oAccount then
        return false
    end
    if not oAccount:AccountIsBuyCZJJ() then
        return false
    end
    return true
end

CAccount = {}
CAccount.__index = CAccount
inherit(CAccount, datactrl.CDataCtrl)

function CAccount:New(sAccount)
    local o = super(CAccount).New(self)
    o.m_sAccount = sAccount
    o.m_iBuyCZJJ = 0
    return o
end

function CAccount:Load(mData)
    mData = mData or {}
    self.m_iBuyCZJJ = mData["czjj"] or self.m_iBuyCZJJ
end

function CAccount:Save()
    local mData = {}
    mData["czjj"] = self.m_iBuyCZJJ
    return mData
end

function CAccount:MergeFrom(mFromData)
end

function CAccount:AccountBuyCZJJ()
    self:Dirty()
    self.m_iBuyCZJJ = 1
end

function CAccount:AccountIsBuyCZJJ(sAccount)
    if self.m_iBuyCZJJ == 0 then
        return false
    end
    return true
end