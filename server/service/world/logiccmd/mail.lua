--import module
local global = require "global"
local skynet = require "skynet"

function RemoteFightPartner(mRecord, mData)
    local iPid = mData.pid
    local iPos = mData.pos
    local iParid = mData.parid
    local oMailMgr = global.oMailMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:SyncFightPartner(iPos, iParid, mData.data)
    end
end