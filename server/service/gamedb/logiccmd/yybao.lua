--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local dbcmd = import(service_path("dbcmd.init"))
local serverinfo = import(lualib_path("public.serverinfo"))

local sYYBaoTable = "yybao"
local sQQTable = "qqgift"

function SavePlayerGift(mRecord, mData)
    local pid = mData.pid
    local mGift = mData.gift
    local mQuery = {pid=pid}
    local mSaveData = {pid=pid,gift=mGift}
    if mSaveData then
        mongoop.ChangeBeforeSave(mSaveData)
    end
    local oGameDb = global.oGameDb
    oGameDb:Update(sYYBaoTable, mQuery, mSaveData, {upsert = true})
end

function LoadPlayerGift(mRecord,mData)
    local oGameDb = global.oGameDb
    local mLoadData = oGameDb:Find(sYYBaoTable,{},{pid=true,gift=true})
    local mRet = {data={}}
    while mLoadData:hasNext() do
        local mUnit = mLoadData:next()
        if mUnit then
            mongoop.ChangeAfterLoad(mUnit)
            table.insert(mRet.data,mUnit)
        end
    end
    interactive.Response(mRecord.source, mRecord.session,mRet)
end

function QueryRoleList(mRecord,mData)
    local sServerid = mData.serverid
    local sAccount = mData.account
    local mGSInfo = serverinfo.GS_INFO
    if sServerid then
        mGSInfo = {[sServerid]=true}
    end
    local mRet = {data={}}
    local res = require "base.res"
    local mChannel = res["daobiao"]['demichannel']
    for sServerKey,_ in pairs(mGSInfo) do
        local mData = global.oSlaveDbMgr:QueryResult(sServerKey,"game","player",{account=sAccount},{pid=true})
        for _,mUnit in pairs(mData) do
            local pid = mUnit.pid
            table.insert(mRet.data,{pid,sServerKey})
        end
    end
    interactive.Response(mRecord.source, mRecord.session,mRet)
end

function SavePlayerIOSGift(mRecord, mData)
    local pid = mData.pid
    local mGift = mData.iosgift
    local mQuery = {pid=pid}
    local mSaveData = {pid=pid,iosgift=mGift}
    if mSaveData then
        mongoop.ChangeBeforeSave(mSaveData)
    end
    local oGameDb = global.oGameDb
    oGameDb:Update(sQQTable, mQuery, mSaveData, {upsert = true})
end

function LoadPlayerIOSGift(mRecord,mData)
    local oGameDb = global.oGameDb
    local mLoadData = oGameDb:Find(sQQTable,{},{pid=true,iosgift=true})
    local mRet = {data={}}
    while mLoadData:hasNext() do
        local mUnit = mLoadData:next()
        if mUnit then
            mongoop.ChangeAfterLoad(mUnit)
            table.insert(mRet.data,mUnit)
        end
    end
    interactive.Response(mRecord.source, mRecord.session,mRet)
end