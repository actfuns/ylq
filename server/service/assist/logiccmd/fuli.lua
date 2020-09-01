-- import module
local global = require "global"
local skyner = require "skynet"
local record = require "public.record"
local interactive = require "base.interactive"
local colorstring = require "public.colorstring"

function GetBackPartnerInfo(mRecord, mData)
    local iPid = mData.pid
    local iSid = mData.sid
    local iStar = mData.star
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer:Send("GS2CBackPartnerInfo",{sid=iSid,star=iStar,list=oPlayer.m_oPartnerCtrl:GetOnceOwn()})
    end
end
