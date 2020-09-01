local global = require "global"
local extend = require "base/extend"

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

function SortStrengthLevel(oPlayer)
    local mData = {}
    for iPos = 1,6 do
        local iLevel = oPlayer:StrengthLevel(iPos)
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

function FastEquipStrength(oPlayer)
    local sReason = "一键打造"
    local mPosRefresh = {}
    for i=1,400 do
        local mLevelData = SortStrengthLevel(oPlayer)
        local mData = mLevelData[1]
        local iLevel,iPos = table.unpack(mData)
        if iLevel >= oPlayer:GetGrade() then
            break
        end
        if oPlayer:IsMaxStrengthLevel(iPos) then
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
        oPlayer:EquipStrength(iPos,iNewLevel, sReason)
        LogAnalyEquipStrength(oPlayer,oEquip,iStrengthLevel,mMaterial,0,true)
    end
    if next(mPosRefresh) then
        oPlayer:ActivePropChange()
        for iPos,_ in pairs(mPosRefresh) do
            local oEquip = oPlayer.m_oItemCtrl:GetEquip(iPos)
            if oEquip then
                oEquip:Refresh()
            end
        end
        oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30019,1)
        oPlayer:AddSchedule("promoted_equip")
    end
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

function FastAddGemExp(oPlayer)
    local bRefresh = false
    local sReason = "宝石一键融合"
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
    if bRefresh then
        oPlayer:ActivePropChange()
        oPlayer.m_oTaskCtrl:AddTeachTaskProgress(30016,1)
    end
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

function _GetItemCompoundGrade(sid)
    local res = require "base.res"
    local mUseTbl = res["daobiao"]["compound"]
    assert(mUseTbl[sid], string.format("没有配置%d的合成材料", sid))
    return mUseTbl[sid]["grade"]
end

function _GetItemCompoundMaterial(sid)
    local res = require "base.res"
    local mUseTbl = res["daobiao"]["compound"]
    assert(mUseTbl[sid], string.format("没有配置%d的合成材料", sid))
    return table_deep_copy(mUseTbl[sid]["sid_item_list"])
end

function _GetItemCompoundCost(sid)
    local res = require "base.res"
    local mUseTbl = res["daobiao"]["compound"]
    return mUseTbl[sid]["cost"]
end

function _CheckIsMaterialEnough(oPlayer,sid)
    local mMaterialTbl = _GetItemCompoundMaterial(sid)
    for _,value in pairs(mMaterialTbl) do
        if value["amount"] > oPlayer:GetItemAmount(value["sid"]) then
           return false,value["sid"]
        end
    end
    return true
end

function CompoundItem(oPlayer,sid)
    local oNotifyMgr = global.oNotifyMgr
    local oToolMgr = global.oToolMgr
    local iPid = oPlayer:GetPid()
    local iGrade = _GetItemCompoundGrade(sid)
    if iGrade > oPlayer:GetGrade() then
         oNotifyMgr:Notify(oPlayer.m_iPid,"等级不足，无法合成该道具")
        return
    end
    local mMaterialTbl = _GetItemCompoundMaterial(sid)
    local iCostCoin = _GetItemCompoundCost(sid) or 0
    local bCanCompound,iUnEnough = _CheckIsMaterialEnough(oPlayer,sid)
    if not bCanCompound then
        local oTempItem = loaditem.LoadItem(iUnEnough)
        oNotifyMgr:Notify(oPlayer.m_iPid,string.format("%s不足",oTempItem:Name()))
        return
    end
    if not oPlayer:ValidCoin(iCostCoin) then
        oNotifyMgr:Notify(oPlayer.m_iPid,"金币不足")
        return
    end

    local sReason = "物品合成"

---开始消耗物品
    for _,value in pairs(mMaterialTbl) do
        local iSid = value["sid"]
        local iAmount = value["amount"]
        local bResult = oPlayer:RemoveItemAmount(iSid,iAmount,sReason)
        if not bResult then
            return
        end
    end

---开始消耗货币
    oPlayer:ResumeCoin(iCostCoin,sReason)

    local oTargetItem = loaditem.ExtCreate(sid)
    oPlayer:RewardItem(oTargetItem,sReason)
    oPlayer:Send("GS2CCompoundSuccess",{})
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
                oNotifyMgr:Notify(oPlayer.m_iPid,"道具数量不足，无法分解")
                return
            end
            if oItem.IsLock and oItem:IsLock() then
                oNotifyMgr:Notify(oPlayer.m_iPid,"上锁物品不可出售")
                return
            end
        end
        if oPlayer:GetItemAmount(iSid) < info.amount then
            oNotifyMgr:Notify(oPlayer.m_iPid,"道具数量不足，无法分解")
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
    for sid,amount in pairs(m) do
        for iNo=1,100 do
            local oItem = loaditem.ExtCreate(sid)
            local iAddAmount = math.min(oItem:GetMaxAmount(),amount)
            amount = amount - iAddAmount
            oItem:SetAmount(iAddAmount)
            table.insert(mItem,oItem)
            if amount <= 0 then
                break
            end
        end
    end
    for _,oItem in pairs(mItem) do
        oPlayer:RewardItem(oItem,"道具分解")
    end
    oPlayer:Send("GS2CDeComposeSuccess",{})
end

function _GetExchangeResource()
    local res = require"base.res"
    local mData = res["daobiao"]["exchangeinfo"]
    return mData
end

function ExChangeItem(oPlayer,mData)
    local mResource = _GetExchangeResource()
    local oNotifyMgr = global.oNotifyMgr
    local iTotal = 0
    for _,info in pairs(mData) do
        local sid = info.sid
        local iAmount = info.amount
        if not mResource[tostring(sid)] then
            oNotifyMgr:Notify(oPlayer.m_iPid,"合成材料有误")
            return
        end
        if oPlayer:GetItemAmount(sid) < iAmount then
            oNotifyMgr:Notify(oPlayer.m_iPid,"合成材料不足")
            return
        end
        iTotal = iTotal+iAmount
    end
    if iTotal < 3 then
        oNotifyMgr:Notify(oPlayer.m_iPid,"合成材料不足")
        return
    end
    for _,info in pairs(mData) do
        local bResult = oPlayer:RemoveItemAmount(info.sid,info.amount,"道具分解")
        if not bResult then
            return
        end
    end
    local mKey = table_key_list(mResource)
    local iSid = mKey[math.random(#mKey)]
    local oItem = loaditem.ExtCreate(iSid)
    oItem:SetAmount(1)
    oPlayer:RewardItem(oItem,"材料转换")
    oPlayer:Send("GS2CExchangeSuccess",{})
end

function ValidEquip(oPlayer,sid)
    local oItem = loaditem.GetItem(sid)
    if not oItem or not table_in_list({"equip","equipstone"},oItem.m_ItemType) then
        return false
    end
    local iSex = oItem:Sex()
    if iSex>0 and iSex ~= oPlayer:GetSex() then
        return false
    end
    local iWeapon = oItem:WeaponType()
    if iWeapon> 0 and iWeapon ~= oPlayer:GetWeaponType() then
        local res = require "base.res"
        local iSch = res["daobiao"]["schoolweapon"]["school"][iWeapon]
        if iSch ~= oPlayer:GetSchool() then
            return false
        end
    end
    return true
end


