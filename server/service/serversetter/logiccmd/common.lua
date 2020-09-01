--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function GetClientServerList(mRecord, mData)
    local oSetterMgr = global.oSetterMgr
    local br, m = safe_call(oSetterMgr.GetClientServerList, oSetterMgr, mData)
    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1}
    end
    interactive.Response(mRecord.source, mRecord.session, mRet)
end