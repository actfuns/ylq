--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"

local baseobj = import(lualib_path("base.baseobj"))

INTERVAL_CHECK_TIME = 3 * 60
DISPATCH_TOKEN_MAX = 10000
HOLDON_TIME = 3 * 60
VALID_TIME = 10 * 60

function NewQRCodeMgr(...)
    local o = CQRCodeMgr:New(...)
    return o
end

CQRCodeMgr = {}
CQRCodeMgr.__index = CQRCodeMgr
inherit(CQRCodeMgr, baseobj.CBaseObject)

function CQRCodeMgr:New(sServiceKey)
    local o = super(CQRCodeMgr).New(self)
    o.m_sServiceKey = sServiceKey
    o.m_iDispatchToken = 0
    o.m_mCodeHandle = {}
    return o
end

function CQRCodeMgr:Init()
    self:Schedule()
end

function CQRCodeMgr:Schedule()
    local f1
    f1 = function ()
        self:DelTimeCb("_CheckValidToken")
        self:AddTimeCb("_CheckValidToken", INTERVAL_CHECK_TIME*1000, f1)
        self:_CheckValidToken()
    end
    self:AddTimeCb("_CheckValidToken", INTERVAL_CHECK_TIME*1000, f1)
end

function CQRCodeMgr:_CheckValidToken()
    local iNow = get_time()
    local lInvalidToken = {}
    for k, v in pairs(self.m_mCodeHandle) do
        if self:IsScanStatus(k) then
            if not self:ValidScanStatus(k) then
                table.insert(lInvalidToken, k)
            end
        elseif iNow - v.time > VALID_TIME then
            table.insert(lInvalidToken, k)
        end
    end
    for _, v in ipairs(lInvalidToken) do
        local oConn = self:GetConnection(v)
        if oConn then
            oConn:Send("GS2CQRCInvalid", {})
        end
        self:DelCodeToken(v)
    end
end

function CQRCodeMgr:GenerateCodeToken(oConn)
    self.m_iDispatchToken = self.m_iDispatchToken + 1
    if self.m_iDispatchToken >= DISPATCH_TOKEN_MAX then
        self.m_iDispatchToken = 1
    end
    local sUniqueKey = tostring(get_time() * DISPATCH_TOKEN_MAX + self.m_iDispatchToken)
    local sCodeToken = string.format("%s-%s", self.m_sServiceKey, sUniqueKey)
    self.m_mCodeHandle[sCodeToken] = {handle=oConn:GetHandle(), time=get_time()}
    return sCodeToken
end

function CQRCodeMgr:GetConnection(sCodeToken)
    local mInfo = self.m_mCodeHandle[sCodeToken]
    if not mInfo then
        return
    end
    local oGateMgr = global.oGateMgr
    local oConn = oGateMgr:GetConnection(mInfo.handle)
    if mInfo.time - get_time() > VALID_TIME then
        if oConn then
            oConn:Send("GS2CQRCInvalid", {})
        end
        self:DelCodeToken(sCodeToken)
        return
    end
    return oConn
end

function CQRCodeMgr:DelCodeToken(sCodeToken)
    local mInfo = self.m_mCodeHandle[sCodeToken]
    if mInfo then
        local oGateMgr = global.oGateMgr
        oGateMgr:KickConnection(mInfo.handle)
    end
    self.m_mCodeHandle[sCodeToken] = nil
end

function CQRCodeMgr:IsScanStatus(sCodeToken)
    local mInfo = self.m_mCodeHandle[sCodeToken]
    if mInfo then
        if mInfo.scan then
            return true
        end
    end
    return false
end

function CQRCodeMgr:ValidScanStatus(sCodeToken)
    local mInfo = self.m_mCodeHandle[sCodeToken]
    if mInfo then
        if mInfo.scan and mInfo.time + HOLDON_TIME >= get_time() then
            return true
        end
    end
    return false
end

function CQRCodeMgr:SendCodeToken(oConn)
    local sCodeToken = self:GenerateCodeToken(oConn)
    oConn:Send("GS2CQRCToken", {token=sCodeToken, validity=VALID_TIME})
end

function CQRCodeMgr:ScanQRCodeSuccess(sCodeToken)
    local oConn = self:GetConnection(sCodeToken)
    if not oConn then
        return
    end
    oConn:Send("GS2CQRCScanSuccess",{})
end

function CQRCodeMgr:CSSendAccountInfo(sCodeToken, account_info, transfer_info)
    local oConn = self:GetConnection(sCodeToken)
    if not oConn then
        return false
    end
    if not self:ValidScanStatus(sCodeToken) then
        oConn:Send("GS2CQRCInvalid", {})
        self:DelCodeToken(sCodeToken)
        return false
    end
    oConn:Send("GS2CQRCAccountInfo", {
        account_info = account_info,
        transfer_info = transfer_info,
    })
    self:DelCodeToken(sCodeToken)
    return true
end

function CQRCodeMgr:ScanQRCode(sCodeToken)
    if self:IsScanStatus(sCodeToken) then
        return false
    end
    local mInfo = self.m_mCodeHandle[sCodeToken]
    if not mInfo then
        return false
    end
    mInfo.scan = true
    mInfo.time = get_time()
    self:ScanQRCodeSuccess(sCodeToken)
    return true
end
