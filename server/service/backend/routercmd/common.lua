--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"
local extend = require "base.extend"

function GetClientServerList(mRecord, mData)
    local oBackendInfoMgr = global.oBackendInfoMgr
    local br, m = safe_call(oBackendInfoMgr.GetClientServerList, oBackendInfoMgr, mData)
    local mRet = {}
    if br then
        mRet = {errcode=0, data=m}
    else
        mRet = {errcode=1}
    end
    router.Response(mRecord.srcsk,mRecord.src,mRecord.session,mRet)
end

function SaveBackendLog(mRecord, mData)
    local oBackendObj = global.oBackendObj
    local oBackendDb = oBackendObj.m_oBackendDb

    mData = extend.Table.deserialize(mData)
    local iPid = mData["pid"]
    local sType = mData["type"]
    local tBackend = oBackendDb:GetDB()
    local mQuery = {["pid"] = iPid, ["type"] = sType}
    local mDocument = {["pid"] = iPid, ["type"] = sType, ["data"] = mData["data"]}
    local mCondition = {upsert = true}
    oBackendDb:Update(mData.tablename, mQuery, mDocument, mCondition)
end

function AddReportList(mRecord,mData)
    mData = extend.Table.deserialize(mData)
    local oReportObj = global.oReportObj
    oReportObj:AddNewReport(mData)
end