--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local netproto = require "base.netproto"
local record = require "public.record"

function C2GSHeartBeat(oPlayer, mData)
    oPlayer:ClientHeartBeat()
end

function C2GSGMCmd(oPlayer, mData)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if is_production_env() and oPlayer:IsGM() then
        oNotifyMgr:Notify(oPlayer:GetPid(),"你不是gm,无法执行gm指令")
        return
    end
    local oGMMgr = global.oGMMgr
    oGMMgr:ReceiveCmd(oPlayer, mData.cmd)
end

function C2GSCallback(oPlayer,mData)
    local iSessionIdx = mData["sessionidx"]
    local oCbMgr = global.oCbMgr
    local m = netproto.ProtobufFunc("default", "C2GSCallback", mData)
    local iNewSessionIdx = tonumber(iSessionIdx)

    if iNewSessionIdx and iNewSessionIdx ~= 0 then
        oCbMgr:SendCallBack(oPlayer,iNewSessionIdx,m)
    end
end

function C2GSNotActive(oPlayer, mData)
    local bActive = oPlayer:GetInfo("active", true)
    if bActive then
        local oTeam = oPlayer:HasTeam()
        if oTeam then
            --oTeam:NotActive(oPlayer:GetPid())
        end
        --oPlayer:SetInfo("active", false)
    end
end

function C2GSBarrage(oPlayer,mData)
    local sType = mData["type"]
    local sContent = mData["content"]
    local iPid = oPlayer.m_iPid
    if sType == "partner" then
        if not oPlayer.m_NotifyBarrage then
            return
        end
        oPlayer.m_NotifyBarrage=nil
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("upcard")
        if oHuodong then
            oHuodong:BarrageSend(oPlayer,mData)
        end
    end
end

function C2GSBigPacket(oPlayer, mData)
    local iClientType = mData.type
    local sData = mData.data
    local iTotal = mData.total
    local iIndex = mData.index
    local iFd = oPlayer:GetNetHandle()
    if iFd then
        oPlayer.m_oBigPacketMgr:HandleBigPacket(iClientType, sData, iTotal, iIndex, iFd)
    end
end

function C2GSQueryClientUpdateRes(oPlayer, mData)
    interactive.Send(".clientupdate", "common", "QueryResUpdate", {
        pid = oPlayer:GetPid(),
        data = mData,
    })
end

function C2GSForceLeaveWar(oPlayer,mData)
    local oWar = oPlayer:GetWar()
    if not oWar then
        return
    end
    local oWarMgr = global.oWarMgr
    oWarMgr:LeaveWar(oPlayer,true)
end

function C2GSClientSession(oPlayer,mData)
    local iSessionIdx = mData["session"]
    local mNet = {
        session = iSessionIdx
    }
    oPlayer:Send("GS2CSessionResponse",mNet)
end

--备用协议
function C2GSDoBackup(oPlayer,mData)
    --print(mData)
end

function C2GSRequestPay(oPlayer, mData)
    local sProductKey = mData.product_key
    local iAmount = mData.product_amount
    local mPayArgs = mData.pay_args or {}
    local sPayKey = mPayArgs.request_key
    local sPayValue = mPayArgs.request_value
    local mArgs = {}
    if table_in_list({"goods_key","grade_key", "one_RMB_gift"},sPayKey) then
        mArgs[sPayKey] = tonumber(sPayValue)
    end
    global.oPayMgr:TryPay(oPlayer, sProductKey, iAmount, "demi",mArgs)
end

--[[
function C2GSGradeRequestPay(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("gradegift")
    if oHuodong then
        if oHuodong:ValidBuyGift(oPlayer, mData.grade_key, mData.product_key) then
            local sProductKey = mData.product_key
            local iAmount = mData.product_amount
            local mArgs = {
                grade_key = mData.grade_key,
            }
            global.oPayMgr:TryPay(oPlayer, sProductKey, iAmount, "demi",mArgs)
        end
    else
        global.oNotifyMgr:Notify(oPlayer:GetPid(), "活动不存在")
    end
end
]]

function C2GSGMRequire(oPlayer,mData)
    local iTargetPid = mData["target_id"]
    local sInfo = mData["info"]
    global.oPubMgr:GMRequire(oPlayer,iTargetPid,sInfo)
end

function C2GSAnswerGM(oPlayer,mData)
    local iTargetPid = mData["gm_id"]
    local sInfo = mData["info"]
    global.oPubMgr:AnswerGM(oPlayer,iTargetPid,sInfo)
end

function C2GSQueryBack(oPlayer,mData)
    oPlayer:Send("GS2CAnswerBack",{})
end

function C2GSSendXGToken(oPlayer,mData)
    oPlayer:SendXGToken(mData)
end
