--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local extend = require "base.extend"

local reportobj = import(service_path("reportobj"))

function SearchReportInfo(mRecord, mData)
    local oReportObj = global.oReportObj
    local br, mRet = safe_call(oReportObj.SearchReportInfo, oReportObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
            data = mRet
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function SearchReporter(mRecord, mData)
    local oReportObj = global.oReportObj
    local br, mRet = safe_call(oReportObj.SearchReporter, oReportObj,mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
            data = mRet
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function SearchChatInfo(mRecord, mData)
    local oReportObj = global.oReportObj
    local br, mRet = safe_call(oReportObj.SearchChatInfo, oReportObj,mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
            data = mRet
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function ChangeContentType(mRecord, mData)
    local oReportObj = global.oReportObj
    local br = safe_call(oReportObj.ChangeContentType, oReportObj,mData.id,mData.type)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function ChangeContentGM(mRecord, mData)
    local oReportObj = global.oReportObj
    local br = safe_call(oReportObj.ChangeContentGM, oReportObj,mData.id,mData.gm)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function DeleteContent(mRecord, mData)
    local oReportObj = global.oReportObj
    local br = safe_call(oReportObj.DeleteContent, oReportObj,mData.id)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function HandlePerson(mRecord, mData)
    local oReportObj = global.oReportObj
    local br = safe_call(oReportObj.HandlePerson, oReportObj,mData.gm,mData.id,mData.serverkey, mData.type,mData.key,mData.value)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end

function MultiHandlePerson(mRecord, mData)
    local oReportObj = global.oReportObj
    local gm = mData.gm
    local id  = mData.id
    local serverkey = mData.serverkey
    local ldata = mData.ldata or {}
    local br = true
    for _,info in pairs(ldata) do
        if br then
            br = safe_call(oReportObj.HandlePerson,oReportObj,gm,id,serverkey,info.type,info.key,info.value,info.args)
        else
            safe_call(oReportObj.HandlePerson,oReportObj,gm,id,serverkey,info.type,info.key,info.value,info.args)
        end
    end
    if br then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 0,
        })
    else
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
        })
    end
end