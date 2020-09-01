--import module

local global = require "global"
local skynet = require "skynet"
local router = require "base.router"
local record = require "public.record"

function Invoke(iCmd, fd, mData)
    local oGateMgr = global.oGateMgr
    local oConn = oGateMgr:GetConnection(fd)
    if oConn then
        if iCmd == router.PROTO_P2R.P2RRouter then
            local mPRecord = mData.record
            oGateMgr:SendR2P(mPRecord.dessk, router.PROTO_R2P.R2PRouter, mData)
        elseif iCmd == router.PROTO_P2R.P2RHeartBeat then
            local sServerKey = mData.sk
            oConn:HandleHeartBeat(sServerKey)
        elseif iCmd == router.PROTO_P2R.P2RRouterBig then
            oGateMgr:SendR2P(mData.sk, router.PROTO_R2P.R2PRouterBig, mData)
        else
            record.warning(string.format("router_s netcmd fail %d", iCmd))
        end
    end
end
