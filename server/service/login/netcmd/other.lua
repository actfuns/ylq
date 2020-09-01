--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function C2GSBigPacket(oConn, mData)
    local iClientType = mData.type
    local sData = mData.data
    local iTotal = mData.total
    local iIndex = mData.index
    local iFd = oConn:GetNetHandle()
    if iFd then
        oConn.m_oBigPacketMgr:HandleBigPacket(iClientType, sData, iTotal, iIndex, iFd)
    end
end

function C2GSClientSession(oConn,mData)
    local iSessionIdx = mData["session"]
    local mNet = {
        session = iSessionIdx
    }
    oConn:Send("GS2CSessionResponse",mNet)
end
