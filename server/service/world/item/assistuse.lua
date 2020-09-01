--imoprt module
--辅助模块道具回调使用
local global = require "global"

local itembase = import(lualib_path("public.itembase"))
local itemdefines = import(service_path("item.itemdefines"))
local loaditem = import(service_path("item.loaditem"))

function GiveItem(oPlayer,mData)
    local lItemList = mData.data
    local sReason = mData.reason
    local mArgs = mData.args or {}
    mArgs.cancel_show = 1
    local iPid = oPlayer:GetPid()
    -- local mKeepList = mData.show_keep or {}
    -- for _,mShow in ipairs(mKeepList) do
    --     global.oUIMgr:AddKeepItem(iPid,mShow)
    -- end
    local oWorldMgr = global.oWorldMgr
    oPlayer:AssistGiveItem(lItemList,sReason,mArgs)
    -- global.oUIMgr:ShowKeepItem(iPid)
end

function SendHongBao(oPlayer,mData)
    local iPid = oPlayer:GetPid()
    local mArgs = mData.data
    local iShape = mArgs.sid
    local mData = {sContent={"公会频道","世界频道"}}
    local func = function (oPlayer,mData)
        SendHongbao2(oPlayer,iShape,mData)
    end
    local oCbMgr = global.oCbMgr
    oCbMgr:SetCallBack(iPid, "GS2CHongBaoUI", mData, nil, func)
end

function SendHongbao2(oPlayer,iShape,mData)
    local iAnswer = mData["answer"]
    if not table_in_list({1,2},iAnswer) then
        return
    end
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    local oItem = loaditem.GetItem(iShape)
    local mData = oItem:GetHongBaoInfo()
    local iOrgID = oPlayer:GetOrgID()
    if not oItem or oItem:GetAmount() <= 0 then return end
    if iAnswer== 1 and iOrgID == 0 then
        oPlayer:NotifyMessage("请先加入公会")
        return
    end
    local mArgs = {}
    local fCallback = function (mRecord,mData2)
        local bSuc = mData2.success
        if not bSuc then
            return
        end
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not oPlayer then
            return
        end
        if iAnswer == 1 then
            global.oHbMgr:SendHongBao(oPlayer,"orgchannel",mData["gold"],mData["cnt"],iShape)
        elseif iAnswer == 2 then
            global.oHbMgr:SendHongBao(oPlayer,"worldchannel",mData["gold"],mData["cnt"],iShape)
        end
        oPlayer:NotifyMessage("成功发放红包")
    end
    local sReason = "道具红包红包"
    if iAnswer == 1 then
        sReason = "公会频道红包"
    elseif iAnswer == 2 then
        sReason = "世界频道红包"
    end
    oPlayer.m_oItemCtrl:RemoveItemAmount(iShape,1,sReason,mArgs,fCallback)
end

function PartnerTravel(oPlayer,mData)
    local mArgs = mData.args or {}
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    local mSpeed = mArgs.speed_info or {}
    oHuodong:UseSpeedItem(oPlayer,mSpeed)
end

function UseTest(oPlayer,mData)
    local sReason = "压测道具"
    local iRandom = math.random(100)
    if iRandom < 10 then
        local iExp = 10000 + math.random(5000)
        oPlayer:RewardExp(iExp,sReason)
    elseif iRandom < 20 then
        local iGold = 10000 + math.random(5000)
        oPlayer:RewardCoin(iGold,sReason)
    elseif iRandom < 30 then
        local iOffer = 10 + math.random(10)
        oPlayer:RewardOrgOffer(iOffer,sReason)
    elseif iRandom < 40 then
        local iMedal = 10 + math.random(10)
        oPlayer:RewardMedal(iMedal,sReason)
    elseif iRandom < 50 then
        local iActive = 20 + math.random(30)
        oPlayer:RewardActive(iActive,sReason)
    elseif iRandom < 60 then
        local iPoint = 20 + math.random(20)
        oPlayer:RewardTrapminePoint(iPoint,sReason)
    else
        local iVal = 30 + math.random(30)
        oPlayer:RewardArenaMedal(iVal,sReason)
    end
end