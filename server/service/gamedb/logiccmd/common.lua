--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"
local dbcmd = import(service_path("dbcmd.init"))

function SaveDb(mRecord, mData)
    local sModule = mData.module
    local sCmd = mData.cmd
    local mCond = mData.cond or {}
    local mSaveData = mData.data
    if mSaveData then
        mongoop.ChangeBeforeSave(mSaveData)
    end
    local mRet = dbcmd.Invoke(sModule,sCmd,mCond,mSaveData)
    if mRet then
        interactive.Response(mRecord.source, mRecord.session,mRet)
    end
end

function LoadDb(mRecord,mData)
    local sModule = mData.module
    local sCmd = mData.cmd
    local mCond = mData.cond or {}
    local mLoadData = mData.data or {}
    local mRet = dbcmd.Invoke(sModule,sCmd,mCond,mLoadData)
    if mRet then
        mongoop.ChangeAfterLoad(mRet)
        interactive.Response(mRecord.source, mRecord.session,mRet)
    end
end

function QuerySlaveDb(mRecord,mData)
    local sServerKey = mData.serverkey
    local sDbName = mData.dbname
    local sTableName = mData.tablename
    local mSearch = mData.search
    local mBack = mData.back
    local mRet = global.oSlaveDbMgr:QueryResult(sServerKey,sDbName,sTableName,mSearch,mBack)
    if mRet then
        mongoop.ChangeAfterLoad(mRet)
        interactive.Response(mRecord.source, mRecord.session,mRet)
    end
end