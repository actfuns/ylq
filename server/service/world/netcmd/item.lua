local global = require "global"
local skynet = require "skynet"
local extend = require "base/extend"

local loaditem = import(service_path("item.loaditem"))
local handleitem = import(service_path("item.handleitem"))
local itemdefines = import(service_path("item.itemdefines"))
local gamedefines = import(lualib_path("public.gamedefines"))

local CONTAINER_TYPE = itemdefines.CONTAINER_TYPE

local max = math.max
local min = math.min

local function GetGlobalData(idx)
    local res = require "base.res"
    local mData = res["daobiao"]["global"][idx]
    local iVal = mData["value"]
    iVal = tonumber(iVal) or 1000000
    return iVal
end

-----------------------------------------------C2GS--------------------------------------------
function C2GSItemUse(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr

    local iItemId = mData["itemid"]
    local target = mData["target"]
    local iAmount = mData["amount"]
    oPlayer.m_oItemCtrl:C2GSItemUse(iItemId,target,iAmount or 1)
end

function C2GSItemInfo(oPlayer,mData)
    local iItemId = mData["itemid"]
    oPlayer.m_oItemCtrl:C2GSItemInfo(iItemId)
end

function C2GSAddItemExtendSize(oPlayer,mData)
end

function C2GSDeComposeItem(oPlayer,mData)
    local sReason = "分解消耗"
    local iItemId = mData["id"]
    local iAmount = mData["iAmount"]
    oPlayer.m_oItemCtrl:C2GSDeComposeItem(iItemId,iAmount)
end

function C2GSComposeItem(oPlayer,mData)
    oPlayer.m_oItemCtrl:Forward("C2GSComposeItem", oPlayer:GetPid(), mData)
end

function C2GSRecycleItem(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr

    local iSaleId = mData["itemid"]
    local iSaleAmount = mData["amount"]
    local iPid = oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    local fCallback = function (mRecord,mData)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            TrueRecycleItem(oPlayer,mData)
        end
    end
    oPlayer.m_oItemCtrl:RecycleItem(iSaleId,iSaleAmount,fCallback)
end

function TrueRecycleItem(oPlayer,mData)
    local bSuc = mData.success
    if not bSuc then
        return
    end
    local iSalePrice = mData.sale_price
    local iSaleAmount = mData.sale_amount
    local sName = mData.sale_name

    local sReason = "道具出售"
    oPlayer:RewardCoin(iSalePrice, sReason, {cancel_tip = 1})
    oPlayer:AddSchedule("sell_item")
    oPlayer:Send("GS2CShowVoice", {type=gamedefines.VOICE_TYPE.SALE_SUCCESS})
    oNotifyMgr:Notify(iPid, string.format("成功出售%s个%s，获得%s个金币", iSaleAmount, sName, iSalePrice))
end

function C2GSRecycleItemList(oPlayer, mData)
    local oNotifyMgr= global.oNotifyMgr

    local iPid = oPlayer:GetPid()
    local lSaleList = table_copy(mData["sale_list"])
    local fCallback = function (mRecord,mData)
        TrueRecycleItemList(iPid,mData)
    end
    oPlayer.m_oItemCtrl:RecycleItemList(lSaleList,fCallback)
end

function TrueRecycleItemList(iPid,mData)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end
    local bSuc = mData.success
    if not bSuc then
        return
    end
    local sReason = "批量出售道具"
    local iSalePrice = mData.sale_price
    oPlayer:RewardCoin(iSalePrice, sReason, {cancel_tip = 1})
    oNotifyMgr:Notify(iPid, "出售成功")
    oPlayer:AddSchedule("sell_item")
    oPlayer:Send("GS2CShowVoice", {type=gamedefines.VOICE_TYPE.SALE_SUCCESS})
end

function C2GSArrangeItem(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local iCD = oPlayer:GetInfo("arrange_item_cd", 0)
    local iNow = get_time()
    if iCD > iNow then
        oNotifyMgr:Notify(iPid, "整理过于频繁，请稍后整理")
        return
    end
    oPlayer.m_oItemCtrl:C2GSArrangeItem()
    oPlayer:SetInfo("arrange_item_cd", iNow + 3)
end

function C2GSPromoteEquipLevel(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPos = mData["pos"]
    local iItemId = mData["itemid"]
    oPlayer.m_oItemCtrl:C2GSPromoteEquipLevel(oPlayer,iPos,iItemId)
end

function C2GSItemPrice(oPlayer,mData)
    local lShape = mData["sid_list"] or {}
    RefreshItemPrice(oPlayer,lShape)
end

function RefreshItemPrice(oPlayer,lShape)
    local mPrice = {}
    for _,iShape in pairs(lShape) do
        local oItem = loaditem.GetItem(iShape)
        local iPrice = oItem:BuyPrice()
        table.insert(mPrice,{sid = iShape,price = iPrice})
    end
    oPlayer:Send("GS2CItemPrice",{
        item_info = mPrice
    })
end

function C2GSResetFuWen(oPlayer,mData)
    oPlayer.m_oItemCtrl:C2GSResetFuWen(oPlayer,mData)
end

function C2GSSaveFuWen(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPos = mData["pos"]
    oPlayer.m_oItemCtrl:C2GSSaveFuWen(iPos)
end

function C2GSUseFuWenPlan(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local oWorldMgr = global.oWorldMgr
    local iOpenGrade = oWorldMgr:QueryControl("fuwenswitch", "open_grade")
    if oPlayer:GetGrade() < iOpenGrade then
        return
    end
    if oWorldMgr:IsClose("fuwenswitch") then
        oNotifyMgr:Notify(oPlayer:GetPid(), "该功能正在维护，已临时关闭。请您留意系统公告。")
        return
    end
    local iCD = oPlayer:GetInfo("use_fuwen_cd",0)
    if iCD - get_time() > 0 then
        oNotifyMgr:Notify(oPlayer:GetPid(), "您操作太频繁了")
        return
    end
    oPlayer.m_oItemCtrl:C2GSUseFuWenPlan()
    oPlayer:SetInfo("use_fuwen_cd", get_time() + 2)
end

function C2GSReNameFuWen(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local lPlanName = mData["fuwen_name"]
    local iCD = oPlayer:GetInfo("rename_fuwen_cd", 0)
    if get_time() < iCD then
        oNotifyMgr:Notify(iPid, "操作太频繁，请稍后")
        return
    end
    oPlayer:SetInfo("rename_fuwen_cd", get_time() + 3)
    local lNewPlanName = table_copy(lPlanName)
    oPlayer.m_oItemCtrl:C2GSReNameFuWen(lNewPlanName)
end

function C2GSEquipStrength(oPlayer,mData)
    oPlayer.m_oItemCtrl:C2GSEquipStrength(oPlayer,mData)
end

function C2GSInlayGem(oPlayer,mData)
    -- local oNotifyMgr = global.oNotifyMgr
    -- local iPos = mData["pos"]
    -- local iGemPos = mData["gem_pos"]
    -- local iItemId = mData["itemid"]
    -- local mCopyData = {
    --     pos = iPos,
    --     gem_pos = iGemPos,
    --     itemid = iItemId
    -- }
    -- oPlayer.m_oItemCtrl:C2GSInlayGem(mCopyData)
    oPlayer.m_oItemCtrl:Forward("C2GSInlayGem", oPlayer:GetPid(), mData)
end

function C2GSInlayAllGem(oPlayer, mData)
    oPlayer.m_oItemCtrl:Forward("C2GSInlayAllGem", oPlayer:GetPid(), mData)
end

function C2GSComposeGem(oPlayer, mData)
    oPlayer.m_oItemCtrl:Forward("C2GSComposeGem", oPlayer:GetPid(), mData)
end

function C2GSAddGemExp(oPlayer,mData)
    -- local iPos = mData["pos"]
    -- local iGemPos = mData["gem_pos"]
    -- local mGemList = mData["gem_list"]
    -- local mData = {
    --     pos = iPos,
    --     gem_pos = iGemPos,
    --     gem_list = mGemList,
    -- }
    -- oPlayer.m_oItemCtrl:C2GSAddGemExp(mData)
end

--一键打造
function C2GSFastStrength(oPlayer,mData)
    oPlayer.m_oItemCtrl:C2GSFastStrength(oPlayer)
end

--一键镶嵌宝石
function C2GSFastAddGemExp(oPlayer,mData)
    -- oPlayer.m_oItemCtrl:C2GSFastAddGemExp()
end

function C2GSCompoundItem(oPlayer,mData)
    local res = require"base.res"
    local bOpen = res["daobiao"]["global_control"]["forge_composite"]["is_open"]
    if bOpen ~= "y" then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意官网相关信息。")
        return
    end
    oPlayer.m_oItemCtrl:C2GSCompoundItem(oPlayer,mData)
end

function C2GSDeCompose(oPlayer,mData)
    local res = require"base.res"
    local bOpen = res["daobiao"]["global_control"]["forge_composite"]["is_open"]
    if bOpen ~= "y" then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(oPlayer.m_iPid,"该功能正在维护，已临时关闭。请您留意官网相关信息。")
        return
    end
    local mInfo = mData.info
    oPlayer.m_oItemCtrl:C2GSDeCompose(oPlayer,mInfo)
end

function C2GSLockEquip(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local iItemId = mData["itemid"]
    local iPos = mData["pos"]
    oPlayer.m_oItemCtrl:C2GSLockEquip(iItemId,iPos)
end

function C2GSChooseItem(oPlayer, mData)
    oPlayer.m_oItemCtrl:C2GSChooseItem(mData)
end

function C2GSBuffStoneOp(oPlayer, mData)
    oPlayer.m_oItemCtrl:Forward("C2GSBuffStoneOp", oPlayer:GetPid(), mData)
end

function C2GSComposeEquip(oPlayer, mData)
    oPlayer.m_oItemCtrl:Forward("C2GSComposeEquip", oPlayer:GetPid(), mData)
end

function C2GSUpgradeEquip(oPlayer, mData)
    oPlayer.m_oItemCtrl:Forward("C2GSUpgradeEquip", oPlayer:GetPid(), mData)
end

function C2GSExChangeEquip(oPlayer, mData)
    oPlayer.m_oItemCtrl:Forward("C2GSExChangeEquip", oPlayer:GetPid(), mData)
end