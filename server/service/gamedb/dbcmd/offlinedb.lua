--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sOfflineTableName = "offline"

function CreateOffline(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Insert(sOfflineTableName, mData.data)
end

function LoadOfflineProfile(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOfflineTableName, {pid = mData.pid}, {profile_info = true})

    local mRet
    if m then
        mRet = {
            success = true,
            data = m.profile_info or {},
            pid = mData.pid,
        }
    else
        mRet = {
            success = false,
        }
    end
    return mRet
end

function SaveOfflineProfile(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOfflineTableName, {pid = mData.pid}, {["$set"]={profile_info = mData.data}},true)
end

function LoadOfflineFriend(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOfflineTableName, {pid = mData.pid}, {friend_info = true})

    local mRet
    if m then
        mRet = {
            success = true,
            data = m.friend_info or {},
            pid = mData.pid,
        }
    else
        mRet = {
            success = false,
        }
    end

    return mRet
end

function SaveOfflineFriend(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOfflineTableName, {pid = mData.pid}, {["$set"]={friend_info = mData.data}},true)
end

function LoadOfflineMailBox(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOfflineTableName, {pid = mData.pid}, {mail_info = true})

    local mRet
    if m then
        mRet = {
            success = true,
            data = m.mail_info or {},
            pid = mData.pid,
        }
    else
        mRet = {
            success = false,
        }
    end

    return mRet
end

function SaveOfflineMailBox(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOfflineTableName, {pid = mData.pid}, {["$set"]={mail_info = mData.data}},true)
end

function LoadOfflinePartner(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOfflineTableName, {pid = mData.pid}, {partner_info = true})

    local mRet
    if m then
        mRet = {
            success = true,
            data = m.partner_info or {},
            pid = mData.pid,
        }
    else
        mRet = {
            success = false,
        }
    end

    return mRet
end

function SaveOfflinePartner(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOfflineTableName, {pid = mData.pid}, {["$set"]={partner_info = mData.data}},true)
end

function LoadOfflinePrivy(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOfflineTableName, {pid = mData.pid}, {privy_info = true})

    local mRet
    if m then
        mRet = {
            success = true,
            data = m.privy_info or {},
            pid = mData.pid,
        }
    else
        mRet = {
            success = false,
        }
    end

    return mRet
end

function SaveOfflinePrivy(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOfflineTableName, {pid = mData.pid}, {["$set"]={privy_info = mData.data}},true)
end

function LoadOfflineTravel(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOfflineTableName, {pid = mData.pid}, {travel_info = true})

    local mRet
    if m then
        mRet = {
            success = true,
            data = m.travel_info or {},
            pid = mData.pid,
        }
    else
        mRet = {
            success = false,
        }
    end
    return mRet
end

function SaveOfflineTravel(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOfflineTableName, {pid = mData.pid}, {["$set"]={travel_info = mData.data}},true)
end


function LoadOfflineRom(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sOfflineTableName, {pid = mData.pid}, {rom_info = true})

    local mRet
    if m then
        mRet = {
            success = true,
            data = m.rom_info or {},
            pid = mData.pid,
        }
    else
        mRet = {
            success = false,
        }
    end
    return mRet
end

function SaveOfflineRom(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sOfflineTableName, {pid = mData.pid}, {["$set"]={rom_info = mData.data}},true)
end

