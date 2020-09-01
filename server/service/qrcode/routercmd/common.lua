--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"

function CSSendAccountInfo(mRecord, mData)
    local sCodeToken = mData.code_token
    local account_info = mData.acount_info
    local transfer_info = mData.transfer_info

    local oQRCodeMgr = global.oQRCodeMgr
    local errcode = 0
    if not oQRCodeMgr:CSSendAccountInfo(sCodeToken, account_info, transfer_info) then
        errcode = 1
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, {
        errcode = errcode,
    })
end

function ScanQRCode(mRecord, mData)
    local sCodeToken = mData.code_token
    local errcode = 0
    if not global.oQRCodeMgr:ScanQRCode(sCodeToken) then
        errcode = 1
    end
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, {
        errcode = errcode,
    })
end
