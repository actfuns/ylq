--import module
local global = require "global"
local skynet = require "skynet"

function LoginResult(mRecord, mData)
    local oGateMgr = global.oGateMgr
    local oConnection = oGateMgr:GetConnection(mData.handle)
    if oConnection then
        oConnection:LoginResult(mData)
    end
end

function ReadyCloseGS(mRecord, mData)
    local oGateMgr = global.oGateMgr
    oGateMgr:SetOpenStatus(false)
end

function SetGateOpenStatus(mRecord, mData)
    local oGateMgr = global.oGateMgr
    oGateMgr:SetOpenStatus(mData.status)
end

function OnLogout(mRecord, mData)
    local oGateMgr = global.oGateMgr
    oGateMgr:OnLogout(mData)
end

function AddUnvalidName(mRecord,mData)
    local sName = mData["name"]
    local oGateMgr = global.oGateMgr
    oGateMgr:AddUnvalidName(sName)
end

function CleanUnValidName(mRecord,mData)
    local oGateMgr = global.oGateMgr
    oGateMgr:CleanUnValidName()
end