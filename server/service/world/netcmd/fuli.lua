local  global = require "global"

function C2GSChargeReward(oPlayer,mData)
    global.oFuliMgr:ChargeReward(oPlayer,mData.id)
end

function C2GSSetBackPartner(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("welfare")
    if oHuodong then
        oHuodong:SetBackPartner(oPlayer,mData.sid,mData.star)
    end
end

function C2GSGetBackPartnerInfo(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("welfare")
    if oHuodong then
        oHuodong:GetBackPartnerInfo(oPlayer,mData.sid,mData.star)
    end
end

function C2GSGetRewardBack(oPlayer,mData)
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("rewardback")
    local sid = mData.sid
    local vip = mData.vip
    if sid ~= 0 then
        oHuodong:GetRewardBack(oPlayer,sid,vip)
    else
        oHuodong:ShortcutRewardBack(oPlayer,vip)
    end
end

function C2GSGetFuliPointInfo(oPlayer,mData)
    global.oFuliMgr:GS2CFuliPointUI(oPlayer)
end

function C2GSBuyFuliPointItem(oPlayer,mData)
    global.oFuliMgr:FuliPointBuy(oPlayer,mData.id,mData.amount,mData.version)
end

function C2GSFuliLuckDraw(oPlayer,mData)
    global.oFuliMgr:LuckDrawItem(oPlayer)
end

function C2GSGiveLuckDraw(oPlayer,mData)
    global.oFuliMgr:GiveLuckDraw(oPlayer)
end

function C2GSGetLuckDrawInfo(oPlayer,mData)
    global.oFuliMgr:GS2CLuckDrawUI(oPlayer)
end

function C2GSStartLuckDraw(oPlayer,mData)
    global.oFuliMgr:LuckDrawItem(oPlayer,mData.type)
end

function C2GSReceiveFirstCharge(oPlayer,mData)
    global.oFuliMgr:ReceiveFirstCharge(oPlayer)
end

function C2GSRedeemcode(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("redeemcode")
    if oHuodong then
        oHuodong:UseRedeemCode(oPlayer,mData.code)
    end
end

function C2GSOpenChargeBackUI(oPlayer,mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("welfare")
    if oHuodong then
        oHuodong:C2GSOpenChargeBackUI(oPlayer)
    end
end