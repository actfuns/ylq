

--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"

local backend = import(service_path("gm/gm_backend"))

ForwardCmd = {}

local function InsertName(iPid, sName)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oBackendMgr = global.oBackendMgr
    if oPlayer then
        oBackendMgr:RenamePlayer(oPlayer, sName)
    else
        oBackendMgr:OnlineExecute(iPid, "RenamePlayer", {sName})
    end
end

function ForwardCmd.RenamePlayer(mRecord, mArgs)
    local iPid = mArgs["pid"]
    local sName = mArgs["name"]
    local iGold = mArgs["gold"] or 0

    -- 判断名字是否可以用
    local oRenameMgr = global.oRenameMgr
    local mCond = {name = sName}

    local insertName = function (m, data)
        InsertName(iPid, sName)
        if iGold > 0 then
            local oMailMgr = global.oMailMgr
            local mMail, sMail = oMailMgr:GetMailInfo(64)
            oMailMgr:SendMail(0, sMail, iPid, mMail,{{sid = gamedefines.COIN_FLAG.COIN_GOLD, value = iGold}})
        end
        router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRes)
    end

    local findName = function (m, data)
        if data.success then
            router.Response(mRecord.srcsk, mRecord.src, mRecord.session, {errcode=3, errmsg="名字重复"})
            return
        else
            oRenameMgr:Request(mCond, "InsertNewNameCounter", insertName)
        end
    end
    oRenameMgr:Request(mCond, "FindName", findName)
end

function ForwardCmd.SearchPartnerInfo(mRecord,mArgs)
    local mCallBack = function (m, mData)
        router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mData.data)
    end
    local oBackendMgr = global.oBackendMgr
    local mData = {}
    mData["pid"] = mArgs["pid"]
    mData["sid"] = mArgs["sid"]
    if not mData["pid"] then return end
    oBackendMgr:SearchPartner("BKSearchPartner",mData,mCallBack)
end

function gmbackend(mRecord, mData)
    local sCmd = mData["cmd"]
    local mArgs = mData["data"]

    if ForwardCmd[sCmd] then
        ForwardCmd[sCmd](mRecord,mArgs)
        return
    end
    local func = backend.Commands[sCmd]

    local mRes = {}
    if func then
        local bSucc, mRet = safe_call(func, mRecord, mArgs)
        if not bSucc then
            mRes = {
                errcode = 2,
                errmsg = "world service call error",
            }
        else
            if not mRet or not mRet["off"] then
                mRes = mRet or {}
            end
        end
    else
        mRes = {
            errcode = 1,
            errmsg = "world service func not find",
        }
    end
    router.Response(mRecord.srcsk,mRecord.src,mRecord.session,mRes)
end

function RewardYYBaoGift(mRecord,mArgs)
    local oBackendMgr = global.oBackendMgr
    local iPid = mArgs.pid
    local iGid = mArgs.gid
    oBackendMgr:RewardYYBaoGift(iPid,iGid)
end

function RewardIOSGift(mRecord,mArgs)
    local oBackendMgr = global.oBackendMgr
    local iPid = mArgs.pid
    local iGid = mArgs.gid
    oBackendMgr:RewardIOSGift(iPid,iGid)
end

function RenamePlayer(mRecord,mArgs)
    ForwardCmd["RenamePlayer"](mRecord,mArgs)
end

function SetHuodongOpen(mRecord, mData)
    local oBackendMgr = global.oBackendMgr
    local br, mRet = safe_call(oBackendMgr.SetHuodongOpen, oBackendMgr, mData)
    if not br then
        mRet = {errmsg = "world service call error"}
    end
    router.Response(mRecord.srcsk,mRecord.src,mRecord.session,mRet)
end

function QueryOpenHuodong(mRecord, mData)
    local oBackendMgr = global.oBackendMgr
    local br, mRet = safe_call(oBackendMgr.QueryOpenHuodong, oBackendMgr, mData)
    if not br then
        mRet = {errmsg = "world service call error"}
    end
    router.Response(mRecord.srcsk,mRecord.src,mRecord.session,{data = mRet})
end