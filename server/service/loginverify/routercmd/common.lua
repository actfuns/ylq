--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local router = require "base.router"


function GSGetVerifyAccount(mRecord, mData)
    local sToken = mData.token

    local oVerifyMgr = global.oVerifyMgr
    local mAccountInfo = oVerifyMgr:VerifyMyToken(sToken)
    if mAccountInfo then
        router.Response(mRecord.srcsk,mRecord.src,mRecord.session,{
            errcode = 0,
            account = mAccountInfo,
        })
    else
        router.Response(mRecord.srcsk,mRecord.src,mRecord.session,{
            errcode = 1,
        })
    end
end

function TestClientVerifyAccount(mRecord,mData)
    local sToken = mData.token
    local iDemiChannel = mData.demi_channel
    local sDeviceId = mData.device_id
    local sCpsChannel = mData.cps
    local sChannelUuid = mData.account
    local iPlatform = mData.platform
    local iNoticeVer = mData.notice_ver
    local mOther = {
        notice_ver = mData.notice_ver,
        packet_info = mData.packet_info or {},
    }

    local oVerifyMgr = global.oVerifyMgr
    oVerifyMgr:TestClientVerifyAccount(sToken, iDemiChannel, sDeviceId, sCpsChannel, sChannelUuid,iPlatform,mOther, function (mData)
        router.Response(mRecord.srcsk,mRecord.src,mRecord.session,mData)
    end)
end

function GSKeepTokenAlive(mRecord, mData)
    local sToken = mData.token

    local oVerifyMgr = global.oVerifyMgr
    oVerifyMgr:KeepTokenAlive(sToken)
end