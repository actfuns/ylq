--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function ClientVerifyAccount(mRecord, mData)
    local oVerifyMgr = global.oVerifyMgr
    oVerifyMgr:ClientVerifyDemiChannel(mData, function (mData)
        interactive.Response(mRecord.source, mRecord.session, mData)
    end)
end

function ClientQRCodeScan(mRecord, mData)
    local sAccountToken = mData.account_token
    local sCodeToken = mData.code_token

    local oVerifyMgr = global.oVerifyMgr
    oVerifyMgr:ClientQRCodeScan(sAccountToken, sCodeToken, function (iErrCode)
        interactive.Response(mRecord.source, mRecord.session, {errcode = iErrCode})
    end)
end

function ClientQRCodeLogin(mRecord, mData)
    local sAccountToken = mData.account_token
    local sCodeToken = mData.code_token
    local mOther = {
        notice_ver = mData.notice_ver
    }
    local mTransferInfo = mData.transfer_info or {}

    local oVerifyMgr = global.oVerifyMgr
    oVerifyMgr:ClientQRCodeLogin(sAccountToken, sCodeToken, mOther, mTransferInfo, function (iErrCode)
        interactive.Response(mRecord.source, mRecord.session, {errcode = iErrCode})
    end)
end