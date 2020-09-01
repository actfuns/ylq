--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"

ForwardKSCmd = {}
ForwardGSCmd = {}
--------------GS2KS---------------
function ForwardKSCmd.ApplyEnterGame(mRecord, mArgs)
    global.oKFMgr:ApplyEnterGame(mArgs.serverkey,mArgs.pid,mArgs.name,mArgs.warinfo)
end

function ForwardKSCmd.ReEnterWar(mRecord,mArgs)
    local iPid = mArgs.pid
    local oPlayer = global.oKFMgr:GetObject(iPid)
    local oWarMgr = global.oWarMgr
    if oPlayer then
        oWarMgr:ReEnterWar(oPlayer)
    end
end

function ForwardKSCmd.NotifyDisconnected(mRecord,mArgs)
    local iPid = mArgs.pid
    local oWarMgr = global.oWarMgr
    local oPlayer = global.oKFMgr:GetObject(iPid)
    oWarMgr:OnDisconnected(oPlayer)
end


function ForwardKSCmd.JoinKFGames(mRecord,mArgs)
     local mRe = global.oKFMgr:JoinGame(mRecord,mArgs)
     router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRe)
end

function ForwardKSCmd.QuitKFGames(mRecord,mArgs)
    global.oKFMgr:DeleteGameObject(mArgs)
end

function ForwardKSCmd.HuodongTestOP(mRecord,mData)
    local name = mData["name"]
    local oHuoDong = global.oHuodongMgr:GetHuodong(name)
    local mRe

    if oHuoDong then
        mRe = safe_call(oHuoDong.TestKFOP,oHuoDong,mData["flag"],mData["mData"])
    end
    if not mRe then
        mRe = {err=1}
    end
     router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRe)
end

function ForwardKSCmd.GS2CKuaFuCmd(mRecord,mData)
     local mRe = global.oKFMgr:KuafuCmd(mData)
     if mRe then
         router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRe)
     end
end

function ForwardKSCmd.OnLogin(mRecord,mData)
    global.oKFMgr:OnLogin(mData)
end


function ForwardKSCmd.OnDisconnected(mRecord,mData)
    global.oKFMgr:OnDisconnected(mData)
end


function GS2KSForward(mRecord, mData)
    local sFuncName = mData.func
    if ForwardKSCmd[sFuncName] then
        ForwardKSCmd[sFuncName](mRecord,mData.args)
    end
end



--------------KS2GS---------------
function ForwardGSCmd.EnsureEnterWar(mRecord,mArgs)
    global.oKFMgr:EnsureEnterWar(mArgs.pid,mArgs.name,mArgs.remotewarid,mArgs.remoteaddr)
end

function ForwardGSCmd.RemoteEvent(mRecord,mArgs)
    local sEventName = mArgs.event
    local m = mArgs.data
    local iPid = mArgs.pid
    local oProxyWarMgr = global.oProxyWarMgr
    oProxyWarMgr:RemoteEvent(sEventName, m, iPid)
end

function ForwardGSCmd.KS2GSHuoDong(mRecord,mData)
    if not global.oHuodongMgr then
        return
    end
    local sCmd = mData["func"]
    local sName = mData["name"]
    local data = mData["data"]
    local oHuoDong = global.oHuodongMgr:GetHuodong(sName)
    if oHuoDong and oHuoDong.OnKFCmd then
        local mRe = oHuoDong:OnKFCmd(sCmd,data)
        if mRe then
            router.Response(mRecord.srcsk, mRecord.src, mRecord.session, mRe)
        end
    end
end

function ForwardGSCmd.KS2GSProxyEvent(mRecord,mData)
    global.oKFMgr:ProxyEvent(mData["pid"],mData["cmd"],mData["data"])
end

function KS2GSForward(mRecord, mData)
    local sFuncName = mData.func
    if ForwardGSCmd[sFuncName] then
        ForwardGSCmd[sFuncName](mRecord,mData.args)
    end
end



