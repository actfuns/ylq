local global = require "global"
local interactive = require "base.interactive"

function C2GSGetRankInfo(oPlayer, mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:C2GSGetRankInfo(oPlayer, mData)
end

function C2GSGetRankTop3(oPlayer, mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:Forward(oPlayer, "C2GSGetRankTop3", mData)
end

function C2GSMyRank(oPlayer, mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:C2GSMyRank(oPlayer, mData)
end

function C2GSMyOrgRank(oPlayer,mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:Forward(oPlayer,"C2GSMyOrgRank",mData)
end

function C2GSGetOrgRankInfo(oPlayer,mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:Forward(oPlayer,"C2GSGetOrgRankInfo",mData)
end

function C2GSGetRankParInfo(oPlayer, mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:Forward(oPlayer,"C2GSGetRankParInfo",mData)
end

function C2GSGetRankMsattack(oPlayer, mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:Forward(oPlayer,"C2GSGetRankMsattack",mData)
end

function C2GSGetRankFirstInfo(oPlayer, mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:Forward(oPlayer, "C2GSGetRankFirstInfo", mData)
end

function C2GSRankUpvoteInfo(oPlayer, mData)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    if oWorldMgr:IsClose("rank") then
        oNotifyMgr:Notify(oPlayer:GetPid(), "该功能正在维护，已临时关闭，请您留意官网相关信息。")
        return
    end
    local oRankMgr = global.oRankMgr
    oRankMgr:C2GSRankUpvoteInfo(oPlayer, mData)
end

function C2GSOpenRankUI(oPlayer, mData)
    local oWorldMgr = global.oWorldMgr
    local oRankMgr = global.oRankMgr
    if oWorldMgr:IsClose("rank") then
        oNotifyMgr:Notify(oPlayer:GetPid(), "该功能正在维护，已临时关闭，请您留意官网相关信息。")
        return
    end
    oRankMgr:OpenRankUI(oPlayer, mData)
end

function C2GSPartnerRank(oPlayer, mData)
    local oRankMgr = global.oRankMgr
    oRankMgr:Forward(oPlayer, "C2GSPartnerRank", mData)
end