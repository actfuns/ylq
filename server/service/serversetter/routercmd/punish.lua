--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"
local record = require "public.record"
local extend = require "base.extend"

function PunishBadPerson(mRecord, mData)
    mData = extend.Table.deserialize(mData)
    local oPunishMgr = global.oPunishMgr
    local br, m = safe_call(oPunishMgr.PunishBadPerson, oPunishMgr, mData.type, mData.key, mData.value)
    local mRet = {}
    if not br then
        record.error("PunishBadPerson error "..ConvertTblToStr(mData))
    end
end

function CanCelPerson(mRecord, mData)
    mData = extend.Table.deserialize(mData)
    local oPunishMgr = global.oPunishMgr
    local br, m = safe_call(oPunishMgr.CanCelPerson, oPunishMgr, mData.type, mData.key)
    local mRet = {}
    if not br then
        record.error("CanCelPerson error "..ConvertTblToStr(mData))
    end
end

function GetBanLoginInfo(mRecord, mData)
    local oPunishMgr = global.oPunishMgr
    local br, mRet = safe_call(oPunishMgr.GetBanLoginInfo, oPunishMgr)
    if not br then
        mRet = {error=0}
    end
    mRet = extend.Table.serialize(mRet)
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function GetBanChatInfo(mRecord, mData)
    local oPunishMgr = global.oPunishMgr
    local br, mRet = safe_call(oPunishMgr.GetBanChatInfo, oPunishMgr)
    if not br then
        mRet = {error=0}
    end
    mRet = extend.Table.serialize(mRet)
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end

function GetBanInfo(mRecord, mData)
    local oPunishMgr = global.oPunishMgr
    local br, mRet = safe_call(oPunishMgr.GetBanInfo, oPunishMgr)
    if not br then
        mRet = {error=0}
    end
    mRet = extend.Table.serialize(mRet)
    router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRet)
end