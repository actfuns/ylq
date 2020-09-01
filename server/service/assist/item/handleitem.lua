local global = require "global"
local extend = require "base/extend"
local interactive = require "base.interactive"
local record = require "public.record"

local itemdefines = import(service_path("item.itemdefines"))
local loaditem = import(service_path("item.loaditem"))
local analy = import(lualib_path("public.dataanaly"))

local min = math.min
local max = math.max
local random = math.random

------------------------符文相关----------------------------
local function GetFuWenData(iPos)
    local res = require "base.res"
    local mData = res["daobiao"]["fuwen_attr"][iPos]
    assert(mData,string.format("fuwen err:%d",iPos))
    return mData
end

--计算符文属性波动概率
function CalculateFuWenK()
    local res = require "base.res"
    local mData = res["daobiao"]["fuwen_wave"]
    local mRatio = {}
    for iNo,mRatioData in pairs(mData) do
        mRatio[iNo] = mRatioData["ratio"]
    end
    local iNo = table_choose_key(mRatio)
    local mRatioData = mData[iNo]
    local iMinRatio = mRatioData["min_ratio"]
    local iMaxRatio = mRatioData["max_ratio"]
    if iMinRatio == iMaxRatio then
        return iMinRatio
    else
        return random(iMinRatio,iMaxRatio)
    end
end

function CalculateFuWen(oEquip)
    local iPos = oEquip:EquipPos()
    local mData = GetFuWenData(iPos)
    local iAttrCnt = mData["cnt"]
    local mFuWenAttr = {"hp","attack","defense","speed","critical_ratio",
    "res_critical","critical_damage","res_abnormal_ratio"}
    local mAttrs =  extend.Random.sample_table(mFuWenAttr, iAttrCnt)
    local mEnv = {
        ilv = oEquip:EquipLevel(),
    }
    local mApply = {}
    for _,sAttr in pairs(mAttrs) do
        local iK = CalculateFuWenK()
        local sValue = mData[sAttr]
        local iValue = formula_string(sValue,mEnv)
        iValue = iValue * iK / 100
        iValue = math.floor(iValue)
        mApply[sAttr] = iValue
    end
    return mApply
end

function GetStrengthData(iPos,iStrengthLevel)
    local res = require "base.res"
    local mData = res["daobiao"]["strength"][iPos][iStrengthLevel]
    assert(mData,string.format("strength effect err:%s %s",iPos,iStrengthLevel))
    return mData
end

function StrengthMaterial(oPlayer,oEquip)
    local iPos = oEquip:EquipPos()
    local iStrengthLevel = oPlayer:StrengthLevel(iPos)
    local mStrengthData = GetStrengthData(iPos,iStrengthLevel)
    local mItemList = {}
    local mEnv = {}
    local mShape = mStrengthData["sid_list"] or {}
    for _,mInfo in pairs(mShape) do
        local iShape = mInfo["sid"]
        local sAmount = mInfo["amount"]
        local iAmount = formula_string(sAmount,mEnv)
        mItemList[iShape] = iAmount
    end
    return mItemList
end

function ComposePartnerEquip(oPlayer, oEquip1, oEquip2)
end

function SortStrengthLevel(oPlayer,mArgs)
    local mData = {}
    for iPos = 1,6 do
        local iLevel = oPlayer:StrengthLevel(iPos,mArgs)
        table.insert(mData,{iLevel,iPos})
    end
    local sortfunc = function (data1,data2)
        if data1[1] ~= data2[1] then
            return data1[1] < data2[1]
        else
            return data1[2] < data2[2]
        end
    end
    table.sort(mData,sortfunc)
    return mData
end

function FastEquipStrength(oPlayer,mArgs)
    local sReason = "一键打造"
    local mPosRefresh = {}
    local iCntLevel = 0
    for i=1,400 do
        local mLevelData = SortStrengthLevel(oPlayer,mArgs)
        local mData = mLevelData[1]
        local iLevel,iPos = table.unpack(mData)
        local iGrade = mArgs.grade or oPlayer:GetGrade()
        if iLevel >= iGrade then
            break
        end
        if oPlayer:IsMaxStrengthLevel(iPos,mArgs) then
            break
        end
        local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
        local mMaterial = StrengthMaterial(oPlayer,oEquip)
        local bBreak = false
        for iShape,iAmount in pairs(mMaterial) do
            if oPlayer:GetItemAmount(iShape) < iAmount then
                bBreak = true
                break
            end
        end
        if bBreak then
            break
        end
        for iShape,iAmount in pairs(mMaterial) do
            if not oPlayer:RemoveItemAmount(iShape,iAmount,sReason) then
                bBreak = true
            end
        end
        if bBreak then
            break
        end
        mPosRefresh[iPos] = 1
        local iStrengthLevel = oPlayer:StrengthLevel(iPos)
        local iNewLevel = iStrengthLevel + 1
        iCntLevel = iCntLevel + 1
        oPlayer:EquipStrength(iPos,iNewLevel, sReason,mArgs)
        LogAnalyEquipStrength(oPlayer,oEquip,iStrengthLevel,mMaterial,0,true)
    end
    local bSuc = false
    if next(mPosRefresh) then
        bSuc = true
        for iPos,_ in pairs(mPosRefresh) do
            local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
            if oEquip then
                oEquip:Refresh()
            end
        end
        if iCntLevel > 0 then
            global.oAssistMgr:PushAchieve(oPlayer:GetPid(), "装备突破总等级", {value = iCntLevel})
        end
    end
    return bSuc
end

local function FastPosAddGemExp(oPlayer,oEquip,iGemPos,mLevelGem)
    local sReason = "宝石一键融合"
    local oEquipGem = oEquip:GetGem(iGemPos)
    local iNeedExp = oEquipGem:GetUpLevelNeedExp()
    local iCurLevel = oEquipGem:Level()
    local iMaxLevel = oEquipGem:MaxLevel()
    local mUseItemList = {}
    local iExp = 0
    --等级由小到大，取最小升级条件
    for iLevel = 1,iMaxLevel do
        local mGemItem = mLevelGem[iLevel]
        if mGemItem then
            for _,iItemId in pairs(mGemItem) do
                local oItem = oPlayer.m_oItemCtrl:HasItem(iItemId)
                local iAmount = oItem:GetAmount()
                local iAddExp = oItem:GetExp()
                local iExp = iExp + iAddExp * iAmount
                if iExp > iNeedExp then
                    local iAddAmount = 0
                    iExp = iExp - iAddExp * iAmount
                    for i = 1,iAmount do
                        iExp = iExp + iAddExp
                        iAddAmount = iAddAmount + 1
                        if iExp >= iNeedExp then
                            mUseItemList[iItemId] = iAddAmount
                            break
                        end
                    end
                else
                    mUseItemList[iItemId] = iAmount
                    if iExp == iNeedExp then
                        break
                    end
                end
            end
        end
    end
    iExp = 0
    local mRecordInfo = {}
    for iItemId,iAmount in pairs(mUseItemList) do
        local oItem = oPlayer.m_oItemCtrl:HasItem(iItemId)
        local Shape = oItem:SID()
        mRecordInfo[Shape] = mRecordInfo[Shape] or {amount=0,lv=oItem:Level()}
        mRecordInfo[Shape]["amount"] = mRecordInfo[Shape]["amount"] + iAmount
        local iAddExp = oItem:GetExp()
        iExp = iExp + iAddExp * iAmount
        oPlayer.m_oItemCtrl:AddAmount(oItem,-iAmount,sReason)
    end
    if iExp > 0 then
        local iBeforeLv = oEquipGem:Level()
        local iBeforeExp = oEquipGem:GetExp()
        oEquip:AddGemExp(iGemPos,iExp,sReason)
        local oAfterGem = oEquip:GetGem(iGemPos)
        oEquip:LogGem(iBeforeExp,oAfterGem:GetExp(), sReason)
        LogAnalyEquipGem(oPlayer,oEquip,iGemPos,mRecordInfo,iBeforeExp,iBeforeLv)
        return true
    end
end

function FastAddGemExp(oPlayer,mArgs)
    local bRefresh = false
    local sReason = "宝石一键融合"
    local iOldLv = oPlayer.m_oItemCtrl:MaxHistoryGemLv()
    for iPos = itemdefines.EQUIP_WEAPON,itemdefines.EQUIP_SHOE do
        local bEquipRefresh = false
        local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
        local iMaxGemCnt = oPlayer:GetMaxGemCnt()
        for iGemPos = 1,iMaxGemCnt do
            local oEquipGem = oEquip:GetGem(iGemPos)
            if not oEquipGem then
                local oGem = oPlayer.m_oItemCtrl:GetMinLevelGem(iPos)
                if not oGem then
                    break
                end
                bEquipRefresh = true
                bRefresh = true
                local iGemType = oGem:SID()
                local mRecordInfo = {[iGemType]={amount=1,lv=oGem:Level()}}
                oPlayer.m_oItemCtrl:AddAmount(oGem,-1,sReason)
                local oNewGem = loaditem.Create(iGemType)
                oEquip:AddGem(iGemPos,oNewGem)
                oNewGem:Effect(oPlayer)
                oEquip:LogGem(0,oNewGem:GetExp(), sReason)
                LogAnalyEquipGem(oPlayer,oEquip,iGemPos,mRecordInfo,0,0)
            end
        end
        for i = 1,100 do
            local mLevelGem = oPlayer.m_oItemCtrl:GetLevelGem(iPos)
            if table_count(mLevelGem) <= 0 then
                break
            end
            local mLevelData = oEquip:GemLevelSort()
            if table_count(mLevelData) <= 0 then
                break
            end
            local mLevel = mLevelData[1]
            local iLevel,iGemPos = table.unpack(mLevel)
            if iLevel >= 10 then
                break
            end
            local bFlag = FastPosAddGemExp(oPlayer,oEquip,iGemPos,mLevelGem)
            if bFlag then
                bRefresh = true
                bEquipRefresh = true
            else
                break
            end
        end
        if bEquipRefresh then
            oEquip:Refresh()
        end
    end
    local iNewLv = oPlayer.m_oItemCtrl:CountGemLevel()
    if iNewLv > iOldLv then
        global.oAssistMgr:PushAchieve(oPlayer:GetPid(), "宝石等级总和", {value = iNewLv - iOldLv})
        oPlayer.m_oItemCtrl:SetMaxHistoryGemLv(iNewLv)
    end
    return bRefresh
end

function LogAnalyEquipStrength(oPlayer,oEquip,blv,costitem,goldcoin,is_one_click)
    local mLog = oPlayer:GetPubAnalyData()
    local iPos = oEquip:EquipPos()
    mLog["equipment_id"] = oEquip:SID()
    mLog["equipment_type"] = iPos
    mLog["equipment_level_before"] = blv
    mLog["equipment_level_after"] = oPlayer:StrengthLevel(iPos)
    mLog["is_one_click"] = is_one_click
    mLog["consume_crystal"] = goldcoin
    local consume_item = ""
    for sid,amount in pairs(costitem) do
        if amount > 0 then
            if consume_item == "" then
                consume_item = string.format("%d+%d",sid,amount)
            else
                consume_item = string.format("%s&%d+%d",consume_item,sid,amount)
            end
        end
    end
    mLog["consume_item"] = consume_item
    analy.log_data("EquipmentBreakthrough",mLog)
end

-- operation 1-重置　2-保存
function LogAnalyEquipFuWen(operation,oPlayer,oEquip,costitem,goldcoin)
    local mLog = oPlayer:GetPubAnalyData()
    local iPos = oEquip:EquipPos()
    mLog["operation"] =operation
    mLog["equipment_type"] =iPos
    mLog["equipment_id"] = oEquip:SID()
    costitem = costitem or {}
    local consume_item = ""
    for sid,amount in pairs(costitem) do
        if amount > 0 then
            if consume_item == "" then
                consume_item = string.format("%d+%d",sid,amount)
            else
                consume_item = string.format("%s&%d+%d",consume_item,sid,amount)
            end
        end
    end
    mLog["consume_item"] = consume_item
    mLog["consume_crystal"] = goldcoin
    analy.log_data("EquipmentCuiling",mLog)
end

function LogAnalyEquipGem(oPlayer,oEquip,iGemPos,costitem,bexp,blv)
    local mLog = oPlayer:GetPubAnalyData()
    local iPos = oEquip:EquipPos()
    local oGem = oEquip:GetGem(iGemPos)
    mLog["operation"] = 1
    mLog["equipment_id"] = oEquip:SID()
    mLog["equipment_type"] = iPos
    mLog["equipment_level"] = oEquip:EquipLevel()
    mLog["stone_location"] = iGemPos
    mLog["before_exp"] = bexp
    mLog["after_exp"] = oGem:GetExp()
    mLog["before_lv"] = blv
    mLog["after_lv"] = oGem:Level()
    local consume_item = ""
    for sid,info in pairs(costitem) do
        if info.amount > 0 then
            if consume_item == "" then
                consume_item = string.format("%d+%d+%d",sid,info.amount,info.lv)
            else
                consume_item = string.format("%s&%d+%d",consume_item,sid,info.amount,info.lv)
            end
        end
    end
    mLog["consume_item"] = consume_item
    analy.log_data("gemstone",mLog)
end

function GetItemCompoundGrade(sid)
    local res = require "base.res"
    local mUseTbl = res["daobiao"]["compound"]
    assert(mUseTbl[sid], string.format("没有配置%d的合成材料", sid))
    return mUseTbl[sid]["grade"]
end

function GetItemCompoundMaterial(sid, iUpgrade)
    local res = require "base.res"
    local mUseTbl = res["daobiao"]["compound"]
    assert(mUseTbl[sid], string.format("没有配置%d的合成材料", sid))
    if iUpgrade ~= 0 then
        local iWeapon =mUseTbl[sid]["upgrade_weapon"]
        assert(iWeapon > 0, string.format("compound err,weapon not exist! sid:%s", sid))
        local lRet = table_deep_copy(mUseTbl[sid]["upgrade_material"])
        -- table.insert(lRet, {sid = iWeapon, amount = 1})
        return lRet
    end
    return table_deep_copy(mUseTbl[sid]["sid_item_list"])
end

function GetUpgradeCostEquip(sid, iUpgrade)
    local res = require "base.res"
    local mUseTbl = res["daobiao"]["compound"]
    assert(mUseTbl[sid], string.format("没有配置%d的合成材料", sid))
    local iShape = mUseTbl[sid]["upgrade_weapon"]
    assert(iShape > 0, string.format("compound err,weapon not exist! sid:%s", sid))
    return iShape
end

function CheckIsMaterialEnough(oPlayer,sid, iUpgrade)
    local mMaterialTbl = GetItemCompoundMaterial(sid, iUpgrade)
    for _,value in pairs(mMaterialTbl) do
        if value["amount"] > oPlayer:GetItemAmount(value["sid"]) then
           return false
        end
    end
    local bUpgrade = CheckUpgradeEquip(oPlayer, sid, iUpgrade)
    return bUpgrade
end

function CheckUpgradeEquip(oPlayer, sid, iUpgrade)
    if iUpgrade == 0 then
        return true
    end
    local oStone = oPlayer:HasItem(iUpgrade)
    if oStone and oStone:ItemType() ~= "equipstone" then
        return false
    end
    local iShape = GetUpgradeCostEquip(sid, iUpgrade)
    if oStone then
        return oStone:SID() == iShape
    else
        local oWield = oPlayer.m_oItemCtrl:GetEquipByID(iUpgrade)
        if oWield and oWield:GetStoneShape() == iShape then
            return true
        end
    end
    return false
end

function DoCompoundItem(oPlayer, sid, iUpgrade)
    local sReason = "物品合成"
    local mMaterialTbl = GetItemCompoundMaterial(sid, iUpgrade)
    --开始消耗物品
    for _,value in pairs(mMaterialTbl) do
        local iSid = value["sid"]
        local iAmount = value["amount"]
        local bResult = oPlayer:RemoveItemAmount(iSid,iAmount,sReason)
        if not bResult then
            break
        end
    end
    local oTargetItem = loaditem.ExtCreate(sid)
    if iUpgrade == 0 then
        oPlayer:RewardItem(oTargetItem,sReason)
    else
        local oStone = oPlayer:HasItem(iUpgrade)
        if oStone then
            local bRemove = oPlayer:RemoveItem(iUpgrade,sReason,{refresh = true})
            if bRemove then
                oPlayer:RewardItem(oTargetItem,sReason)
            end
        else
            local oEquip = oPlayer.m_oItemCtrl:GetEquipByID(iUpgrade)
            if oEquip then
                _DoChangeEquip(oPlayer, oEquip, oTargetItem)
            end
        end
    end
    oPlayer:Send("GS2CCompoundSuccess",{})
end

function _DoChangeEquip(oPlayer, oEquip, oEquipStone)
    local iPos = oEquip:EquipPos()
    local iNowLevel = oEquip:EquipLevel()
    local oOldEquipStone = oEquip:CreateEquipStone()
    local iNewLevel = oEquipStone:Level()
    local iQuality = oEquipStone:Quality()
    local iStoneLock = oEquipStone:GetData("lock", 0)

    local iNewShape = oEquip:SID() + (iNewLevel-iNowLevel) * 10
    local mArgs = {
        item_level = iQuality,
    }
    local mApply = oEquipStone:PackApplyData(oPlayer:GetSchool())
    oEquip:UnWield(oPlayer)
    local oNewEquip = loaditem.Create(iNewShape,mArgs)
    oPlayer.m_oItemCtrl:DispatchItemID(oNewEquip)
    oNewEquip:UseEquipStone(mApply)
    oEquip:BackUp(oNewEquip)
    oNewEquip:Wield(oPlayer)
    oPlayer.m_oItemCtrl:WieldEquip(iPos,oNewEquip)
    oPlayer.m_oEquipMgr:UpdateData()

    oNewEquip:SetData("lock", iStoneLock)
    oNewEquip:Refresh()
    if itemdefines.EQUIP_WEAPON == 1 then
        oPlayer:ChangeWeapon()
    end
    oPlayer:SynShareObj({equip = 1})
    oPlayer:UpdateFriendEquip({iPos})
end

function _GetDecomposeItem(sid)
    local res = require"base.res"
    local mData = res["daobiao"]["decompose"][sid]["sid_item_list"]
    return mData
end

function DecomposeItem(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local m = {}
    for _,info in pairs(mData) do
        local iSid = info.sid
        local iItemId = info.id
        if iItemId ~= 0 then
            local oItem = oPlayer.m_oItemCtrl:HasItem(iItemId)
            if not oItem then
                oNotifyMgr:Notify(oPlayer:GetPid(),"道具数量不足，无法分解")
                return
            end
            if oItem.IsLock and oItem:IsLock() then
                oNotifyMgr:Notify(oPlayer:GetPid(),"上锁物品不可出售")
                return
            end
        end
        if oPlayer:GetItemAmount(iSid) < info.amount then
            oNotifyMgr:Notify(oPlayer:GetPid(),"道具数量不足，无法分解")
            return
        else
            local mItem = _GetDecomposeItem(iSid)
            for _,T in pairs(mItem) do
                m[T["sid"]] = (m[T["sid"]] or 0) + T["amount"]
            end
        end
    end
    for _,info in pairs(mData) do
        local bResult = false
        if info.id then
            bResult = oPlayer:RemoveItem(info.id,"道具分解",{refresh=true})
        else
            bResult = oPlayer:RemoveItemAmount(info.sid,info.amount,"道具分解")
        end
        if not bResult then
            return
        end
    end
    local mItem = {}
    for sid,iAmount in pairs(m) do
        for iNo=1,100 do
            local oItem = loaditem.ExtCreate(sid)
            local iAddAmount = math.min(oItem:GetMaxAmount(),iAmount)
            iAmount = iAmount - iAddAmount
            oItem:SetAmount(iAddAmount)
            table.insert(mItem,oItem)
            if iAmount <= 0 then
                break
            end
        end
    end
    for _,oItem in pairs(mItem) do
        oPlayer:RewardItem(oItem,"道具分解")
    end
    global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
    oPlayer:Send("GS2CDeComposeSuccess",{})
end

--时间复杂度 6×6×200
function InlayAllGem(oPlayer)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    local mInlay = {}
    local iOldLv = oPlayer.m_oItemCtrl:MaxHistoryGemLv()
    local iGemCnt = oPlayer:GetMaxGemCnt()
    for iPos = itemdefines.EQUIP_WEAPON, itemdefines.EQUIP_SHOE do
        local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
        if oEquip then
            for iCnt = 1, iGemCnt do
                local iGemPos = oEquip:GetMinLevelGemPos(iGemCnt)
                local oGem = oEquip:GetGem(iGemPos)
                local oMaxGem = oPlayer.m_oItemCtrl:GetMaxLevelGem(iPos)
                if not oMaxGem then
                    break
                end
                if oGem then
                    if oGem:Level() >= oMaxGem:Level() then
                        break
                    else
                        mInlay[iPos] = 1
                        oGem:UnEffect(oPlayer)
                        oEquip:RemoveGem(oPlayer, iGemPos)
                        DoInlayAllGem(oPlayer, oEquip, iGemPos,oMaxGem)
                        oGem:SetAmount(1)
                        oPlayer.m_oItemCtrl:AddItem(oGem, "一键镶嵌宝石", {cancel_tip = 1, cancel_channel = 1, cancel_show = 1})
                    end
                else
                    mInlay[iPos] = 1
                    DoInlayAllGem(oPlayer, oEquip, iGemPos, oMaxGem)
                end
            end
        end
    end
    if next(mInlay) then
        for iPos, _ in pairs(mInlay) do
            local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
            oEquip:Refresh()
        end
        oPlayer.m_oEquipMgr:UpdateData()
        oPlayer:UpdateFriendEquip({iPos})
        oPlayer:SynShareObj({equip = 1})
        local iNewLv = oPlayer.m_oItemCtrl:CountGemLevel()
        if iNewLv > iOldLv then
            oAssistMgr:PushAchieve(iPid, "宝石等级总和", {value = iNewLv - iOldLv})
            oPlayer.m_oItemCtrl:SetMaxHistoryGemLv(iNewLv)
        end
    end
end

function DoInlayAllGem(oPlayer, oEquip, iGemPos, oMaxGem)
    local mRecordInfo = {[oMaxGem:SID()]={amount=1,lv=oMaxGem:Level()}}
    local sReason = "一键镶嵌宝石"
    local iGemType = oMaxGem:SID()
    local oNewGem = loaditem.Create(iGemType)
    oPlayer.m_oItemCtrl:AddAmount(oMaxGem,-1,sReason)
    oEquip:AddGem(iGemPos,oNewGem)
    oNewGem:Effect(oPlayer)

    if oNewGem:Level() >= 3 then
        global.oAssistMgr:PushAchieve(oPlayer:GetPid(), "宝石3级次数", {value = 1})
    end
    LogAnalyEquipGem(oPlayer,oEquip,iGemPos,mRecordInfo,0,0)
end

function UnlayGem(oPlayer, iPos, iGemPos, iItemId)
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    if not oEquip then
        return
    end
    local oEquipGem = oEquip:GetGem(iGemPos)
    if not oEquipGem then
        return
    end
    oEquipGem:UnEffect(oPlayer)
    oEquipGem:SetAmount(1)
    oEquip:RemoveGem(iGemPos)
    oPlayer.m_oItemCtrl:AddItem(oEquipGem, "卸下宝石", {cancel_tip = 1, cancel_show=1, cancel_channel = 1})

    local oGem = oPlayer:HasItem(iItemId)
    if oGem and oGem:ItemType() == "gem" then
        InlayGem(oPlayer, iPos, iGemPos, iItemId)
    else
        oEquip:Refresh()
        oPlayer.m_oEquipMgr:UpdateData()
        oPlayer:UpdateFriendEquip({iPos})
        oPlayer:SynShareObj({equip = 1})
    end
end

function InlayGem(oPlayer, iPos, iGemPos, iItemId)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()
    local oGem = oPlayer:HasItem(iItemId)
    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    local mRecordInfo = {[oGem:SID()]={amount=1,lv=oGem:Level()}}
    local sReason = "宝石镶嵌"
    local iGemType = oGem:SID()
    local iOldLv = oPlayer.m_oItemCtrl:MaxHistoryGemLv()
    oPlayer.m_oItemCtrl:AddAmount(oGem,-1,sReason)
    local oNewGem = loaditem.Create(iGemType)
    oEquip:AddGem(iGemPos,oNewGem)
    oNewGem:Effect(oPlayer)
    oEquip:Refresh()

    oPlayer.m_oEquipMgr:UpdateData()
    oPlayer:UpdateFriendEquip({iPos})
    oPlayer:SynShareObj({equip = 1})

    local iNewLv = oPlayer.m_oItemCtrl:CountGemLevel()
    if iNewLv > iOldLv then
        oAssistMgr:PushAchieve(iPid, "宝石等级总和", {value = iNewLv - iOldLv})
        oPlayer.m_oItemCtrl:SetMaxHistoryGemLv(iNewLv)
    end
    if oNewGem:Level() >= 3 then
        oAssistMgr:PushAchieve(iPid, "宝石3级次数", {value = 1})
    end
    LogAnalyEquipGem(oPlayer,oEquip,iGemPos,mRecordInfo,0,0)
end

function ValidUpgradeEquip(oPlayer, iPos, iLevel, iCostEquip)
    local oAssistMgr = global.oAssistMgr
    local iPid = oPlayer:GetPid()

    local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
    if not oEquip then
        return false
    end
    local oCostEquip = oPlayer:HasItem(iCostEquip)
    local iStoneShape = oCostEquip and oCostEquip:SID()
    if not oCostEquip then
        oCostEquip = oPlayer.m_oItemCtrl:GetEquipByID(iCostEquip)
        iStoneShape = oCostEquip and oCostEquip:GetStoneShape()
    end
    if not oCostEquip then
        return false
    end
    local mComData = itemdefines.GetComposeEquipData(iPos, iLevel)
    if not mComData then
        return false
    end
    if oPlayer:GetGrade() < mComData.grade then
        return false
    end
    local lCostItem = mComData.upgrade_material
    for _, m in ipairs(lCostItem) do
        if oPlayer:GetItemAmount(m.sid) < m.amount then
            oAssistMgr:BroadCastNotify(iPid, nil, "材料不足")
            return false
        end
    end
    local lCostEquip = mComData.upgrade_weapon
    if not table_in_list(lCostEquip, iStoneShape) then
            oAssistMgr:BroadCastNotify(iPid, nil, "道具不在消耗列表中")
        return false
    end
    local iEquipSid = oPlayer.m_oItemCtrl:RandomGiveEquip(oPlayer, mComData.upgrade_item)
    if not iEquipSid then
        return false
    end
    return true
end

function UpgradeEquip(oPlayer, iPos, iLevel, iCostEquip)
    local mComData = itemdefines.GetComposeEquipData(iPos, iLevel)
    if mComData.upgrade_coin > 0 then
        local mData = {}
        mData.pid = oPlayer:GetPid()
        mData.coin = mComData.upgrade_coin
        mData.reason = "装备升级"
        -- mData.args = {cancel_tip = 1}
        interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
            local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
            if oPlayer then
                DoUpgradeEquip(oPlayer, m, iPos, iLevel, iCostEquip)
            end
        end)
    else
        mData.success = true
        DoUpgradeEquip(oPlayer, mData, iPos, iLevel, iCostEquip)
    end
end

function DoUpgradeEquip(oPlayer, m, iPos, iLevel, iCostEquip)
    local bFlag = false
    if m.success then
        if ValidUpgradeEquip(oPlayer, iPos, iLevel, iCostEquip) then
            bFlag = true
            local mComData = itemdefines.GetComposeEquipData(iPos, iLevel)
            local lCostItem = mComData.upgrade_material
            for _, mItem in ipairs(lCostItem) do
                oPlayer:RemoveItemAmount(mItem.sid, mItem.amount, m.reason, {cancel_tip = 1})
            end
            local iCostShape, iEquipId
            local oCostEquip = oPlayer:HasItem(iCostEquip)
            local iEquipSid = oPlayer.m_oItemCtrl:RandomGiveEquip(oPlayer, mComData.upgrade_item)
            local oStone = loaditem.ExtCreate(iEquipSid)
            if oCostEquip then
                iCostShape = oCostEquip:SID()
                oPlayer.m_oItemCtrl:AddAmount(oCostEquip, -1, m.reason, {cancel_tip = 1})
                oPlayer:RewardItem(oStone, m.reason, {cancel_tip = 1})
                -- global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
                iEquipId = oStone:ID()
            else
                local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
                iCostShape = oEquip:GetStoneShape()
                _DoChangeEquip(oPlayer, oEquip, oStone)
                local oEq = oPlayer.m_oItemCtrl:GetEquip(iPos)
                iEquipId = oEq and oEq:ID()
            end
            local args = {
                {"&role&", oPlayer:GetName()},
                {"&item&", loaditem.ItemColorName(iCostShape)},
                {"&item&", loaditem.ItemColorName(iEquipSid)},
            }
            local sMsg= global.oAssistMgr:GetChuanWenTextData(10009, args)
            global.oNotifyMgr:SendSysChat(sMsg , 1, 1)
            oPlayer:Send("GS2CExchangeEquip", {itemid = iEquipId})
        end
    end
    oPlayer:DoResultMoney(bFlag, m)
end

function ValidExchangeEquip(oPlayer, iEquipId)
    local oEquip = oPlayer:HasItem(iEquipId)
    if not oEquip then
        oEquip = oPlayer.m_oItemCtrl:GetEquipByID(iEquipId)
        if not oEquip then
            return false
        end
    end
    if oEquip:ItemType() ~= "equipstone"  and oEquip:ItemType() ~= "equip" then
        return false
    end
    local iEquipSid = oEquip:GetStoneShape()
    local mExchange = itemdefines.GetEquipExchangeData(iEquipSid)
    if not mExchange then
        return false
    end
    local iEquipSid = oPlayer.m_oItemCtrl:RandomGiveEquip(oPlayer, mExchange.change_item)
    if not iEquipSid then
        global.oAssistMgr:BroadCastNotify(oPlayer:GetPid(), nil, "数据错误")
        print(debug.traceback(), iEquipSid)
        return false
    end
    local lCostItem = mExchange.cost_item or {}
    for _, mItem in ipairs(lCostItem) do
        if oPlayer:GetItemAmount(mItem.sid) < mItem.amount then
            global.oAssistMgr:BroadCastNotify(oPlayer:GetPid(), nil, "材料不足")
            return false
        end
    end
    return true
end

function ExchangeEquip(oPlayer, iEquipId)
    local oStone = oPlayer:HasItem(iEquipId)
    if not oStone then
        oStone = oPlayer.m_oItemCtrl:GetEquipByID(iEquipId)
    end
    local iShape = oStone:GetStoneShape()
    local mExchange = itemdefines.GetEquipExchangeData(iShape)
    if mExchange.cost_coin > 0 then
        local mData = {}
        mData.pid = oPlayer:GetPid()
        mData.coin = mExchange.cost_coin
        mData.reason = "装备装换"
        -- mData.args = {cancel_tip = 1}
        interactive.Request(".world", "common", "FrozenMoney", mData, function(mRecord, m)
            local oPlayer = global.oAssistMgr:GetPlayer(m.pid)
            if oPlayer then
                DoExchangeEquip(oPlayer, m, iEquipId)
            end
        end)
    else
        mData.success = true
        DoExchangeEquip(oPlayer, mData, iEquipId)
    end
end

function DoExchangeEquip(oPlayer, m, iItemId)
    local bFlag = false
    if m.success then
        if ValidExchangeEquip(oPlayer, iItemId) then
            bFlag = true
            local oStone = oPlayer:HasItem(iItemId)
            if not oStone then
                oStone = oPlayer.m_oItemCtrl:GetEquipByID(iItemId)
            end
            local iShape = oStone:GetStoneShape()
            local mExchange = itemdefines.GetEquipExchangeData(iShape)
            -- local mStone = extend.Array.weight_choose(mExchange.change_item, "weight")
            local iEquipSid = oPlayer.m_oItemCtrl:RandomGiveEquip(oPlayer, mExchange.change_item)
            local oNewStone = loaditem.ExtCreate(iEquipSid)
            local lCostItem = mExchange.cost_item or {}
            for _, mItem in ipairs(lCostItem) do
                oPlayer:RemoveItemAmount(mItem.sid, mItem.amount, m.reason, {cancel_tip = 1})
            end
            local iEquipId
            if oStone:ItemType() == "equipstone" then
                oPlayer.m_oItemCtrl:DispatchItemID(oNewStone)
                oPlayer.m_oItemCtrl:AddAmount(oStone,-1,m.reason, {cancel_tip = 1})
                oPlayer:RewardItem(oNewStone, m.reason, {cancel_tip = 1})
                iEquipId = oNewStone:ID()
                -- global.oUIMgr:ShowKeepItem(oPlayer:GetPid())
            else
                local iPos = oStone:EquipPos()
                _DoChangeEquip(oPlayer, oStone, oNewStone)
                local oEquip =  oPlayer.m_oItemCtrl:GetEquip(iPos)
                iEquipId =oEquip and oEquip:ID()
            end
            oPlayer:Send("GS2CExchangeEquip", {itemid = iEquipId})
        end
    end
    oPlayer:DoResultMoney(bFlag, m)
end