--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

function C2GSQueryLogin(oConn,mData)
    local oGateMgr = global.oGateMgr
    oConn:QueryLogin(mData)
end

function C2GSLoginAccount(oConn, mData)
    local oGateMgr = global.oGateMgr
    if not oGateMgr:IsOpen() then
        local iChannel = oConn:GetChannel()
        local sIP = oConn.m_sIP
        if not oGateMgr:ValidPlayerLogin(mData["account"],iChannel,sIP) then
            oConn:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.in_maintain})
            return
        end
    end
    if oGateMgr:IsLimit() then
        oConn:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.login_player_limit})
        return
    end
    oConn:LoginAccount(mData)
end

function C2GSLoginRole(oConn, mData)
    local oGateMgr = global.oGateMgr
    if not oGateMgr:IsOpen() then
        if not oGateMgr:ValidPlayerLogin(oConn.m_sAccount, oConn.m_iChannel, oConn.m_sIP) then
            oConn:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.in_maintain})
            return
        end
    end
    oConn:LoginRole(mData)
end

function C2GSCreateRole(oConn, mData)
    local oGateMgr = global.oGateMgr
    if not oGateMgr:IsOpen() then
        if not oGateMgr:ValidPlayerLogin(oConn.m_sAccount, oConn.m_iChannel, oConn.m_sIP) then
            oConn:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.in_maintain})
            return
        end
    end
    oConn:CreateRole(mData)
end

function C2GSReLoginRole(oConn, mData)
    oConn:ReLoginRole(mData)
end

function C2GSSetInviteCode(oConn,mData)
    local oGateMgr = global.oGateMgr
    if not oGateMgr:IsOpen() then
        if not oGateMgr:ValidPlayerLogin(oConn.m_sAccount, oConn.m_iChannel, oConn.m_sIP) then
            oConn:Send("GS2CLoginError", {pid = 0, errcode = gamedefines.ERRCODE.in_maintain})
            return
        end
    end
    oConn:SetInviteCode(mData)
end