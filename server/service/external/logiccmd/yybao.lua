--import module
local global = require "global"
local skynet = require "skynet"
local cjson = require "cjson"
local interactive = require "base.interactive"
local record = require "public.record"
local httpuse = require "public.httpuse"
local router = require "base.router"


function ForwardCmd(mRecord, mData)
    local oYYBaoSdk = global.oYYBaoSdk
    local oYYBaoObj = global.oYYBaoObj
    local sCmd = mData.cmd
    local mArgs = mData.args
    local timestamp = mArgs.timestamp
    local mRet = {
        code=0,
        msg="parameter not have cmd ".. sCmd,
    }
    if not timestamp then
        mRet.msg = "invalid timestamp"
        mRet.sign = oYYBaoSdk:BackSign(mRet.code,get_time())
        interactive.Response(mRecord.source, mRecord.session, mRet)
        return
    end

    local iDis = math.abs(timestamp-get_time()) // 60
    if iDis >= 5 then
        mRet.msg = "时间戳已经到期"
        mRet.sign = oYYBaoSdk:BackSign(mRet.code,timestamp)
        interactive.Response(mRecord.source, mRecord.session, mRet)
        return
    end

    local sSign = mArgs.sign
    mArgs.sign = nil

    if oYYBaoSdk:EnterSign(mArgs) ~= sSign then
        mRet.msg = "invalid sign"
        mRet.sign = oYYBaoSdk:BackSign(mRet.code,timestamp)
        interactive.Response(mRecord.source, mRecord.session, mRet)
        return
    end

    if sCmd then
        local callback = function (mTrueRes)
            mTrueRes.sign = oYYBaoSdk:BackSign(mTrueRes.code,timestamp)
            interactive.Response(mRecord.source, mRecord.session, mTrueRes)
        end
        local func = oYYBaoObj[sCmd]
        if func then
            mRet.code = 1
            mRet.msg = "成功"
            func(oYYBaoObj,mRet,mArgs,callback)
            return
        end
    end

    mRet.sign = oYYBaoSdk:BackSign(mRet.code,timestamp)
    interactive.Response(mRecord.source, mRecord.session, mRet)
end
