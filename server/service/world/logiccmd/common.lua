--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function AddTeachTaskProgress(mRecord,mData)
    local iPid = mData.pid
    local iTask = mData.task
    local iProgress = mData.progress
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oTaskCtrl:AddTeachTaskProgress(iTask,iProgress)
    end
end

function TriggerPartnerTask(mRecord,mData)
    local iPid = mData.pid
    local iParId = mData.parid
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer.m_oTaskCtrl:TriggerPartnerTask(iParId)
    end
end

function AddSchedule(mRecord, mData)
    local iPid = mData.pid
    local sCmd = mData.cmd
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:AddSchedule(sCmd)
    end
end

function AssistSyncData(mRecord,mData)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:AssistSyncData(mData)
end

function FrozenMoney(mRecord, mData)
    local oWorldMgr = global.oWorldMgr
    local iPid = mData.pid
    local iCostCoin = mData.coin
    local iCostGoldCoin = mData.goldcoin
    local sReason = mData.reason
    local mArgs = mData.args
    local bSucc = true
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mFrozen = {}
    if oPlayer then
        if iCostCoin and not oPlayer:ValidCoin(iCostCoin, mArgs) then
            bSucc = false
        end
        if iCostGoldCoin and not oPlayer:ValidGoldCoin(iCostGoldCoin, mArgs) then
            bSucc = false
        end
    else
        bSucc = false
    end
    if bSucc then
        if iCostCoin then
            local iSession = oPlayer:FrozenMoney("coin", iCostCoin, sReason)
            mFrozen.coin  = {iSession, iCostCoin}
        end
        if iCostGoldCoin then
            local iSession = oPlayer:FrozenMoney("goldcoin", iCostGoldCoin, sReason)
            mFrozen.goldcoin = {iSession, iCostGoldCoin}
        end
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSucc,
        pid = iPid,
        frozen = mFrozen,
        reason = sReason,
        args = mArgs,
    })
end

function UnFrozenMoney(mRecord, mData)
    local oWorldMgr = global.oWorldMgr
    local iPid = mData.pid
    local mFrozen = mData.frozen or {}
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oProfile = oPlayer:GetProfile()
    if mFrozen.coin then
        local iSession, iVal = table.unpack(mFrozen.coin)
        oProfile:UnFrozenMoney(iSession)
    end
    if mFrozen.goldcoin then
        local iSession, iVal = table.unpack(mFrozen.coin)
        oProfile:UnFrozenMoney(iSession)
    end
end

function ResumeMoney(mRecord, mData)
    local oWorldMgr = global.oWorldMgr
    local iPid = mData.pid
    local sReason = mData.reason
    local mArgs = mData.args
    local mFrozen = mData.frozen or {}
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oProfile = oPlayer:GetProfile()
    if mFrozen.coin then
        local iSession, iVal = table.unpack(mFrozen.coin)
        oProfile:UnFrozenMoney(iSession)
        if oPlayer:ValidCoin(iVal, mArgs) then
            oPlayer:ResumeCoin(iVal, sReason, mArgs)
        end
    end
    if mFrozen.goldcoin then
        local iSession, iVal = table.unpack(mFrozen.goldcoin)
        oProfile:UnFrozenMoney(iSession)
        if oPlayer:ValidGoldCoin(iVal, mArgs) then
            oPlayer:ResumeGoldCoin(iVal, sReason, mArgs)
        end
    end
end

function PushCondition(mRecord, mData)
    local iPid = mData.pid
    local lCondition = mData.condition or {}
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        for _, m in ipairs(lCondition) do
            oPlayer:PushBookCondition(m.key, {value = m.value})
        end
    end
end

function RewardCoin(mRecord,mData)
    local iPid = mData.pid
    local iVal = mData.val
    local sReason = mData.reason
    local mArgs = mData.args
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:RewardCoin(iVal,sReason,mArgs)
    end
end

function SynShareObj(mRecord, mData)
    local iPid = mData.pid
    local mArgs = mData.args or {}
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        if mArgs.stone_share then
            oPlayer:UpdateStoneShare()
        end
        if mArgs.equip then
            oPlayer:UpdateEquipShare()
        end
        if next(mArgs) then
            oPlayer:ActivePropChange()
        end
    end
end

function UpdateHandBookKey(mRecord, mData)
    local oHandBookMgr = global.oHandBookMgr
    oHandBookMgr:UpdateKey()
end