-- import module
local global = require "global"
local skyner = require "skynet"
local record = require "public.record"
local interactive = require "base.interactive"
local colorstring = require "public.colorstring"
local router = require "base.router"

local gamedefines = import(lualib_path("public.gamedefines"))
local itemdefines = import(service_path("item/itemdefines"))
local loaditem = import(service_path("item.loaditem"))
local loadpartner = import(service_path("partner.loadpartner"))
local CONTAINER_TYPE = gamedefines.ITEM_CONTAINER

ForwardNetcmds = {}

function ForwardNetcmds.C2GSPartnerFight(oPlayer, mData)
    local mPos = mData.fight_info
    local iPos = mPos.pos
    local iParId = mPos.parid
    oPlayer.m_oPartnerCtrl:SetFightInfo(iPos, iParId)
end

function ForwardNetcmds.C2GSPartnerSwitch(oPlayer, mData)
    local lFightInfo = mData.fight_info
    lFightInfo[1].parid = lFightInfo[1].parid or 0
    lFightInfo[2].parid =lFightInfo[2].parid or 0
    if not oPlayer.m_oPartnerCtrl:ValidSwitchPartner(lFightInfo) then
        return
    end
    oPlayer.m_oPartnerCtrl:SwitchFightPartner(lFightInfo[1], lFightInfo[2])
end

function ForwardNetcmds.C2GSUpgradePartnerStar(oPlayer, mData)
    local iParId = mData.partnerid
    local lCostList = mData.cost_list
    oPlayer.m_oPartnerCtrl:IncreasePartnerStar(iParId, lCostList)
end

function ForwardNetcmds.C2GSSetPartnerLock(oPlayer, mData)
    local iParId = mData.partnerid
    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
    if oPartner then
        oPartner:SetLock()
    end
end

function ForwardNetcmds.C2GSRenamePartner(oPlayer, mData)
    -- local utf8 = require "lutf8lib"
    local iParId = mData.partnerid
    local sName = mData.name
    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
    if oPartner then
        -- if utf8:len(sName) <= 6 then
            oPartner:SetName(sName)
        -- end
    end
end

function ForwardNetcmds.C2GSPartnerPictureSwitchPos(oPlayer, mData)
    local lPosInfo = mData["picture_pos"] or {}
    if not oPlayer.m_oPartnerCtrl:ValidSwitchPartnerPicture(lPosInfo) then
        return
    end
    oPlayer.m_oPartnerCtrl:SwitchPartnerPicture(lPosInfo)
end

function ForwardNetcmds.C2GSComposePartner(oPlayer, mData)
    local iChipSid = mData.partner_chip_type
    local iAmount = mData.compose_amount
    oPlayer.m_oPartnerCtrl:ComposePartner(iChipSid, iAmount)
end

function ForwardNetcmds.C2GSAwakePartner(oPlayer, mData)
    local iParId = mData.partnerid
    oPlayer.m_oPartnerCtrl:AwakePartner(iParId)
end

function ForwardNetcmds.C2GSComposeAwakeItem(oPlayer, mData)
    local iAwakeSid = mData.sid
    local iCompose = mData.compose_amount
    oPlayer:ComposeAwakeItem(iAwakeSid, iCompose)
end

function ForwardNetcmds.C2GSUsePartnerItem(oPlayer, mData)
    local iItemId = mData.itemid
    local iTarget = mData.target
    local iAmount = mData.amount
    oPlayer.m_oItemCtrl:ItemUse(iItemId,iTarget,iAmount)
end

function ForwardNetcmds.C2GSPartnerEquipPlanSave(oPlayer, mData)
    local iParId = mData.partnerid
    local iPlanId = mData.plan_id
    local lEquip = mData.equip_list or {}
    if #lEquip < 0 or #lEquip > 6 then
        record.error(string.format("C2GSPartnerEquipPlanSave error,%s", oPlayer:GetPid()))
        return
    end
    -- oPlayer.m_oPartnerCtrl:SaveEquipPlan(iParId, iPlanId, lEquip)
end

function ForwardNetcmds.C2GSPartnerEquipPlanUse(oPlayer, mData)
    local iParId = mData.partnerid
    local iPlanId = mData.plan_id or 0
    local lEquip = mData.equip_list or {}
    if #lEquip < 0 or #lEquip > 6 then
        record.error(string.format("C2GSPartnerEquipPlanUse error,%s", oPlayer:GetPid()))
        return
    end
    -- oPlayer.m_oPartnerCtrl:UsePartnerEquipPlan(iParId, iPlanId, lEquip)
end

function ForwardNetcmds.C2GSComposePartnerEquip(oPlayer, mData)
    local lCostList = mData.cost_list or {}
    if oPlayer.m_oItemCtrl:ValidComposePartnerEquip(lCostList) then
        oPlayer.m_oItemCtrl:ComposePartnerEquip(lCostList[1], lCostList[2])
    end
end

function ForwardNetcmds.C2GSLockPartnerItem(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iItemId = mData["itemid"]
    local iPid = oPlayer:GetPid()
    local oItem = oPlayer:HasItem(iItemId)
    if not oItem then
        return
    end
    if table_in_list({"parsoul", "parequip", "parstone"}, oItem:ItemType()) then
        oItem:SetLock()
        local sMsg
        local iLock = oItem:GetLock()
        if iLock == 0 then
            sMsg = "已解锁"
        else
            sMsg = "已加锁"
        end
        oItem:RefreshLock()
        oAssistMgr:Notify(iPid, sMsg)
    else
        oAssistMgr:Notify(iPid, "道具不可加锁")
    end
end

function ForwardNetcmds.C2GSDrawCard(oPlayer, mData)
    local iType = mData.type
    local sReason = mData.reason
    local lPartners = mData.partners or {}
    local mArgs = mData.args or {}
    mArgs.cancel_tip = 1
    mArgs.cancel_show = 1
    local lPartnerId = oPlayer.m_oPartnerCtrl:GivePartner(lPartners, sReason, mArgs)

    oPlayer:Send("GS2CDrawCardResult",{
        type = iType,
        partner_list = lPartnerId,
    })
end

function ForwardNetcmds.C2GSSetShowPartner(oPlayer,mData)
    local parlist = mData.parlist or {}
    oPlayer.m_oPartnerCtrl:SetShowPartner(parlist)
    oPlayer.m_oPartnerCtrl:RefreshShowPartner(1)
end

function ForwardNetcmds.C2GSSetFollowPartner(oPlayer, mData)
    local iParId = mData.partnerid
    local mTitle = mData.title or {}
    oPlayer.m_oPartnerCtrl:SetFollowPartner(iParId, mTitle)
end


function ForwardNetcmds.C2GSSetPartnerTravelPos(oPlayer, mData)
    local lPos = mData["pos_info"] or {}
    for _, m in ipairs(lPos) do
        m.parid = m.parid or 0
        if m.parid > 0 then
            local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(m.parid)
            if not oPartner then
                return
            end
            if oPartner:IsFrdTravel() then
                global.oAssistMgr:Notify(oPlayer:GetPid(), "伙伴寄存好友")
                return
            end
        end
    end
    oPlayer.m_oPartnerCtrl:SetPartnerTravelPos(lPos)
end

function ForwardNetcmds.C2GSSetFrdPartnerTravel(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    local iParId = mData["parid"]
    local iFrdPid = mData["frd_pid"]
    if oPlayer.m_oPartnerCtrl:IsFrdTravel() then
        return
    end
    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
    if oPartner then
        if oPartner:IsTravel() then
            oAssistMgr:Notify(iPid, "伙伴正在游历")
            return
        end
        if not oPartner:IsFrdTravel() then
            oPartner:SetStatus(gamedefines.PARTNER_STATUS.ON_FRD_TRAVEL, true)
        end
        mData["par_name"] = oPartner:GetName()
        mData["par_grade"] = oPartner:GetGrade()
        mData["par_star"] = oPartner:GetStar()
        mData["par_awake"] = oPartner:GetAwake()
        mData["par_model"] = table_deep_copy(oPartner:GetModelInfo())
        local mRemote = {
            pid = iPid,
            frd_pid = iFrdPid,
            data = mData,
        }
        interactive.Request(".world", "partner", "AddTravelPartner2Frd", mRemote, function(mRecord, m)
            local oPlayer = global.oAssistMgr:GetPlayer(iPid)
            local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
            if m.success then
                oPartner:PropChange("status")
            else
                if oPartner:IsFrdTravel() then
                    oPartner:SetStatus(gamedefines.PARTNER_STATUS.ON_FRD_TRAVEL, true)
                end
            end
        end)
    end
end

function ForwardNetcmds.C2GSQuickWearPartnerEquip(oPlayer, mData)
    mData = mData or {}
    local iParId = mData["partnerid"]
    local lWear = mData["wear_list"] or {}
    if oPlayer.m_oItemCtrl:ValidWearPartnerEquips(iParId,lWear) then
        oPlayer.m_oItemCtrl:WearPartnerEquips(iParId, lWear)
    end
end

function ForwardNetcmds.C2GSUpGradePartner(oPlayer, mData)
    mData = mData or {}
    local iParId = mData["partnerid"]
    local iUpgrade = mData["upgrade"]
    local oPartner =  oPlayer.m_oPartnerCtrl:GetPartner(iParId)
    if oPartner and table_in_list({1,5}, iUpgrade) then
        oPlayer.m_oPartnerCtrl:UpGradePartner(iParId, iUpgrade)
    end
end

function ForwardNetcmds.C2GSOpenPartnerUI(oPlayer, mData)
    mData = mData or {}
    local iParId = mData["partnerid"]
    local iOpen = mData["type"]
    local iMD5 = mData["md5"]
    local oPartner =  oPlayer.m_oPartnerCtrl:GetPartner(iParId)
    if oPartner then
        oPlayer.m_oPartnerCtrl:OpenPartnerUI(iParId,iOpen, iMD5)
    end
end

function ForwardNetcmds.C2GSAddPartnerSkill(oPlayer, mData)
    mData = mData or {}
    local iParId = mData["partnerid"]
    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
    if oPartner then
        oPlayer.m_oPartnerCtrl:AddPartnerSkill(iParId)
    end
end

function ForwardNetcmds.C2GSBuyPartnerBaseEquip(oPlayer, mData)
    mData = mData or {}
    local iPos = mData["pos"]
    local iParId = mData["parid"] or 0
    if not table_in_list({1,2,3,4}, iPos) then
        return
    end
    local res = require "base.res"
    local iStar,iLevel = 1, 1
    local iShape = itemdefines.GetPartnerEquipShape(iPos, iStar, iLevel)
    local mItem = res["daobiao"]["item"][iShape]
    if not mItem then
        return
    end
    local oItem = loaditem.GetItem(iShape)
    if oItem:ItemType() ~= "parequip" then
        return
    end
    local iNeedPrice = oItem:BuyPrice()
    if iNeedPrice <= 0 then
        return
    end
    if oPlayer.m_oItemCtrl:ValidGive({{iShape, 1}}) then
        oPlayer.m_oItemCtrl:BuyPartnerBaseEquip(iShape, iParId)
    end
end

function ForwardNetcmds.C2GSRecyclePartnerEquipList(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    mData = mData or {}
    local lEquipId = mData["equipids"] or {}
    local iCoin = 0
    for _, iEquipId in ipairs(lEquipId) do
        local  oItem = oPlayer:HasItem(iEquipId)
        if not oItem then
            return
        end
        if oItem:ItemType() ~= "parequip" then
            return
        end
        -- if oItem:IsWield() then
        --     oAssistMgr:BroadCastNotify(iPid, nil, "该符文已穿戴")
        --     return
        -- end
        if oItem:IsLock() then
            oAssistMgr:BroadCastNotify(iPid, nil, "该符文已上锁")
            return
        end
        iCoin = iCoin + oItem:SalePrice()
    end
    local sReason = "伙伴符文出售"
    for _, iEquipId in ipairs(lEquipId) do
        local  oItem = oPlayer:HasItem(iEquipId)
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(oItem:GetWield())
        if oPartner then
            oItem:UnWield(oPartner, oPlayer)
            oAssistMgr:DispatchFinishHook()
        end
        oPlayer.m_oItemCtrl:AddAmount(oItem, -1, sReason, {cancel_tip = 1})
    end
    if iCoin > 0 then
        oPlayer:RewardCoin(iCoin, sReason, {cancel_tip = 1, cancel_show =1})
        local sMsg = string.format("已出售完毕，获得了%s#amount", oAssistMgr:CoinIcon())
        oAssistMgr:BroadCastNotify(iPid, nil, sMsg, {amount = iCoin})
    end
end

function ForwardNetcmds.C2GSStrengthPartnerEquip(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    mData = mData or {}
    local iEquipId = mData["itemid"]
    local iOneKey = mData["one_key"]
    local iHaveCoin = mData["coin"] or 0
    local  oParEquip = oPlayer:HasItem(iEquipId)
    if not oParEquip then
        return
    end
    if oParEquip:ItemType() ~= "parequip" then
        return
    end
    if oParEquip:IsMaxLevel() then
        oAssistMgr:BroadCastNotify(iPid, nil, "已达到当前星级最大等级，升星后可继续升级")
        return
    end
    local iPos = oParEquip:EquipPos()
    local iStar = oParEquip:Star()
    local iStartLv = oParEquip:EquipLevel()
    local iEndLv = iStartLv + 1
    if iOneKey == 1 then
        iEndLv = 10
    end
    local iShape = itemdefines.GetPartnerEquipShape(iPos, iStar, iStartLv)
    local oItemObj = loaditem.GetItem(iShape)
    if oItemObj:UpgradeCoin() > iHaveCoin then
        global.oUIMgr:GS2CShortWay(iPid,1)
        return
    end
    local m = oItemObj:UpgradeItem()
    if not oPlayer:ValidRemoveItemAmount(m.sid, m.amount) then
        local o = loaditem.GetItem(m.sid)
        oAssistMgr:BroadCastNotify(iPid, nil, string.format("%s不足", o:Name()))
        return
    end
    local iCostCoin = 0
    local mCostItem = {}
    local iNewShape
    for i=iStartLv, (iEndLv - 1) do
        local iShape = itemdefines.GetPartnerEquipShape(iPos, iStar, i)
        local oItem = loaditem.GetItem(iShape)
        if iCostCoin + oItem:UpgradeCoin() > iHaveCoin then
            break
        end
        local mItem = oItem:UpgradeItem()
        local iNeedItem = mItem.amount + (mCostItem[mItem.sid] or 0)
        if oPlayer.m_oItemCtrl:GetItemAmount(mItem.sid) < iNeedItem then
            break
        end
        local iShape2 = itemdefines.GetPartnerEquipShape(iPos, iStar, i+1)
        if loaditem.GetItemData(iShape2) then
            iNewShape = iShape2
            iCostCoin = iCostCoin + oItem:UpgradeCoin()
            mCostItem[mItem.sid] = iNeedItem
        else
            record.error(string.format("C2GSStrengthPartnerEquip err:%s", iShape2))
            break
        end
    end
    if iNewShape then
        local m = {}
        m.pid = oPlayer:GetPid()
        m.reason = "符文升级"
        m.coin = iCostCoin
        oPlayer.m_oItemCtrl:StrengthPartnerEquip(iEquipId, iNewShape, m, mCostItem, iOneKey)
    end
end

function ForwardNetcmds.C2GSUpstarPartnerEquip(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    mData = mData or {}
    local iEquipId = mData["itemid"]
    local iHaveCoin = mData["coin"] or 0
    local oItem = oPlayer:HasItem(iEquipId)
    if not oItem then
        return
    end
    if oItem:ItemType() ~= "parequip" then
        return
    end
    local iCostCoin = oItem:UpstarCoin()
    if iHaveCoin < iCostCoin then
        global.oUIMgr:GS2CShortWay(iPid,1)
        return
    end
    local mItem = oItem:UpstarItem()
    if oPlayer.m_oItemCtrl:GetItemAmount(mItem.sid) < mItem.amount then
        oAssistMgr:BroadCastNotify(iPid, nil, "道具不足")
        return
    end
    if oItem:IsMaxStar() then
        oAssistMgr:BroadCastNotify(iPid, nil, "已满星")
        return
    end
    if not oItem:IsMaxLevel() then
        oAssistMgr:BroadCastNotify(iPid, nil, "强化到10级可进行升星")
        return
    end
    local m = {}
    m.pid = oPlayer:GetPid()
    m.coin = iCostCoin
    m.reason = "购买伙伴符文"
    oPlayer.m_oItemCtrl:UpstarPartnerEquip(iEquipId, m)
end

function ForwardNetcmds.C2GSInlayPartnerStone(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    mData = mData or {}
    local iEquipId = mData["equipid"]
    local iStoneId = mData["stoneid"]
    local oParEquip = oPlayer:HasItem(iEquipId)
    if not oParEquip then
        return
    end
    if oParEquip:ItemType() ~= "parequip" then
        return
    end
    local oParStone = oPlayer:HasItem(iStoneId)
    if not oParStone then
        return
    end
    if oParStone:ItemType() ~= "parstone" then
        return
    end
    oPlayer.m_oItemCtrl:InlayPartnerStone(oParEquip, oParStone)
end

function ForwardNetcmds.C2GSComposePartnerStone(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    mData = mData or {}
    local iStoneSid = mData["stonesid"]
    local iOneKey = mData["one_key"]
    local mItem = loaditem.GetItemData(iStoneSid)
    if not mItem then
        return
    end
    local oParStone = loaditem.GetItem(iStoneSid)
    if oParStone:ItemType() ~= "parstone" then
        return
    end
    if oParStone:IsMaxLevel() then
        oAssistMgr:BroadCastNotify(iPid, nil, "该符石已达最大等级")
        return
    end
    local iCost = 3
    local iHave = oPlayer:GetItemAmount(iStoneSid)
    if iHave < iCost then
        oAssistMgr:BroadCastNotify(iPid, nil, string.format("您的%s不足", mItem.name))
    end
    if iOneKey == 1 then
        iCost = (iHave // 3) * 3
    end
    local iLevel = oParStone:Level() + 1
    local iPos = oParStone:EquipPos()
    local iShape = itemdefines.GetPartnerStoneShape(iPos, iLevel)
    local lGive = {{iShape, iCost // 3}}
    if oPlayer:ValidGive(lGive) then
        local sReason = "符石合成"
        if oPlayer:RemoveItemAmount(iStoneSid, iCost, sReason, {cancel_tip = 1}) then
            oPlayer:GiveItem(lGive, sReason, {})
            oPlayer:Send("GS2CComposePartnerStone", {stonesid = iShape})
        end
    end
end

function ForwardNetcmds.C2GSUsePartnerSoulType(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    mData = mData or {}
    local iParId = mData["parid"]
    local iSoulType = mData["soul_type"] or 0
    local lSoulPos = mData["soul_pos"] or {} --pos, itemid
    oPlayer.m_oPartnerCtrl:UseParSoulType(oPlayer, iParId, iSoulType, lSoulPos)
end

function ForwardNetcmds.C2GSUpgradePartnerSoul(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    mData = mData or {}
    local iSoulId = mData["soul_id"]
    local lCostIds = mData["cost_ids"] or {}
    if oPlayer.m_oItemCtrl:ValidUpgradeParSoul(oPlayer, iSoulId, lCostIds) then
        oPlayer.m_oItemCtrl:UpgradePartnerSoul(oPlayer, iSoulId, lCostIds)
    end
end

function ForwardNetcmds.C2GSUsePartnerSoul(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    mData = mData or {}
    local iParId = mData["parid"]
    local iSoulId = mData["soul_id"]
    local iPos = mData["pos"]

    local mSoulPos = itemdefines.GetParSoulPosData(iPos)
    if not mSoulPos then
        oAssistMgr:BroadCastNotify(iPid, nil, "参数出错，部位信息不存在")
        return
    end
    if oPlayer:GetGrade() < mSoulPos.unlock_grade then
        oAssistMgr:BroadCastNotify(iPid, nil, "当前核心御灵已满")
        return
    end

    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
    if not oPartner then
        oAssistMgr:BroadCastNotify(iPid, nil, "伙伴不存在")
        return
    end
    local oItem = oPlayer:HasItem(iSoulId)
    if not oItem then
        return
    end
    if oItem:ItemType() ~= "parsoul" then
        return
    end
    if oPartner:GetSoulType() ~= oItem:GetSoulType() then
        local mSoulType = itemdefines.GetParSoulTypeData(oItem:GetSoulType())
        oAssistMgr:BroadCastNotify(iPid, nil, string.format("切换成%s核心时才能穿戴", mSoulType.name))
        return
    end
    if not oItem:IsWield() and oPartner:HasSoulAttrType(oItem:AttrType()) then
        oAssistMgr:BroadCastNotify(iPid, nil, "同属性类型的御灵仅可穿戴1件")
        return
    end
    local iHistory = oPlayer.m_oPartnerCtrl:HistoryMaxSoulAmount()
    oItem:UseSoul(oPlayer, oPartner, iPos)
    oPartner:ActivePropChange("soul_type", "souls")
    local iNew = oPlayer.m_oPartnerCtrl:CountWieldSoul()
    if iNew > iHistory then
        oAssistMgr:PushAchieve(iPid, "穿戴御灵数量", {value = iNew - iHistory})
    end
end

function ForwardNetcmds.C2GSSwapPartnerEquip(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    local iSrcParId = mData["src_parid"]
    local iDesParId = mData["des_parid"]
    local oSrcPartner = oPlayer.m_oPartnerCtrl:GetPartner(iSrcParId)
    if not oSrcPartner then
        oAssistMgr:BroadCastNotify(iPid, nil, "伙伴不存在")
        return
    end
    local oDesPartner = oPlayer.m_oPartnerCtrl:GetPartner(iDesParId)
    if not oDesPartner then
        oAssistMgr:BroadCastNotify(iPid, nil, "目标伙伴不存在")
        return
    end
    local lDesEquip = {}
    local lSrcEquipId = oSrcPartner:PackEquip()
    for _, iParEquip in ipairs(lSrcEquipId) do
        local oParEquip = oPlayer.m_oItemCtrl:HasItem(iParEquip)
        if oParEquip then
            oSrcPartner:UnWieldEquip(oParEquip, false)
            table.insert(lDesEquip, oParEquip)
        end
    end

    local lSrcEquip = {}
    local lDesEquipId = oDesPartner:PackEquip()
    for _, iParEquip in ipairs(lDesEquipId) do
        local oParEquip = oPlayer.m_oItemCtrl:HasItem(iParEquip)
        if oParEquip then
            oDesPartner:UnWieldEquip(oParEquip, false)
            table.insert(lSrcEquip, oParEquip)
        end
    end

    for _, oParEquip in ipairs(lSrcEquip) do
        oSrcPartner:WieldEquip(oParEquip, false)
        oParEquip:GS2CRefreshPartnerEquipInfo(oPlayer)
    end

    for _, oParEquip in ipairs(lDesEquip) do
        oDesPartner:WieldEquip(oParEquip, false)
        oParEquip:GS2CRefreshPartnerEquipInfo(oPlayer)
    end

    oSrcPartner:ActivePropChange("equip_list")
    oDesPartner:ActivePropChange("equip_list")
end

function ForwardNetcmds.C2GSReceivePartnerChip(oPlayer, mData)
    local iShape = 10019
    local oItem = oPlayer.m_oItemCtrl:GetItemObj(iShape)
    if not oItem then
        return
    end
    local mDraw = oPlayer:HasDrawPartner()
    if not mDraw then
        return
    end
    local iPartype = mDraw.partype
    local mPartner = loadpartner.GetPartnerData(iPartype)
    if not mPartner then
        return
    end
    local sReason = "领取一发入魂碎片"
    local mArgs = {}
    mArgs.cancel_tip = 1
    mArgs.cancel_show = 1
    oPlayer:ResetDrawPartner()
    oItem:DoGivePartner(oPlayer, iPartype, sReason, mArgs)
    interactive.Send(".world", "upcard", "CloseDrawCardUI", {pid = oPlayer:GetPid()})
end

function ForwardNetcmds.C2GSReDrawPartner(oPlayer, mData)
    local iShape = 10019
    local oItem = oPlayer.m_oItemCtrl:GetItemObj(iShape)
    if not oItem then
        return
    end
    local mDraw = oPlayer:HasDrawPartner()
    if not mDraw then
        return
    end
    oPlayer.m_oPartnerCtrl:ReDrawPartner(oPlayer)
end

function ForwardNetcmds.C2GSSwapPartnerEquipByPos(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    local iSrcParId = mData["src_parid"]
    local iDesParId = mData["des_parid"]
    local iSrcPos = mData["src_pos"]
    local iDesPos = mData["des_pos"]
    local oSrcPartner = oPlayer.m_oPartnerCtrl:GetPartner(iSrcParId)
    local oDesPartner = oPlayer.m_oPartnerCtrl:GetPartner(iDesParId)
    if not oSrcPartner or not oDesPartner then
        oAssistMgr:BroadCastNotify(iPid, nil, "伙伴不存在")
        return
    end
    if iSrcPos ~= iDesPos then
        oAssistMgr:BroadCastNotify(iPid, nil, "位置不同")
        return
    end
    if iSrcParId == iDesParId then
        oAssistMgr:BroadCastNotify(iPid, nil, "伙伴id相同")
        return
    end
    local oSrcItem = oSrcPartner:GetWieldEquip(iSrcPos)
    local oDesItem = oDesPartner:GetWieldEquip(iDesPos)
    if not oSrcItem or not oDesItem then
        oAssistMgr:BroadCastNotify(iPid, nil, "符文不存在")
        return
    end
    oSrcPartner:UnWieldEquip(oSrcItem)
    oDesPartner:UnWieldEquip(oDesItem)
    oSrcPartner:WieldEquip(oDesItem, true)
    oDesPartner:WieldEquip(oSrcItem, true)
end

function ForwardNetcmds.C2GSAddParSoulPlan(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    local sName = mData["name"] or ""
    local iSoulType = mData["soul_type"] or 0
    local lSoulPos = mData["souls"] or {}
    if oPlayer.m_oParSoulCtrl:ValidAddSoulPlan(oPlayer, sName, iSoulType, lSoulPos) then
        oPlayer.m_oParSoulCtrl:AddSoulPlan(oPlayer, sName, iSoulType, lSoulPos)
    end
end

function ForwardNetcmds.C2GSDelParSoulPlan(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    local iPlan = mData["idx"]
    oPlayer.m_oParSoulCtrl:RemoveSoulPlan(oPlayer, iPlan)
end

function ForwardNetcmds.C2GSModifyParSoulPlan(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    local iPlan = mData["idx"]
    local sName = mData["name"] or ""
    local iSoulType = mData["soul_type"] or 0
    local lSoulPos = mData["souls"] or {}
    if oPlayer.m_oParSoulCtrl:ValidModifySoulPlan(oPlayer, iPlan, sName, iSoulType, lSoulPos) then
        oPlayer.m_oParSoulCtrl:ModifySoulPlan(oPlayer, iPlan, sName, iSoulType, lSoulPos)
    end
end

function ForwardNetcmds.C2GSParSoulPlanUse(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    local iPlan = mData["idx"]
    local iParId = mData["parid"]
    if oPlayer.m_oParSoulCtrl:ValidUseParSoulPlan(oPlayer, iPlan, iParId) then
        oPlayer.m_oParSoulCtrl:UseParSoulPlan(oPlayer, iPlan, iParId)
    end
end

function ForwardNetcmds.C2GSExchangePartnerChip(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    local iChipSid = mData["chip_sid"]
    local iAmount = mData["amount"]
    if oPlayer.m_oPartnerCtrl:ValidExchangeChip(oPlayer, iChipSid, iAmount) then
        oPlayer.m_oPartnerCtrl:ExchangeChip(oPlayer, iChipSid, iAmount)
    end
end

function Forward(mRecord, mData)
    local iPid = mData.pid
    local sCmd = mData.cmd
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        local func = ForwardNetcmds[sCmd]
        assert(func, string.format("Forward function:%s not exist!", sCmd))
        func(oPlayer, mData.data)
    end
end

function GivePartner(mRecord, mData)
    local iPid = mData.pid
    local lPartner = mData.partners
    local sReason = mData.reason
    local mArgs = mData.args
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        if oPlayer.m_oPartnerCtrl:ValidGive(lPartner, mArgs) then
            oPlayer.m_oPartnerCtrl:GivePartner(lPartner, sReason, mArgs)
        else
            --oAssistMgr:Notify(iPid, "伙伴背包已满")
        end
    end
end

function GetPataPartnerList(mRecord, mData)
    local iPid = mData.pid
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    local lPataPartner = {}
    if oPlayer then
        lPataPartner = oPlayer.m_oPartnerCtrl:GetPataPartnerList()
    end
    interactive.Response(mRecord.source, mRecord.session,{
        pid = iPid,
        data = lPataPartner,
        })
end

function GetPartnerListByPlayer(mRecord, mData)
    local pid = mData["pid"]
    local parlist = mData["partner"]
    local oPlayer = global.oAssistMgr:GetPlayer(pid)
    local lPataPartner = {}
    if oPlayer then
        for _,iPartner in ipairs(parlist) do
            local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iPartner)
            if oPartner then
                table.insert(lPataPartner,oPartner:PackRemoteInfo())
            end
        end
    end
    interactive.Response(mRecord.source, mRecord.session,{
        data = lPataPartner,
        })
end

function GetPartnerWarInfoListByPlayer(mRecord, mData)
    local pid = mData["pid"]
    local parlist = mData["partner"]
    local oPlayer = global.oAssistMgr:GetPlayer(pid)
    local lPataPartner = {}
    if oPlayer then
        for _,iPartner in ipairs(parlist) do
            local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iPartner)
            if oPartner then
                table.insert(lPataPartner,oPartner:PackWarInfo())
            end
        end
    end
    interactive.Response(mRecord.source, mRecord.session,{
        data = lPataPartner,
        })
end


function RecordPataPartnerHP(mRecord, mData)
    local iPid = mData.pid
    local iParId = mData.parid
    local iHP = mData.hp
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:RecordPataPartnerHP(iParId, iHP)
    end
end

function ResetPataPartnerHP(mRecord, mData)
    local iPid = mData.pid
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:ResetPataPartnerHP(oPlayer)
    end
end

function SetFight(mRecord, mData)
    local iPid = mData.pid
    local bFight = mData.fight
    local iPos = mData.pos
    local iParId = mData.parid
    local bRefresh = mData.refresh
    local sReason = mData.reason
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        local mInfo = nil
        if bFight then
            oPlayer.m_oPartnerCtrl:OnFight(iPos, iParId, bRefresh, sReason)
            local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
            mInfo = oPartner:PackRemoteInfo()
        else
            oPlayer.m_oPartnerCtrl:OffFight(iPos, bRefresh, sReason)
        end
        oPlayer.m_oPartnerCtrl:RemoteFightPartner(iPos, iParId, mInfo)
    end
end

function SetWarPartner(mRecord, mData)
    local iPid = mData.pid
    local iWarId = mData.war_id
    local iWarAddr = mData.war_addr
    local iWarType = mData.war_type
    local iKFWarAddr = mData.kf_war_addr
    local iKFWarId = mData.kf_war_id
    local lPartnerId = mData.partner_list or {}
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        local mPartnerData = {}
        for _,mInfo in pairs(lPartnerId) do
            local iPos = mInfo["pos"]
            local iParid = mInfo["parid"]
            local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParid)
            if oPartner then
                local mFightData = {
                    partnerdata = oPartner:PackWarInfo(),
                }
                if iWarType == gamedefines.WAR_TYPE.PATA_TYPE then
                    mFightData = {
                        partnerdata = oPartner:PackPataWarInfo(),
                    }
                end
                table.insert(mPartnerData,{
                    pos = iPos,
                    parid = iParid,
                    partnerdata = mFightData,
                })
            end
        end
        local mWarData = {}
        mWarData["partner"] = mPartnerData
        local sCmd = "C2GSWarPartner"
        local mArgs = {pid = iPid, war_id = iWarId, cmd = sCmd, data = mWarData}
        if iKFWarAddr and iKFWarId then
            mArgs.war_id = iKFWarId
            router.Send("ks", iKFWarAddr, "kuafu", "Forward",mArgs)
        elseif iWarAddr then
            mArgs.war_id = iWarId
            interactive.Send(iWarAddr, "war", "Forward", mArgs)
        end
    end
end

function SetAutoSkill(mRecord, mData)
    local iPid = mData.pid
    local mAutoSkill = mData.auto_skill
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:SetAutoSkill(oPlayer, mAutoSkill)
    end
end

function AddPartnerListExp(mRecord, mData)
    local iPid = mData.pid
    local mExp = mData.data or {}
    local sReason = mData.reason
    local mArgs = mData.args or {}
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        local lName = {}
        local l1 = {}
        local l2 = {}
        for iParId, iExp in pairs(mExp) do
            local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
            if oPartner then
                if not oPartner:IsGradeLimit({cancel_tip = 1}) then
                    oPartner:RewardExp(iExp, sReason, mArgs)
                elseif oPartner:IsPlayerGradeLimit(oPlayer) then
                    table.insert(l1, oPartner:GetName())
                elseif oPartner:GetStar() < 5 then
                    table.insert(l2, oPartner:GetName())
                end
            end
        end
        if not mArgs.cancel_tip then
            if next(l1) then
                local sName = table.concat(l1, "、")
                local sMsg = "#partner_name等级超过主角等级#O5#n级时，伙伴将不再获得经验"
                local mNotifyArgs = {
                    partner_name = sName,
                }
                global.oAssistMgr:BroadCastNotify(iPid,nil,sMsg,mNotifyArgs)
            end
            if next(l2) then
                local sName = table.concat(l2, "、")
                local sMsg = "#partner_name已达到最大等级，升星后可继续获得经验"
                local mNotifyArgs = {
                    partner_name = sName,
                }
                global.oAssistMgr:BroadCastNotify(iPid,nil,sMsg,mNotifyArgs)
            end
        end
    end
end

function GetDayLimitFightPartner(mRecord,mData)
    local iPid = mData.pid
    local sKey = mData.key
    local iFix = mData.fix or 0
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    local lPataPartner = {}
    if oPlayer then
        lPataPartner = oPlayer.m_oPartnerCtrl:GetDayLimitFightPartner(sKey,iFix)
    end
    interactive.Response(mRecord.source, mRecord.session,{
        pid = iPid,
        data = lPataPartner,
        })
end

function RecordDayLimitPartner(mRecord,mData)
    local iPid = mData.pid
    local sKey = mData.key
    local parlist = mData.partner
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:RecordDayLimitPartner(parlist,sKey)
    end
end

function GetLinkPartnerInfo(mRecord, mData)
    local iPid = mData.pid
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    local iPartner = mData.partner
    local mResult = {}
    if oPlayer then
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iPartner)
        if oPartner then
            mResult = oPartner:PackLinkInfo(iPartner)
        end
    end
    interactive.Response(mRecord.source, mRecord.session,{
        pid = iPid,
        data = mResult,
        })
end

function CloseGS(mRecord, mData)
    -- global.oAssistMgr:CloseGS()
end

function Disconnected(mRecord, mData)
    -- local iPid = mData.pid
    -- global.oAssistMgr:Disconnected(iPid)
end

function SetEqualArena(mRecord,mData)
    local iPid = mData.pid
    local iPartList = mData.partner
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local lPartner = {}
    if oPlayer then
        oPlayer.m_oPartnerCtrl:SetEqualArena(iPartList)
        lPartner= oPlayer.m_oPartnerCtrl.m_EqualArena
    end
    if mData.respond then
        interactive.Response(mRecord.source, mRecord.session,{
            data = lPartner,
            })
    end

end

function GetAllPartnerInfo(mRecord, mData)
    local iPid = mData.pid
    local mInfo = mData.info
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        local mPartner = oPlayer.m_oPartnerCtrl:GetAllPartnerInfo(mInfo)
        interactive.Response(mRecord.source, mRecord.session,{
            pid = iPid,
            data = mPartner,
        })
    end
end

function TestCmd(mRecord, mData)
    local iPid = mData.pid
    local sCmd = mData.cmd
    local sType = mData.type
    local m = mData.data
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local sReason = "gm测试"
    if oPlayer then
        if sCmd == "savedb" then
            oPlayer:DoSave()
            return
        end
        if sType == "item" then
            oPlayer.m_oItemCtrl:TestCmd(oPlayer, sCmd, m, sReason)
        else
            oPlayer.m_oPartnerCtrl:TestCmd(oPlayer, sCmd, m, sReason)
        end
    end
end

function BackUpTerraWarsInfo(mRecord, mData)
    local iPid = mData.pid
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        local mPartner = oPlayer.m_oPartnerCtrl:BackUpTerraWarsInfo()
        interactive.Response(mRecord.source, mRecord.session,{
            pid = iPid,
            data = mPartner,
        })
    end
end

function PackTerraWarInfo(mRecord,mData)
    local iPid = mData.pid
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        local mPartner = oPlayer.m_oPartnerCtrl:PackTerraWarInfo(mData.partner)
        interactive.Response(mRecord.source, mRecord.session,{
            pid = iPid,
            data = mPartner,
        })
    end
end

function SyncGuardInfo(mRecord,mData)
    local iPid = mData.pid
    local mPartner = mData.partner
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:SyncGuardInfo(mPartner)
    end
end

function RemoveMineTravelPartner(mRecord, mData)
    local iPid = mData["pid"]
    local iParId = mData["parid"]
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:RemoveMineTravel(iParId)
    end
end

function SyncHouseAttr(mRecord, mData)
    local iPid = mData["pid"]
    local mAttr = mData["attr"] or {}
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:SetHouseAttr(mAttr)
    end
end

function UpdatePowerRank(mRecord, mData)
    local iPid = mData["pid"]
    local mRank = mData["rank"] or {}
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:UpdatePowerRank(mRank)
    end
end

function OpenParSoul(mRecord, mData)
    local iPid = mData["pid"]
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oPartnerCtrl:OpenParSoul(oPlayer)
    end
end

function FixSevDayParEquip(mRecord, mData)
    local iPid = mData.pid
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        local mSetStar = oPlayer.m_oPartnerCtrl.m_mParEquipStar or {}
        for iType, mSet in pairs(mSetStar) do
            for iStar, iCount in pairs(mSet) do
                oPlayer.m_oPartnerCtrl:CheckParEquipStarAchieve(iType, iStar, iCount)
            end
        end
    end
end

function FixCountParEquipWield(mRecord, mData)
    local iPid = mData["pid"]
    local oPlayer = global.oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        local iCount = oPlayer.m_oPartnerCtrl:CountWieldEquip()
        if iCount > 0 then
            global.oAssistMgr:PushAchieve(iPid, "穿戴符文", {value = iCount})
        end
    end
end