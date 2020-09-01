--import module
local global = require "global"
local skynet = require "skynet"
local cjson = require "cjson"
local interactive = require "base.interactive"
local record = require "public.record"
local httpuse = require "public.httpuse"
local router = require "base.router"

function HttpGameServer(mRecord, mData)
    local oBackendObj = global.oBackendObj
    local sServer = mData["servers"]

    local lServer = {}
    if mData["allserver"] then
        lServer = oBackendObj:GetAllServers()
    else
        local lServerId = split_string(sServer, ",")
        for _,s in pairs(lServerId) do
            local oServer = oBackendObj:GetServerObj(s)
            if oServer then
                table.insert(lServer, oServer)
            end
        end
    end

    if #lServer <= 0 then
        interactive.Response(mRecord.source, mRecord.session, {
            errcode = 1,
            errmsg = "not find server",
        })
        return
    end

    local iCnt = #lServer
    for _, oServer in pairs(lServer) do
        local sServerTag = oServer:GetServerTag()
        router.Request(sServerTag,".world","backend","gmbackend",mData,function (m1,mRes)
            iCnt = iCnt - 1
            if mRes.errcode then
                record.error("host:%s, errCode:%s, errMsg:%s", sHost, mRes.errcode, mRes.errmsg)
            end
            if iCnt <= 0 then
                -- TODO liuzla 汇总所有服务器
                interactive.Response(mRecord.source, mRecord.session, mRes)
            end
        end)
    end
end

function SearchPlayer(mRecord, mData)
    local oBackendObj = global.oBackendObj
    local iType = mData["type"]
    local lCondition = mData["data"]
    -- local mData["servers"]
    local lServers = oBackendObj:GetAllServers()

    local mSearch = {}
    if iType == 1 then
        mSearch = {name = {['$in'] = lCondition}}
    else
        mSearch = {pid = {['$in'] = lCondition}}
    end

    local oGmToolsObj = global.oGmToolsObj
    local br, mRet = safe_call(oGmToolsObj.SearchPlayer, oGmToolsObj, lServers, mSearch)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {errcode=0, data=mRet})
    else
        interactive.Response(mRecord.source, mRecord.session, {errcode=1, data={}})
    end
end

function SearchPlayerSummon(mRecord, mData)
    local oBackendObj = global.oBackendObj

    local iPid = mData["pid"]
    local sName = mData["pname"]
    -- local mData["servers"]
    local lServers = oBackendObj:GetAllServers()

    local mSearch = {}
    if iType == 1 then
        mSearch = {name = sName}
    else
        mSearch = {pid = iPid}
    end

    local oGmToolsObj = global.oGmToolsObj
    local br, mRet = safe_call(oGmToolsObj.SearchPlayerSummon, oGmToolsObj, lServers, mSearch)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {errcode=0, data=mRet})
    else
        interactive.Response(mRecord.source, mRecord.session, {errcode=1, "server error"})
    end
end

function SearchOrg(mRecord, mData)
    local iOrg = mData["orgid"]
    local sName = mData["orgname"]
    local sServer = mData["serverid"]

    local oBackendObj = global.oBackendObj
    local oServer = oBackendObj:GetServer(sServer)
    if not oServer then
       interactive.Response(mRecord.source, mRecord.session, {errcode=1, "server not find"})
       return
    end

    local mSearch = {}
    if iOrg then
        mSearch = {orgid = iOrg}
    else
        mSearch = {name = sName}
    end

    local oGmToolsObj = global.oGmToolsObj
    local br, mRet = safe_call(oGmToolsObj.SearchOrg, oGmToolsObj, oServer, mSearch)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {errcode=0, data=mRet})
    else
        interactive.Response(mRecord.source, mRecord.session, {errcode=2, data={}})
    end
end

function SearchPlayerList(mRecord, mData)
    local oGmToolsObj = global.oGmToolsObj
    local br, mRet = safe_call(oGmToolsObj.SearchPlayerList, oGmToolsObj, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, {errcode=0, data=mRet})
    else
        interactive.Response(mRecord.source, mRecord.session, {errcode=2, data={}})
    end
end

function SaveOrUpdateNotice(mRecord, mData)
    router.Send("cs", ".serversetter", "common", "SaveOrUpdateNotice", mData)
    interactive.Response(mRecord.source, mRecord.session, {})
end

function GetNoticeList(mRecord, mData)
    router.Request("cs", ".serversetter", "common", "GetNoticeList", mData, function (r, d)
        interactive.Response(mRecord.source, mRecord.session, d)
    end)
end

function DeleteNotice(mRecord, mData)
    router.Send("cs", ".serversetter", "common", "DeleteNotice", mData)
    interactive.Response(mRecord.source, mRecord.session, {})
end

function PublishNotice(mRecord, mData)
    router.Send("cs", ".serversetter", "common", "PublishNotice", mData)
    interactive.Response(mRecord.source, mRecord.session, {})
end

function GetClientNotice(mRecord, mData)
    local platforms = mData["platforms"]
    local oNoticeMgr = global.oNoticeMgr
    local br, mRet = safe_call(oNoticeMgr.GetClientNotice, oNoticeMgr, mData)
    if br then
        interactive.Response(mRecord.source, mRecord.session, mRet)
    else
        interactive.Response(mRecord.source, mRecord.session, {error="server error", infoList={}})
    end
end

function GetLoopNoticeList(mRecord, mData)
    local oNoticeMgr = global.oNoticeMgr
    local lRet = oNoticeMgr:GetLoopNoticeList()
    interactive.Response(mRecord.source, mRecord.session, {errcode=0, data=lRet})
end

function SaveOrUpdateLoopNotice(mRecord, mData)
    local oNoticeMgr = global.oNoticeMgr
    oNoticeMgr:SaveOrUpdateLoopNotice(mData)
    interactive.Response(mRecord.source, mRecord.session, {})
end

function DeleteLoopNotice(mRecord, mData)
    local oNoticeMgr = global.oNoticeMgr
    local lId = mData["ids"]
    oNoticeMgr:DeleteLoopNotice({id = {['$in'] = lId}}, lId)
    interactive.Response(mRecord.source, mRecord.session, {})
end

function PublishLoopNotice(mRecord, mData)
    local oNoticeMgr = global.oNoticeMgr
    local lId = mData["ids"]
    oNoticeMgr:PublishLoopNotice({id = {['$in'] = lId}})
    interactive.Response(mRecord.source, mRecord.session, {})
end

function RedeemCode(mRecord, mData)
    print("gmtools:RedeemCode",mData)
    router.Request("cs", ".redeemcode", "common", "Forward", mData, function (m1, m2)
        interactive.Response(mRecord.source, mRecord.session, m2)
    end)
end

