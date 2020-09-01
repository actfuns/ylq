--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"
local httpuse = require "public.httpuse"
local router = require "base.router"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))

function NewFuliMgr(...)
    local o = CFuliMgr:New(...)
    return o
end

CFuliMgr = {}
CFuliMgr.__index = CFuliMgr
CFuliMgr.c_sDbKey = "accountfuli"
inherit(CFuliMgr, datactrl.CDataCtrl)

function CFuliMgr:New()
    local o = super(CFuliMgr).New(self)
    o.m_bLoading = true
    o.m_TestFuliAct = {}
    o.m_ChargeAct = {}
    o.m_BackPartner = {}
    o.m_ChargeBack = {} --充值返利
    o.m_RushRank = {} --冲榜返利
    return o
end

function CFuliMgr:Save()
    local mData = {}
    mData.fuli = table_key_list(self.m_TestFuliAct)
    mData.charge = self.m_ChargeAct
    mData.backpartner = self.m_BackPartner
    mData.chargeback = self.m_ChargeBack
    mData.rushrank = self.m_RushRank
    return mData
end

function CFuliMgr:Load(mData)
    mData = mData or {}
    local mFuli = mData.fuli or {}
    for _,sAccount in pairs(mFuli) do
        self.m_TestFuliAct[sAccount] = true
    end
    self.m_ChargeAct = mData.charge or {}
    self.m_BackPartner = mData.backpartner or {}
    self.m_ChargeBack = mData.chargeback or {}
    self.m_RushRank = mData.rushrank or {}
end

function CFuliMgr:IsLoading()
    return self.m_bLoading
end

function CFuliMgr:Init()
    if not self:IsLoading() then return end
    local mData = {
        name = self.c_sDbKey
    }
    local mArgs = {
        module = "fulidb",
        cmd = "LoadFuli",
        data = mData
    }
    gamedb.LoadDb("fuli","common", "LoadDb", mArgs,
        function (mRecord, mData)
            if self:IsLoading() then
                self:Load(mData.data)
                self.m_bLoading = false
                self:ConfigSaveFunc()
            end
    end)
end

function CFuliMgr:SaveDb()
    if self:IsDirty() then
        local mData = {
            name = self.c_sDbKey,
            data = self:Save()
        }
        gamedb.SaveDb("fuli","common", "SaveDb", {module="fulidb",cmd="SaveFuli",data = mData})
        self:UnDirty()
    end
end

function CFuliMgr:_CheckSaveDb()
    assert(not self:IsLoading(), "FuliMgr save fail: is loading")
    self:SaveDb()
end

function CFuliMgr:ConfigSaveFunc()
    -- self:ApplySave(function ()
    --     local obj = global.oFuliMgr
    --     if obj then
    --         obj:_CheckSaveDb()
    --     else
    --         record.warning("FuliMgr save err: no obj")
    --     end
    -- end)
end

function CFuliMgr:FuliPass(sAccount)
    if type(sAccount) ~= "string" then
        return
    end
    self:Dirty()
    self.m_TestFuliAct[sAccount] = true
    self:SaveDb()
end

function CFuliMgr:HasTestFuliAuth(sAccount)
    -- return false
    if self.m_TestFuliAct[sAccount] then
        self:Dirty()
        self.m_TestFuliAct[sAccount] = nil
        self:SaveDb()
        return true
    end
    return false
end

function CFuliMgr:ChargeAct(sAccount,iAdd)
    self:Dirty()
    local mChargeAct = self.m_ChargeAct
    mChargeAct[sAccount] = mChargeAct[sAccount] or 0
    mChargeAct[sAccount] = mChargeAct[sAccount] + iAdd
    self.m_ChargeAct = mChargeAct
    self:SaveDb()
end

function CFuliMgr:GetActCharge(sAccount)
    self:Dirty()
    local iVal = self.m_ChargeAct[sAccount] or 0
    self.m_ChargeAct[sAccount] = nil
    self:SaveDb()
    return iVal
end

function CFuliMgr:SetBackPartner(sAccount,iSid,iStar)
    self:Dirty()
    self.m_BackPartner[sAccount] = {iSid,iStar}
    self:SaveDb()
end

function CFuliMgr:GetBackPartner(sAccount)
    self:Dirty()
    local mInfo = self.m_BackPartner[sAccount]
    self.m_BackPartner[sAccount] = nil
    self:SaveDb()
    return mInfo
end

function CFuliMgr:UpdateChargeBack(sAccount,mInfo)
    self:Dirty()
    local mUnit = self.m_ChargeBack[sAccount] or {}

    mUnit.backrmb = mInfo.backrmb or mUnit.backrmb
    mUnit.backgold = mInfo.backgold or mUnit.backgold
    mUnit.month = mInfo.month or mUnit.month
    mUnit.zsk = mInfo.zsk or mUnit.zsk
    mUnit.fund = mInfo.fund or mUnit.fund
    mUnit.onegift = mInfo.onegift or mUnit.onegift
    mUnit.gradegift = mInfo.gradegift or mUnit.gradegift
    mUnit.special = mInfo.special or mUnit.special
    mUnit.skin = mInfo.skin or mUnit.skin

    self.m_ChargeBack[sAccount] = mUnit
    self:SaveDb()
end

function CFuliMgr:UpdateRushRankBack(mData)
    mData = mData or {}
    if next(mData) then
        self:Dirty()
        for sAccount, m in pairs(mData) do
            local mm = self.m_RushRank[sAccount] or {}
            table_combine(mm, m)
            self.m_RushRank[sAccount] = mm
        end
        self:SaveDb()
    end
end

function CFuliMgr:QueryChargeBack(sAccount)
    self:Dirty()
    local mInfo = self.m_ChargeBack[sAccount] or {}
    self.m_ChargeBack[sAccount] = nil
    self:SaveDb()
    return mInfo
end

function CFuliMgr:QueryRushRank(sAccount)
    self:Dirty()
    local mInfo = self.m_RushRank[sAccount] or {}
    self.m_RushRank[sAccount] = nil
    self:SaveDb()
    return mInfo
end