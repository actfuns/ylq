--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local extend = require "base.extend"
local record = require "public.record"


function PrintConnectCnt(mRecord, mData)
    local oGateMgr = global.oGateMgr
    local iCnt = 0
    for _,oGate in pairs(oGateMgr.m_mGates) do
        iCnt = iCnt + table_count(oGate.m_mConnections)
    end
    record.info("connect cnt : "..iCnt)
end