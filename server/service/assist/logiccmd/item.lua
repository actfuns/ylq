-- import module
local global = require "global"
local skyner = require "skynet"
local record = require "public.record"
local interactive = require "base.interactive"
local colorstring = require "public.colorstring"

local gamedefines = import(lualib_path("public.gamedefines"))
local itemdefines = import(service_path("item/itemdefines"))
local loaditem = import(service_path("item/loaditem"))
local handleitem = import(service_path("item/handleitem"))
local CONTAINER_TYPE = gamedefines.ITEM_CONTAINER

ForwardNetcmds = {}

function ForwardNetcmds.C2GSItemInfo(oPlayer,mData)
    local iItemId = mData["itemid"]
    oPlayer.m_oItemCtrl:ItemInfo(iItemId)
end

function ForwardNetcmds.C2GSDeComposeItem(oPlayer,mData)
    local sReason = "分解消耗"
    local iItemId = mData["id"]
    local iAmount = mData["amount"]
    local itemobj = oPlayer.m_oItemCtrl:HasItem(iItemId)
    if not itemobj then
        return
    end
    local iSrcSID = itemobj:SID()
    if oPlayer:GetItemAmount(iSrcSID) < iAmount then
        return
    end

    local ItemList = {}
    local sDeComPosInfo = itemobj:DeComposeInfo()
    local iDestSID,sArg = string.match(sDeComPosInfo,"(%d+)(.+)")
    iDestSID = tonumber(iDestSID)
    assert(iDestSID,string.format("DeCompose err:%d %s",itemobj:SID(),sDeComPosInfo))
    local iSumAmount = iAmount
    local mArg
    if sArg then
        sArg = string.sub(sArg,2,#sArg-1)
        mArg = split_string(sArg,",")
        for _,sArg in pairs(mArg) do
            local key,value = string.match(sArg,"(.+)=(.+)")
            if key == "Amount" then
                iSumAmount = tonumber(value) * iAmount
            end
        end
    end

    ItemList = {
    {iDestSID, iSumAmount}
    }
    if not oPlayer:ValidGive(ItemList) then
        return
    end
    if not oPlayer:RemoveItemAmount(iSrcSID,iAmount, sReason) then
        return
    end

    while(iSumAmount > 0) do
        local itemobj = loaditem.Create(iDestSID)
        local iMaxAmount = itemobj:GetMaxAmount()
        local iAddAmount = min(iMaxAmount,iSumAmount)
        iSumAmount = iSumAmount - iMaxAmount
        itemobj:SetAmount(iAddAmount)
        for _,sArg in pairs(mArg) do
            local key,value = string.match(sArg,"(.+)=(.+)")
            if key ~= "Amount" then
                local sKey = string.format("m_",key)
                if itemobj[sKey] then
                    itemobj[sKey] = value
                else
                    itemobj:SetData(key,value)
                end
            end
        end
        oPlayer:RewardItem(itemobj,"DeComposeItem")
         if iSumAmount <= 0 then
            break
        end
    end
end

function ValidComposeItem(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iSid = mData["sid"]
    local iAmount = mData["amount"]
    local iPid = oPlayer:GetPid()
    local iCoinType = mData["coin_type"]
    local mData = loaditem.GetItemData(iSid)
    if not mData then
        return false
    end
    local oItem = loaditem.GetItem(iSid)
    if oItem:ItemType()  ~= "other" then
        oNotifyMgr:Notify(iPid, "道具不可合成")
        return
    end
    local iCostAmount = oItem:ComposeAmount()
    if iCostAmount <= 0 then
        oNotifyMgr:Notify(iPid, "道具不可合成")
        return false
    end
    if iAmount <= 0 then
        oNotifyMgr:Notify(iPid, "合成数量不足")
        return false
    end
    local iSize = iAmount
    local lItems = {}
    local mComPosInfo = oItem:ComposeItemInfo()
    for _,mData in pairs(mComPosInfo) do
        local iShape = mData["sid"]
        local iAmount = mData["amount"] * iSize
        table.insert(lItems, {iShape, iAmount})
    end
    if not oPlayer:ValidGive(lItems,{cancel_tip = 1}) then
        oNotifyMgr:Notify(iPid,"背包已满")
        return false
    end
    iCostAmount = iCostAmount * iAmount
    local iHaveAmount = oPlayer:GetItemAmount(iSid)
    if iHaveAmount < iCostAmount then
        if iCoinType == 0 then
            oNotifyMgr:Notify(iPid, "道具数量不足")
            return false
        end
    end
    return true
end

function ForwardNetcmds.C2GSComposeItem(oPlayer,mData)
    if not ValidComposeItem(oPlayer,mData) then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local iSid = mData["sid"]
    local iAmount = mData["amount"]
    local iPid = oPlayer:GetPid()
    local iCoinType = mData["coin_type"]
    local oItem = loaditem.GetItem(iSid)
    local iCostAmount = oItem:ComposeAmount()
    iCostAmount = iCostAmount * iAmount
    local iHaveAmount = oPlayer:GetItemAmount(iSid)
    local mInfo = {pid = iPid}
    if iHaveAmount < iCostAmount then
        if iCoinType == gamedefines.COIN_FLAG.COIN_GOLD then
            local iUseCount = iCostAmount-iHaveAmount
            mData["use_count"] = iUseCount
            local iCoinCost = oItem:BuyPrice() * iUseCount
            mInfo.goldcoin = iCoinCost
            mInfo.reason = "合成道具"
            interactive.Request(".world", "common", "FrozenMoney", mInfo, function(mRecord, m)
                local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
                if oPlayer then
                    _ComposeItem(oPlayer, m, mData)
                end
            end)
        end
    else
        mInfo.success = true
        _ComposeItem(oPlayer,mInfo,mData)
    end
    
end

function _ComposeItem(oPlayer,m,mData)
    local bFlag = false
    if m.success then
        if ValidComposeItem(oPlayer,mData) then
            local iSid = mData["sid"]
            local iAmount = mData["amount"]
            local iPid = oPlayer:GetPid()
            local oItem = loaditem.GetItem(iSid)
            local lItems = {}
            local mComPosInfo = oItem:ComposeItemInfo()
            for _,mData in pairs(mComPosInfo) do
                local iShape = mData["sid"]
                local iAmount = mData["amount"] * iAmount
                table.insert(lItems, {iShape, iAmount})
            end
            local iCostAmount = oItem:ComposeAmount()
            iCostAmount = (iCostAmount - (mData["use_count"] or 0)) * iAmount
            local sReason = "道具合成"
            if not oPlayer:RemoveItemAmount(iSid, iCostAmount, sReason) then
                return
            end
            oPlayer:GiveItem(lItems,sReason, {cancel_show = 1})
        end
    end
    oPlayer:DoResultMoney(bFlag, m)
end

function ForwardNetcmds.C2GSArrangeItem(oPlayer,mData)
    oPlayer.m_oItemCtrl:Arrange()
end

function ValidCompoundItem(oPlayer,sid,iUpgrade,mArgs)
    local res = require"base.res"
    local oNotifyMgr = global.oNotifyMgr
    mArgs = mArgs or {}
    local bOpen = res["daobiao"]["global_control"]["forge_composite"]["is_open"]
    if bOpen ~= "y" then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(oPlayer:GetPid(),"该功能正在维护，已临时关闭。请您留意官网相关信息。")
        return false
    end
    local iGrade = handleitem.GetItemCompoundGrade(sid)
    local iPlayerGrade = mArgs.grade or oPlayer:GetGrade()
    if iGrade > iPlayerGrade then
         oNotifyMgr:Notify(oPlayer:GetPid(),"等级不足，无法合成该道具")
        return false
    end
    local bCanCompound,iUnEnough = handleitem.CheckIsMaterialEnough(oPlayer,sid,iUpgrade)
    -- if not bCanCompound then
    --     local oTempItem = loaditem.LoadItem(iUnEnough)
    --     oNotifyMgr:Notify(oPlayer:GetPid(),string.format("%s不足",oTempItem:Name()))
    --     return false
    -- end
    return bCanCompound
end

function C2GSCompoundItem(mRecord,mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = mData["pid"]
    local iShape = mData["sid"]
    local iUpgrade = mData["upgrade"]
    local mArgs = mData["args"]
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local bSuc = true
    local mRemoteArgs = {}
    if not ValidCompoundItem(oPlayer,iShape,iUpgrade,mArgs) then
        bSuc = false
    else
        handleitem.DoCompoundItem(oPlayer, iShape, iUpgrade)
        mRemoteArgs.equip = {equip_se = oPlayer.m_oItemCtrl:GetWieldEquipSkill()}
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc,
        pid = iPid,
        args = mRemoteArgs,
    })
end

function ForwardNetcmds.C2GSDeCompose(oPlayer,mData)
    local res = require"base.res"
    local bOpen = res["daobiao"]["global_control"]["forge_composite"]["is_open"]
    if bOpen ~= "y" then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(oPlayer.m_iPid,"该功能正在维护，已临时关闭。请您留意官网相关信息。")
        return
    end
    local info = mData.info
    handleitem.DecomposeItem(oPlayer,info)
end

function ForwardNetcmds.C2GSLockEquip(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local iItemId = mData["itemid"]
    local iPos = mData["pos"]
    local oItem = oPlayer.m_oItemCtrl:HasItem(iItemId)
    if oItem then
        if oItem:ItemType() ~= "equipstone"  then
            return
        end
    else
        oItem = oPlayer.m_oItemCtrl:GetEquip(iPos)
    end
    if oItem then
        oItem:SetLock()
        oItem:RefreshLock()
        if oItem:IsLock() then
            oNotifyMgr:Notify(iPid, "已上锁")
        else
            oNotifyMgr:Notify(iPid, "已解锁")
        end
    end
end

function ForwardNetcmds.C2GSReNameFuWen(oPlayer,mData)
    local lPlanName = mData.plan_name
    if next(lPlanName) then
        for _, m in ipairs(lPlanName) do
            local sName = m["name"]
            local iPlan = m["plan"]
            local oEquip = oPlayer.m_oItemCtrl:GetEquip(1)
            local m = oEquip:GetFuWenPlan(iPlan)
            if m and sName ~= "" then
                oPlayer.m_oItemCtrl:SetFuWenName(iPlan, sName)
            end
        end
        oPlayer.m_oItemCtrl:GS2CFuWenPlanName()
    end
end

function ForwardNetcmds.C2GSChooseItem(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    local iItemId = mData["itemid"]
    local lItemSid = mData["itemsids"] or {}
    local oItem = oPlayer:HasItem(iItemId)
    local iAmount = mData["amount"] or 1
    if not oItem then
        oAssistMgr:BroadCastNotify(iPid, nil, "道具不存在")
        return
    end
    if oItem:ChooseAmount() <= 0 then
        oAssistMgr:BroadCastNotify(iPid, nil, "非可选道具")
        return
    end
    local mArgs = {}
    mArgs.itemsids = lItemSid
    mArgs.cancel_tip  = 1
    oPlayer.m_oItemCtrl:ItemUse(iItemId, 0, iAmount, mArgs)
    global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
end

function ForwardNetcmds.C2GSBuffStoneOp(oPlayer, mData)
    local iOp = mData["op"]
    local iItemId = mData["itemid"]
    local oItem = oPlayer:HasItem(iItemId)
    if not oItem then
        return
    end
    if not oItem:IsBuff() then
        return
    end
    if not oPlayer.m_oItemCtrl:HasBuffStone(oItem:SID()) then
        return
    end
    if iOp ==  1 then
        oPlayer.m_oItemCtrl:StrengthBuffStone(oPlayer, oItem)
    else
        oPlayer.m_oItemCtrl:CoverBuffStone(oPlayer, oItem)
    end
end

function ForwardNetcmds.C2GSInlayGem(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    mData = mData or {}
    local iPos = mData["pos"]
    local iGemPos = mData["gem_pos"]
    local iItemId = mData["itemid"]

    local iCnt = oPlayer:GetMaxGemCnt(mArgs)
    if iGemPos > iCnt then
        oAssistMgr:BroadCastNotify(iPid, nil, "宝石槽未开启")
        return
    end
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    if not oEquip then
        return
    end
    local oEquipGem = oEquip:GetGem(iGemPos)
    if oEquipGem then
        handleitem.UnlayGem(oPlayer, iPos, iGemPos, iItemId)
        return
    end
    local oGem = oPlayer:HasItem(iItemId)
    if not oGem then
        return
    end
    if oGem:ItemType() ~= "gem" then
        return
    end
    if oGem:WieldPos() ~= iPos then
        return
    end
    handleitem.InlayGem(oPlayer, iPos, iGemPos, iItemId)
end

function ForwardNetcmds.C2GSInlayAllGem(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    local iOpenGrade = oAssistMgr:QueryControl("forge_gem", "open_grade")
    if iOpenGrade > oPlayer:GetGrade() then
        return
    end

    handleitem.InlayAllGem(oPlayer)
end

function ForwardNetcmds.C2GSComposeGem(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    mData = mData or {}
    local iSid = mData["sid"]
    local iCompose = mData["amount"] or 0
    local mItem = loaditem.GetItemData(iSid)
    if not mItem then
        return
    end
    local oGem = loaditem.GetItem(iSid)
    if oGem:ItemType() ~= "gem" then
        return
    end
    if oGem:IsMaxLevel() then
        oAssistMgr:BroadCastNotify(iPid, nil, "已满级")
        return
    end
    local iHaveAmount = oPlayer:GetItemAmount(iSid)
    if iCompose == 0 then
        iCompose = iHaveAmount // 3
    end
    if iCompose <= 0 then
        return
    end
    if iCompose * 3 <= iHaveAmount then
        local sReason = "宝石合成"
        local iNewShape = oGem:SID() + 1
        local oNewGem = loaditem.GetItem(iNewShape)
        oPlayer:RemoveItemAmount(iSid, iCompose * 3, sReason, {})
        oPlayer:GiveItem({{iNewShape, iCompose}}, sReason, {cancel_tip = 1, cancel_show = 1})
        oPlayer:Send("GS2CGemCompose", {gem_sid = iNewShape, amount = iCompose})
        oAssistMgr:BroadCastNotify(iPid, nil, string.format("合成成功，获得%s * %s", oNewGem:Name(), iCompose))
        if oNewGem:Level() >= 10 then
            local sMsg = string.format("%s合成了%s颗%s，让人羡慕不已！", oPlayer:GetName(), iCompose, oNewGem:Name())
            global.oNotifyMgr:SendSysChat(sMsg, 1, 1)
        end
    end
end

function ForwardNetcmds.C2GSComposeEquip(oPlayer, mData)
    mData = mData or {}
    local iPos = mData["pos"]
    local iLevel = mData["level"]
    oPlayer.m_oItemCtrl:ComposeEquip(oPlayer, iPos, iLevel)
end

function ForwardNetcmds.C2GSUpgradeEquip(oPlayer, mData)
    mData = mData or {}
    local iPos = mData["pos"]
    local iLevel = mData["level"]
    local iCostItem = mData["cost_id"]
    if handleitem.ValidUpgradeEquip(oPlayer, iPos, iLevel, iCostItem) then
        handleitem.UpgradeEquip(oPlayer, iPos, iLevel, iCostItem)
    end
end

function ForwardNetcmds.C2GSExChangeEquip(oPlayer, mData)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    if oAssistMgr:IsClose("forge_composite") then
        oAssistMgr:BroadCastNotify(iPid, nil, "该功能正在维护，已临时关闭。请您留意官网相关信息。")
        return
    end
    if oAssistMgr:QueryControl("forge_composite", "open_grade") > oPlayer:GetGrade() then
        oAssistMgr:BroadCastNotify(iPid, nil, "等级不足")
        return
    end
    mData = mData or {}
    local iEquipId = mData["equipid"]
    if handleitem.ValidExchangeEquip(oPlayer, iEquipId) then
        handleitem.ExchangeEquip(oPlayer, iEquipId)
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

function ValidPromoteEquipLevel(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPos = mData["pos"]
    local iItemId = mData["itemid"]
    local mArgs = mData["args"]
    local iPid = oPlayer:GetPid()
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    assert(oEquip,string.format("premote equip err:%s %s",iPid,iPos))
    local oStone = oPlayer.m_oItemCtrl:HasItem(iItemId)
    if not oStone or oStone:ItemType() ~= "equipstone" then
        return false
    end
    if oEquip:EquipPos() ~= oStone:WieldPos() then
        oNotifyMgr:Notify(iPid,"不能使用该灵石升级装备")
        return false
    end
    local iShape = oStone:Shape()
    local iGrade = mArgs.grade or oPlayer:GetGrade()
    if oStone:Level() > iGrade then
        oNotifyMgr:Notify(iPid,"无法使用超过角色等级的灵石")
        return false
    end
    local iWeapon = oStone:WeaponType()
    if iWeapon > 0 and iWeapon ~= oPlayer:GetWeaponType() then
        local res = require "base.res"
        local iSch = res["daobiao"]["schoolweapon"]["school"][iWeapon]
        local sMsg = "不可穿戴该类型武器"
        if iSch == oPlayer:GetSchool() then
            sMsg = "切换流派后即可穿戴"
        end
        oNotifyMgr:Notify(iPid, sMsg)
        return false
    end
    local iSex = oStone:Sex()
    if iSex > 0 and iSex ~= oPlayer:GetSex() then
        oNotifyMgr:Notify(iPid, "装备与角色性别不符")
        return false
    end
    return true
end

function C2GSPromoteEquipLevel(mRecord,mData)
    local oNotifyMgr = global.oNotifyMgr
    local oAssistMgr = global.oAssistMgr
    local iPid = mData["pid"]
    local mPromoteData = mData["data"]
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local iPos = mPromoteData["pos"]
    local iItemId = mPromoteData["itemid"]
    local mArgs = mPromoteData.mArgs or {}
    local mRemoteArgs = {}
    local bSuc = true
    if not ValidPromoteEquipLevel(oPlayer,mPromoteData) then
        bSuc = false
    else
        local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
        assert(oEquip,string.format("premote equip err:%s %s",iPid,iPos))
        local oStone = oPlayer.m_oItemCtrl:HasItem(iItemId)
        oPlayer.m_oItemCtrl:PromoteEquipLevel(oPlayer,iPos,oStone)
        mRemoteArgs.weapon = oPlayer:GetWeapon()
        mRemoteArgs.equip = {equip_se = oPlayer.m_oItemCtrl:GetWieldEquipSkill()}
        oPlayer.m_oEquipMgr:UpdateData()
        oPlayer:UpdateFriendEquip({iPos})
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc,
        pid = iPid,
        args = mRemoteArgs,
    })
end

function ValidAddGemExp(oPlayer,mData)
    local iPos = mData["pos"]
    local iGemPos = mData["gem_pos"]
    local mGemList = mData["gem_list"]
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    for _,iItemId in pairs(mGemList) do
        local oItem = oPlayer.m_oItemCtrl:HasItem(iItemId)
        if not oItem or oItem:ItemType() ~= "gem" then
            return false
        end
        if oEquip:EquipPos() ~= oItem:WieldPos() then
            return false
        end
    end
    local iGemId = mGemList[1]
    local oGem = oPlayer:HasItem(iGemId)
    if not oGem then
        oNotifyMgr:Notify(iPid, "宝石不存在")
        return false
    end
    if oGem:ItemType() ~= "gem" then
        oNotifyMgr:Notify(iPid, "该物品非宝石")
        return false
    end
    if oEquip:EquipPos() ~= oGem:WieldPos() then
        oNotifyMgr:Notify(iPid, "穿戴部分出错")
        return false
    end
    local oEquipGem = oEquip:GetGem(iGemPos)
    if not oEquipGem then
        oNotifyMgr:Notify(iPid, "装备该部位不存在宝石")
        return false
    end
    local iMaxGemExp = oEquipGem:MaxExp()
    if oEquipGem:IsMaxLevel() then
        oNotifyMgr:Notify(iPid, "宝石已满级")
        return false
    end
    return true
end

function C2GSAddGemExp(mRecord,mData)
    local iPid = mData["pid"]
    local iPos = mData["pos"]
    local iGemPos = mData["gem_pos"]
    local mGemList = mData["gem_list"]
    local oAssistMgr = global.oAssistMgr
    local oNotifyMgr = global.oNotifyMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local mRemoteArgs = {}
    local bSuc = true
    if not ValidAddGemExp(oPlayer,mData) then
        bSuc = false
    else
        local iOldLv = oPlayer.m_oItemCtrl:MaxHistoryGemLv()
        local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
        local iGemId = mGemList[1]
        local oGem = oPlayer:HasItem(iGemId)
        local oEquipGem = oEquip:GetGem(iGemPos)
        local iMaxGemExp = oEquipGem:MaxExp()
        local iBeforeLv = oEquipGem:Level()
        local iBeforeExp = oEquipGem:GetExp()
        local iExp = oGem:GetExp()
        local sReason = "宝石合成"
        local mRecordInfo = {[oGem:SID()]={amount=1,lv=oGem:Level()}}
        oPlayer.m_oItemCtrl:AddAmount(oGem,-1,sReason)
        oEquip:AddGemExp(iGemPos, iExp, sReason)
        oEquip:Refresh()
        oPlayer.m_oEquipMgr:UpdateData()
        oPlayer:UpdateFriendEquip({iPos})
        local iNewLv = oPlayer.m_oItemCtrl:CountGemLevel() - iOldLv
        if iNewLv > iOldLv then
            oAssistMgr:PushAchieve(iPid, "宝石等级总和", {value = iNewLv - iOldLv})
            oPlayer.m_oItemCtrl:SetMaxHistoryGemLv(iNewLv)
        end
        local oAfterGem = oEquip:GetGem(iGemPos)
        oEquip:LogGem(iBeforeExp,oAfterGem:GetExp(), sReason)
        handleitem.LogAnalyEquipGem(oPlayer,oEquip,iGemPos,mRecordInfo,iBeforeExp,iBeforeLv)
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc,
        pid = iPid,
        args = mRemoteArgs,
    })
end

function ValidSaveFuWen(oPlayer,iPos)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    if not oEquip or oEquip:ItemType() ~= "equip" then
        return false
    end
    local mApply = oEquip:CurrentBackFuWen()
    if not mApply then
        oNotifyMgr:Notify(iPid,"没有淬灵属性，无法保存")
        return false
    end
    return true
end

function C2GSSaveFuWen(mRecord,mData)
    local oAssistMgr = global.oAssistMgr
    local oNotifyMgr = global.oNotifyMgr
    local iPid = mData["pid"]
    local iPos = mData["pos"]
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local bSuc = true
    local mRemoteArgs = {}
    if not ValidSaveFuWen(oPlayer,iPos) then
        bSuc = false
    else
        local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
        oEquip:UseBackFuWen(oPlayer, oEquip:EquipLevel())
        oEquip:SendFuWen(oPlayer)
        oPlayer.m_oEquipMgr:UpdateData()
        handleitem.LogAnalyEquipFuWen(2,oPlayer,oEquip,{},0)
        oPlayer:UpdateFriendEquip({iPos})
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc,
        pid = iPid,
        args = mRemoteArgs,
    })
end

function ValidUseFuWenPlan(oPlayer,iGrade)
    local oAssistMgr = global.oAssistMgr
    local iOpenGrade = oAssistMgr:QueryControl("fuwenswitch", "open_grade")
    if iGrade < iOpenGrade then
        return false
    end
    if oAssistMgr:IsClose("fuwenswitch") then
        oNotifyMgr:Notify(oPlayer:GetPid(), "该功能正在维护，已临时关闭。请您留意系统公告。")
        return false
    end
    return true
end

function C2GSUseFuWenPlan(mRecord, mData)
    local oNotifyMgr = global.oNotifyMgr
    local oAssistMgr = global.oAssistMgr
    local iPid = mData.pid
    local iGrade = mData.grade
    local bSuc = true
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if not ValidUseFuWenPlan(oPlayer,iGrade) then
        bSuc = false
    else
        local oEquip = oPlayer.m_oItemCtrl:GetEquip(1)
        local iUsedPlan = oEquip:GetFuWenPlanID()
        local iChoosePlan = 1
        if iUsedPlan == 1 then
            iChoosePlan = 2
        end
        local sReason = "切换淬灵方案"
        for iPos = itemdefines.EQUIP_WEAPON, itemdefines.EQUIP_SHOE do
            local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
            oEquip:UseFuWenPlan(oPlayer, iChoosePlan, sReason)
            oEquip:SendFuWen(oPlayer)
        end
        oPlayer.m_oEquipMgr:UpdateData()
        oPlayer:UpdateFriendEquip()
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc,
        pid = iPid,
        args = mRemoteArgs,
    })
end

function ValidRecycleItem(oPlayer,iSaleId,iSaleAmount)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    if iSaleAmount <= 0 then
        return false
    end
    local oItem = oPlayer:HasItem(iSaleId)
    if not oItem then
        return false
    end
    if oItem.IsLock and oItem:IsLock() then
        oNotifyMgr:Notify(iPid, "上锁物品不可出售")
        return false
    end
    local iHaveAmount = oItem:GetAmount()
    if iHaveAmount < iSaleAmount then
        oNotifyMgr:Notify(iPid, "道具不足")
        return false
    end
    if oItem:SalePrice() == 0 then
        oNotifyMgr:Notify(iPid, "道具不可出售")
        return false
    end
    return true
end

function RecycleItem(mRecord,mData)
    local iPid = mData.pid
    local oNotifyMgr = global.oNotifyMgr
    local oAssistMgr = global.oAssistMgr
    local iSaleId = mData["itemid"]
    local iSaleAmount = mData["amount"]

    local oPlayer = oAssistMgr:GetPlayer(iPid)

    if not ValidRecycleItem(oPlayer,iSaleId,iSaleAmount) then
        interactive.Response(mRecord.source, mRecord.session, {
            success = false,
        })
    end
    local oItem = oPlayer:HasItem(iSaleId)
    local iSalePrice = oItem:SalePrice() * iSaleAmount

    local sReason = "道具出售"
    local sName = oItem:Name()
    oPlayer.m_oItemCtrl:AddAmount(oItem,-iSaleAmount,sReason)
    interactive.Response(mRecord.source, mRecord.session, {
        success = true,
        pid = iPid,
        sale_price = iSalePrice,
        sale_amount = iSaleAmount,
        sale_name = sName,
    })
end

function RecycleItemList(mRecord,mData)
    local oNotifyMgr= global.oNotifyMgr
    local oAssistMgr = global.oAssistMgr
    local iPid = mData.pid
    local lSaleList = mData["sale_list"]
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local mSaleList = {}
    local bFlag = true
    for _, mSale in pairs(lSaleList) do
        local iSaleId = mSale["itemid"]
        local iSaleAmount= mSale["amount"]
        local oItem = oPlayer:HasItem(iSaleId)
        if not oItem then
            bFlag = false
            break
        end
        if oItem:SalePrice() == 0 then
            oNotifyMgr:Notify(iPid, "出售失败，存在不可出售道具")
            bFlag = false
            break
        end
        if oItem.IsLock and oItem:IsLock() then
            oNotifyMgr:Notify(iPid, "上锁物品不可出售")
            bFlag = false
            break
        end
        mSaleList[iSaleId] =  iSaleAmount + (mSaleList[iSaleId] or 0)
        if mSaleList[iSaleId] > oItem:GetAmount() then
            oNotifyMgr:Notify(iPid, "道具不足")
            bFlag = false
            break
        end
    end

    if not bFlag then
        interactive.Response(mRecord.source, mRecord.session, {
            success = false,
        })
        return
    end

    local iSalePrice = 0
    local sReason = "批量出售道具"
    for iSaleId, iSaleAmount in pairs(mSaleList) do
        local oItem = oPlayer:HasItem(iSaleId)
        if oItem then
            local iHaveAmount = oItem:GetAmount()
            if iHaveAmount >= iSaleAmount then
                local iPrice = oItem:SalePrice()
                oPlayer.m_oItemCtrl:AddAmount(oItem,-iSaleAmount,sReason)
                iSalePrice = iSalePrice + iPrice * iSaleAmount
            end
        end
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = true,
        pid = iPid,
        sale_price = iSalePrice,
    })
end

--一键打造
function C2GSFastStrength(mRecord,mData)
    local iPid = mData.pid
    local mArgs = mData.args or {}
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local bSuc = handleitem.FastEquipStrength(oPlayer,mArgs)
    local mRemoteArgs = {
        equip_strength = mArgs.equip_strength,
    }
    if bSuc then
        oPlayer.m_oEquipMgr:UpdateData()
        oPlayer:UpdateFriendEquip()
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc,
        pid = iPid,
        args = mRemoteArgs,
    })
end

function C2GSFastAddGemExp(mRecord,mData)
    local iPid = mData.pid
    local mArgs = mData.args or {}
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local bRefresh = handleitem.FastAddGemExp(oPlayer,mArgs)
    local mRemoteArgs = { }
    oPlayer.m_oEquipMgr:UpdateData()
    oPlayer:UpdateFriendEquip()
    interactive.Response(mRecord.source, mRecord.session, {
        success = true,
        pid = iPid,
        brefresh = bRefresh,
        args = mRemoteArgs,
    })
end

function C2GSItemUse(mRecord, mData)
    local iPid = mData.pid
    local mItemData = mData.data
    local iItemId = mItemData["itemid"]
    local iTarget = mItemData["target"]
    local iAmount = mItemData["amount"] or 1
    local mArgs = mItemData["remote_args"] or {}
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local bSuc = false
    local mRemoteArgs = {}
    if oPlayer and oPlayer.m_oItemCtrl:ValidItemUse(iItemId) then
        bSuc = true
        local oItem = oPlayer:HasItem(iItemId)
        oItem:Use(oPlayer,iTarget, iAmount or 1, mArgs)
        mRemoteArgs = oPlayer:GetRemoteItemData()
        -- mRemoteArgs.show_keep = global.oUIMgr:GetRemoteKeep(iPid)
        -- global.oUIMgr:ClearRemoteKeep(iPid)
        oPlayer:ClearRemoteItemData()
        global.oUIMgr:ShowKeepItem(iPid)
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc,
        pid = iPid,
        args = mRemoteArgs,
    })
end

function ValidResetFuWen(oPlayer,iPos)
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    if not oEquip then
        return false
    end
    local iShape = 11101
    local iLevel = oEquip:EquipLevel()
    local mFuwenData = itemdefines.GetFuWenData(iPos, iLevel)
    local iHaveAmount = oPlayer:GetItemAmount(iShape)
    local iNeedAmount = mFuwenData.count or 0
    if iHaveAmount < iNeedAmount then
        return false
    end
    return true
end

function GetResetFuWenInfo(oPlayer,iPos,iPrice)
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    if not oEquip then
        return false
    end
    local iShape = 11101
    local iLevel = oEquip:EquipLevel()
    local mFuwenData = itemdefines.GetFuWenData(iPos, iLevel)
    local iHaveAmount = oPlayer:GetItemAmount(iShape)
    local iNeedAmount = mFuwenData.count or 0
    local iBuyAmount = iNeedAmount - iHaveAmount
    return {
        shape = iShape,
        amount = iBuyAmount,
        price = iPrice,
    }
end

function ResetFuWen(oPlayer,iPos,iPrice,mArgs)
    local sReason = "重置符文"
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer:GetPid()
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    local iShape = 11101
    local oItem = loaditem.GetItem(iShape)
    assert(oItem, string.format("other item data err: %s", iShape))
    local iLevel = oEquip:EquipLevel()
    local mFuwenData = itemdefines.GetFuWenData(iPos, iLevel)
    local iHaveAmount = oPlayer:GetItemAmount(iShape)
    local iNeedAmount = mFuwenData.count
    local iTotalPrice = 0
    local iTureCost = 0
    local iHaveAmount = oPlayer:GetItemAmount(iShape)
    if iHaveAmount < iNeedAmount then
        return
    end
    oPlayer:RemoveItemAmount(iShape,iNeedAmount,sReason)
    local mApply = oItem:ResetFuWen(oEquip)
    oEquip:AddBackFuWen(oPlayer, mApply)
    oEquip:SendFuWen(oPlayer)
    local mPrice = {}
    table.insert(mPrice,{sid = iShape,price = oItem:BuyPrice()})
    oPlayer:Send("GS2CItemPrice",{
        item_info = mPrice
    })

    global.oAssistMgr:PushAchieve(iPid, "装备淬灵", {value = 1})
    handleitem.LogAnalyEquipFuWen(1,oPlayer,oEquip,{[iShape]=iTureCost},iTotalPrice)
end

function C2GSResetFuWen(mRecord,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = mData.pid
    local mRemoteData = mData.data
    local iPos = mRemoteData["pos"]
    local iPrice = mRemoteData["price"]
    local mArgs = mRemoteData["args"]
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local bSuc = false
    local mRemoteArgs = {
        pos = iPos,
    }
    if oPlayer and ValidResetFuWen(oPlayer,iPos) then
        bSuc = true
        ResetFuWen(oPlayer,iPos,iPrice,mArgs)
    else
        local mItem = GetResetFuWenInfo(oPlayer,iPos,iPrice)
        local lItem = {{mItem.shape,mItem.amount}}
        if not oPlayer:ValidGive(lItem,{cancel_tip = 1}) then
            oNotifyMgr:Notify(iPid, "重置失败，背包格子不足")
            mRemoteArgs.fail = true
        end
        mRemoteArgs.buy_item = {{mItem.shape,mItem.amount,iPrice}}
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc,
        pid = iPid,
        args = mRemoteArgs,
    })
end

function ValidBuyEquipStrength(oPlayer,iPos,mArgs)
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    if not oEquip or oEquip:ItemType() ~= "equip" then
        return false
    end
    if oPlayer:IsMaxStrengthLevel(iPos,mArgs) then
        oNotifyMgr:Notify(iPid, "已达最大可强化等级")
        return false
    end
    local iStrengthLevel = oPlayer:StrengthLevel(iPos)
    local iGrade = mArgs.grade or oPlayer:GetGrade()
    if iStrengthLevel >= iGrade then
        return false
    end
    return true
end

function ValidEquipStrength(oPlayer,iPos,mStrengthInfo,mArgs)
    local oNotifyMgr = global.oNotifyMgr
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    local iPid = oPlayer:GetPid()
    if not oEquip or oEquip:ItemType() ~= "equip" then
        return
    end
    if not mStrengthInfo then
        return
    end
    if oPlayer:IsMaxStrengthLevel(iPos,mArgs) then
        oNotifyMgr:Notify(iPid, "已达最大可强化等级")
        return
    end
    local iStrengthLevel = oPlayer:StrengthLevel(iPos)
    local iGrade = mArgs.grade or oPlayer:GetGrade()
    if iStrengthLevel >= iGrade then
        oNotifyMgr:Notify(iPid, "强化等级不可超过角色等级")
        return
    end
    local mItemList = handleitem.StrengthMaterial(oPlayer,oEquip)
    local lBuyItem = {}
    for _,mItemData in pairs(mStrengthInfo) do
        local iShape = mItemData["sid"] or 0
        local iAmount = mItemData["amount"] or 0
        local iPrice = mItemData["price"] or 0
        if not mItemList[iShape] then
            return false
        end
        local iNeedAmount = mItemList[iShape]
        local iHaveAmount = oPlayer:GetItemAmount(iShape)
        local iItemAmount = math.min(iNeedAmount,iHaveAmount)
        if iHaveAmount < iNeedAmount then
            local iBuyAmount = iNeedAmount - iHaveAmount
            table.insert(lBuyItem, {iShape, iBuyAmount})
        end
    end
    if table_count(lBuyItem) > 0 then
        if not oPlayer:ValidGive(lBuyItem,{cancel_tip = 1}) then
            oNotifyMgr:Notify(iPid,"请预留足够的空位")
            return false
        end
    end
    for iShape,iAmount in pairs(mItemList) do
        if oPlayer:GetItemAmount(iShape) < iAmount then
            return false
        end
    end
    return true
end

function GetEquipStrengBuyInfo(oPlayer,iPos,mStrengthInfo)
    local oNotifyMgr = global.oNotifyMgr
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    local iPid = oPlayer:GetPid()
    local mItemList = handleitem.StrengthMaterial(oPlayer,oEquip)
    local lBuyItem = {}
    for _,mItemData in pairs(mStrengthInfo) do
        local iShape = mItemData["sid"]
        local iAmount = mItemData["amount"] or 0
        local iPrice = mItemData["price"]
        assert(mItemList[iShape],string.format("GetEquipStrengBuyInfo error,pid:%s sid:%s",oPlayer:GetPid(),iShape))
        if not mItemList[iShape] then
            return lBuyItem
        end
        local iNeedAmount = mItemList[iShape] or 0
        local iHaveAmount = oPlayer:GetItemAmount(iShape)
        if iHaveAmount < iNeedAmount then
            local iBuyAmount = iNeedAmount - iHaveAmount
            table.insert(lBuyItem, {iShape, iBuyAmount,iPrice})
        end
    end
    return lBuyItem
end

function EquipStrength(oPlayer,mData,mArgs)
    local sReason = "装备强化"
    local oNotifyMgr = global.oNotifyMgr
    local iPos = mData["pos"]
    local mArgs = mData["args"]
    local iPid = oPlayer:GetPid()
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    local mItemList = handleitem.StrengthMaterial(oPlayer,oEquip)
    local mTrueCostItem = {}
    for iShape,iAmount in pairs(mItemList) do
        mTrueCostItem[iShape] = iAmount
        oPlayer:RemoveItemAmount(iShape,iAmount,sReason)
    end
    local iStrengthLevel = oPlayer:StrengthLevel(iPos,mArgs)
    local iNewLevel = iStrengthLevel + 1
    oPlayer:EquipStrength(iPos,iNewLevel, sReason,mArgs)
    oEquip:Refresh()
    local iTotalPrice = mArgs.goldcoin or 0
    oPlayer.m_oEquipMgr:UpdateData()
    oPlayer:UpdateFriendEquip({iPos})
    global.oAssistMgr:PushAchieve(iPid, "装备突破总等级", {value = 1})

    handleitem.LogAnalyEquipStrength(oPlayer,oEquip,iStrengthLevel,mTrueCostItem,iTotalPrice,false)
end

function C2GSEquipStrength(mRecord,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = mData["pid"]
    local iPos = mData["pos"]
    local mStrengthInfo = mData["strength_info"]
    local mArgs = mData["args"]
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local bSuc = false
    local mRemoteArgs = {
        pos = iPos,
    }
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    local mItemList = handleitem.StrengthMaterial(oPlayer,oEquip)
    if ValidEquipStrength(oPlayer,iPos,mStrengthInfo,mArgs) then
        bSuc = true
        EquipStrength(oPlayer,mData,mArgs)
        mRemoteArgs.level = oPlayer:StrengthLevel(iPos)
        oPlayer:UpdateFriendEquip({iPos})
    else
        local lBuyItem = GetEquipStrengBuyInfo(oPlayer,iPos,mStrengthInfo)
        if not oPlayer:ValidGive(lBuyItem,{cancel_tip = 1}) then
            oNotifyMgr:Notify(iPid, "突破失败，背包格子不足")
            mRemoteArgs.fail = true
        end
        if not ValidBuyEquipStrength(oPlayer,iPos,mArgs) then
            mRemoteArgs.fail = true
        end
        mRemoteArgs.buy_item = lBuyItem
    end
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc,
        pid = iPid,
        args = mRemoteArgs,
    })
end

function RewardItemList(mRecord, mData)
    local iPid = mData.pid
    local lItem = mData.items or {}
    local sReason = mData.reason
    local mArgs = mData.args or {}
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oItemCtrl:GiveItem(lItem, sReason, mArgs)
    end
end

function RewardItem(mRecord,mData)
    local iPid = mData.pid
    local mItemData = mData.item or {}
    local sReason = mData.reason
    local mArgs = mData.args or {}
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local oItem = loaditem.LoadItem(mItemData["sid"],mItemData)
    if oPlayer then
        oPlayer:RewardItem(oItem,sReason,mArgs)
    end
end

function InitEquip(mRecord,mData)
    local iPid = mData.pid
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oItemCtrl:InitEquip()
    end
end

function RemoveItemAmount(mRecord,mData)
    local iPid = mData.pid
    local iShape = mData.shape
    local iAmount = mData.amount
    local sReason = mData.reason
    local mArgs = mData.args or {}
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local bSuc = false
    if oPlayer then
        if oPlayer:GetItemAmount(iShape) < iAmount then
            bSuc = false
        else
            bSuc = oPlayer:RemoveItemAmount(iShape,iAmount,sReason, mArgs)
        end
    end
    oPlayer.m_oItemCtrl:ShareUpdate()
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc,
        pid = iPid,
    })
end

--items{{sid, amount}}
function RemoveItemList(mRecord, mData)
    local iPid = mData.pid
    local lItem = mData.items
    local sReason = mData.reason
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local bSucc = false
    if oPlayer then
        if oPlayer.m_oItemCtrl:ValidRemoveItemList(lItem, {cancel_tip = 1}) then
            oPlayer.m_oItemCtrl:RemoveItemList(lItem, sReason)
            bSucc = true
        end
    end
    oPlayer.m_oItemCtrl:ShareUpdate()
    interactive.Response(mRecord.source, mRecord.session, {
        success = bSucc,
        pid = iPid,
        items = lItem,
    })
end

function GiveItem(mRecord,mData)
    local iPid = mData.pid
    local lItem = mData.items or {}
    local sReason = mData.reason
    local mArgs = mData.args or {}
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local bSuc = true
    if not oPlayer then
        bSuc = false
    else
        if not oPlayer:ValidGive(lItem,{cancel_tip = 1}) then
            bSuc = false
        else
            oPlayer.m_oItemCtrl:GiveItem(lItem, sReason, mArgs)
        end
    end
    oPlayer.m_oItemCtrl:ShareUpdate()
     interactive.Response(mRecord.source, mRecord.session, {
        success = bSuc,
        pid = iPid,
    })
end

function GetItemLink(mRecord,mData)
    local iPid = mData.pid
    local iItemId = mData.itemid or 0
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local oItem = oPlayer.m_oItemCtrl:HasItem(iItemId)
    if not oItem then
        local mEquip = oPlayer.m_oItemCtrl:GetEquipList()
        for iPos, oEquip in pairs(mEquip) do
            if oEquip:ID() == iItemId then
                oItem = oEquip
                break
            end
        end
    end
    local mItemData = {}
    if oItem then
        mItemData = oItem:PackItemInfo()
    end
    interactive.Response(mRecord.source, mRecord.session, {
        item = mItemData
    })
end

function GetEquipList(mRecord,mData)
    local iPid = mData.pid
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local mData = {}
    local mEquip = oPlayer.m_oItemCtrl:GetEquipList()
    for iPos, oEquip in pairs(mEquip) do
        mData[iPos] = oEquip:PackItemInfo()
    end
    interactive.Response(mRecord.source, mRecord.session,mData)
end

function GetEquipLinkList(mRecord, mData)
    local iPid = mData.pid
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local mData = {}
    local mEquip = oPlayer.m_oItemCtrl:GetEquipList()
    for iPos, oEquip in pairs(mEquip) do
        mData[iPos] = oEquip:PackItemInfo()
    end
    interactive.Response(mRecord.source, mRecord.session,mData)
end

function OpenFuWenPlan(mRecord, mData)
    local iPid = mData.pid
    local iPlan = mData.plan
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    oPlayer.m_oItemCtrl:OpenFuWenPlan(oPlayer, iPlan)
end

function GetTotalGemLevel(mRecord, mData)
    local iPid = mData.pid
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        local iCnt = oPlayer.m_oItemCtrl:CountGemLevel()
        local mData = {level = iCnt}
        interactive.Response(mRecord.source, mRecord.session, {pid = iPid, data = mData})
    end
end

function TestCmd(mRecord, mData)
    local iPid = mData.pid
    local sCmd = mData.cmd
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if oPlayer then
        oPlayer.m_oItemCtrl:TestCmd(oPlayer, sCmd, mData.data)
    end
end