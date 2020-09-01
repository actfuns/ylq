local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local res = require "base.res"
local extend = require "base.extend"
local record = require "public.record"

local itembase = import(service_path("item/itembase"))

local max = math.max
local min = math.min
local random = math.random


CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "partner_equip"

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

function CItem:New(sid)
    local o = super(CItem).New(self,sid)
    o.m_mMainApply = {}     --主属性
    o.m_mMainApply2 = {}    --主属性2
    o.m_mSubApply = {}      --副属性
    o.m_mPlanInfo = {}
    o:SetData("equip_level", 0)
    o:SetData("equip_exp", 0)
    o:SetData("wield", 0)
    o:SetData("lock", 0)
    return o
end

function CItem:Load(mData)
    super(CItem).Load(self,mData)
    self.m_mMainApply = mData["main_apply"] or {}
    self.m_mSubApply = mData["sub_apply"] or {}
    self.m_mMainApply2 = mData["main_apply2"] or {}

    local mPlanInfo = mData["partner_plan_info"] or {}
    for iPartnerId,  m in pairs(mPlanInfo) do
        iPartnerId = tonumber(iPartnerId)
        for _, iPlanId in ipairs(m) do
            local mPlan = self.m_mPlanInfo[iPartnerId]  or {}
            mPlan[iPlanId] = true
            self.m_mPlanInfo[iPartnerId] = mPlan
        end
    end
end

function CItem:Save()
    local mData = super(CItem).Save(self)

    mData["main_apply"] = self.m_mMainApply
    mData["sub_apply"] = self.m_mSubApply
    mData["main_apply2"] = self.m_mMainApply2

    local mPlanInfo = {}
    for iPartnerId,  mPlan in pairs(self.m_mPlanInfo) do
        local m = {}
        for iPlanId, bPlan in pairs(mPlan) do
            if bPlan then
                table.insert(m, iPlanId)
            end
        end
        if next(m) then
            mPlanInfo[db_key(iPartnerId)] = m
        end
    end
    mData["partner_plan_info"] = mPlanInfo
    return mData
end

function CItem:EquipPos()
    return self:GetItemData()["pos"]
end

function CItem:Model()
    return self:GetItemData()["model"]
end

function CItem:Star()
    return self:GetItemData()["equip_star"]
end

function CItem:EquipType()
    return self:GetItemData()["equip_type"]
end

function CItem:EquipTypeName()
    local res = require "base.res"
    local iType = self:EquipType()
    local m = res["daobiao"]["partner_item"]["equip_set"][iType]
    return m.name
end

function CItem:MaxLevel()
    return 15
end

function CItem:GetPlanInfo()
    return self.m_mPlanInfo
end

function CItem:GetUpGradeData()
    local iStar = self:Star()
    local iLevel = self:GetData("equip_level", 0)
    local mData = res["daobiao"]["partner_item"]["equip_upgrade"]
    mData = mData[iStar][iLevel]
    assert(mData, string.format("partner equip err: %s, %s, %s", self:SID(), iStar, iLevel))

    return mData
end

function CItem:GetSubApplyData()
    local iStar = self:Star()
    local mData = res["daobiao"]["partner_item"]["equip_sub_init_attr"]
    mData = mData[iStar]
    assert(mData, string.format("partner equip err: %s, %s", self:SID(), iStar))

    return mData
end

function CItem:GetMainApplyData()
    local iStar = self:Star()
    local mData = res["daobiao"]["partner_item"]["equip_main_init_attr"]
    mData = mData[iStar]
    assert(mData, string.format("partner equip err: %s, %s", self:SID(), iStar))

    return mData
end

function CItem:GetAttrData(sAttr)
    local mData = res["daobiao"]["partner_item"]["equip_attr_info"]
    mData = mData[sAttr]
    assert(mData, string.format("partner equip err: %s, %s", self:SID(), sAttr))

    return mData
end

function CItem:GetMaxExp()
    local iStar = self:Star()
    local iMaxLevel = self:MaxLevel()
    local mData = res["daobiao"]["partner_item"]["equip_upgrade"]
    mData =mData[iStar][iMaxLevel]
    return mData.upgrade_exp
end

function CItem:GetEatExp()
    local mData = self:GetUpGradeData()
    if self:EquipType() == 60 then
        return mData.eat_exp_fuwen
    end
    return mData.eat_exp
end

function CItem:GetUpGradeCost()
    local mData = self:GetUpGradeData()
    return mData.upgrade_cost
end

function CItem:SetWield(iPartnerId)
    self:SetData("wield", iPartnerId or 0)
end

function CItem:GetWield()
    return self:GetData("wield")
end

function CItem:GetEquipExp()
    return self:GetData("equip_exp", 0)
end

function CItem:GetEquipLevel()
    return self:GetData("equip_level", 0)
end

function CItem:SetEquipLevel(iLevel)
    if iLevel > self:GetEquipLevel() then
        local iStar = self:Star()
        local mData = res["daobiao"]["partner_item"]["equip_upgrade"]
        mData =mData[iStar][iLevel -1]
        self:SetData("equip_exp", mData.upgrade_exp)
        self:SetData("equip_level", iLevel)
    end
end

function CItem:GetLock()
    return self:GetData("lock", 0)
end

function CItem:SetLock()
    self:Dirty()

    local iLock = self:GetData("lock")
    if iLock == 0 then
        self:SetData("lock", 1)
    else
        self:SetData("lock", 0)
    end
end

function CItem:IsLock()
    if self:GetLock() == 0 then
        return false
    else
        return true
    end
end

function CItem:GetInPlan()
    for iPartnerId, mPlanInfo in pairs(self.m_mPlanInfo) do
        if next(mPlanInfo) then
            return 1
        end
    end
    return 0
end

function CItem:Create(iLevel)
    self:CreateMainApply()
    self:CreateSubApply()
    self:CreateMainApply2()
end

function CItem:CreateMainApply()
    local mEnv = {}
    local sArgs = self:GetItemData()["main_attr_rate"]
    local mRate = formula_string(sArgs, mEnv)
    local iRan = random(100)
    local iTotal = 0
    for sAttr, iRate in pairs(mRate) do
        iTotal = iTotal + iRate
        if iRan <= iTotal then
            self:InitMainApply(sAttr)
            break
        end
    end
end

function CItem:CreateMainApply2()
    local mEnv = {}
    local sArgs = self:GetItemData()["main_attr_rate2"]
    local mRate = formula_string(sArgs, mEnv)
    local iRan = random(100)
    local iTotal = 0
    for sAttr, iRate in pairs(mRate) do
        iTotal = iTotal + iRate
        if iRan <= iTotal then
            self:InitMainApply2(sAttr)
            break
        end
    end
end

function CItem:InitMainApply(sAttr)
    self:Dirty()
    local mData = self:GetMainApplyData()
    self.m_mMainApply[sAttr] = mData[sAttr]
end

function CItem:InitMainApply2(sAttr)
    self:Dirty()
    local mData = self:GetMainApplyData()
    local sAttr2 = sAttr .. "2"
    self.m_mMainApply2[sAttr] = mData[sAttr2]
end

function CItem:CreateSubApply()
    local mEnv = {}
    local mData = self:GetSubApplyData()
    local sArgs = mData["sub_attr_rate"]
    local mRate = formula_string(sArgs, mEnv)
    local iRan = random(100)
    local iTotal = 0
    for _, mData in pairs(mRate) do
        local iRate = mData.rate
        local iAmount = mData.amount
        iTotal = iTotal + iRate
        if iRate <= iTotal then
            self:InitSubApply(iAmount)
            break
        end
    end
end

function CItem:InitSubApply(iAmount)
    if iAmount <= 0 then
        return
    end
    self:Dirty()
    local mAttrList = self:TotalAttrNameList()
    for i = 1, iAmount do
        local iLen = #mAttrList
        local iRan = random(iLen)
        local sAttr = mAttrList[iRan]
        local mData = self:GetAttrData(sAttr)
        self.m_mSubApply[sAttr] = mData["sub_init_attr"]
        mAttrList[iRan] = mAttrList[iLen]
        mAttrList[iLen] = nil
    end
end

function CItem:TotalAttrNameList()
    local mData = res["daobiao"]["partner_item"]["equip_attr_info"]
    local mRet = {}

    for sAttr, _ in pairs(mData) do
        table.insert(mRet, sAttr)
    end

    return mRet
end

function CItem:PreCheckPartner(oPlayer)
    local iWield = self:GetData("wield")
    local bRefresh = false
    local iPid,iTraceNo = table.unpack(self:GetData("TraceNo",{}))
    if iWield > 0 then
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iWield)
        if oPartner then
            oPartner:WieldEquip(self, bRefresh)
        else
            record.user("partner_equip", "error", {
                pid = iPid,
                trace = iTraceNo,
                sid = self:SID(),
                parid = iWield,
                reason = "PreCheckPartner,Wield",
                })
            self:SetData("wield", 0)
        end
    end

    local lErrorId = {}
    for iPartnerId, mPlanInfo in pairs(self.m_mPlanInfo) do
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iPartnerId)
        if oPartner then
            for iPlanId, bPlan in pairs(mPlanInfo) do
                if bPlan then
                    oPartner:SetEquipPlan(iPlanId, self, bPlan)
                end
            end
        else
            record.user("partner_equip", "error", {
                pid = iPid,
                trace = iTraceNo,
                sid = self:SID(),
                parid = iPartnerId,
                reason = "PreCheckPartner,EquipPlan",
                })
            table.insert(lErrorId, iPartnerId)
        end
    end
    if next(lErrorId) then
        for _, iPartnerId in ipairs(lErrorId) do
            self.m_mPlanInfo[iPartnerId] = nil
        end
    end
end

function CItem:IsMaxLevel()
    if self:GetData("equip_level") >= self:MaxLevel() then
        return true
    else
        return false
    end
end

function CItem:AddExp(oPlayer, iAddExp, sReason, mArgs)
    local oNotifyMgr = global.oNotifyMgr

    if self:IsMaxLevel() then
        return
    end
    local iExp = self:GetEquipExp()
    local iMaxExp = self:GetMaxExp()
    local iAddExp = min(iAddExp, iMaxExp - iExp)
    if iAddExp > 0 then
        iExp = iExp + iAddExp
        self:SetData("equip_exp", iExp)
        self:CheckUpGrade(oPlayer)
        self:GS2CRefreshPartnerEquipInfo(oPlayer)
        oPlayer:AddTeachTaskProgress(30011,1)
        oPlayer:AddSchedule("promoted_partner")
    end
end

function CItem:CheckUpGrade(oPlayer)
    local mUpGrade = res["daobiao"]["partner_item"]["equip_upgrade"]
    local iStar = self:Star()
    mUpGrade = mUpGrade[iStar]
    local iLevel = self:GetEquipLevel()
    local i = iLevel
    local iPartnerId = self:GetWield()
    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iPartnerId)
    if oPartner then
        self:ClearCPowerApply(oPartner)
    end
    while true do
        local m = mUpGrade[i]
        if not m then
            break
        end
        if self:IsMaxLevel() then
            break
        end
        local iCurMaxExp = m.upgrade_exp
        if self:GetEquipExp() < iCurMaxExp then
            break
        end
        self:OnUpGrade(oPlayer)
        i = i + 1
    end
    if oPartner then
        self:InitCPowerApply(oPartner)
    end
    if i > iLevel and oPartner then
        oPartner:ActivePropChange()
    end
end

function CItem:OnUpGrade(oPlayer)
    local iLevel = self:GetEquipLevel()
    iLevel = iLevel + 1
    self:SetData("equip_level", iLevel)

    local mEnv = {}
    local mData = self:GetItemData()
    local sArgs = mData["upgrade_add"]
    local mArgs = formula_string(sArgs, mEnv)
    for sAttr, _ in pairs(self.m_mMainApply) do
        self:AddMainApply(sAttr, mArgs[sAttr])
    end
    sArgs = mData["upgrade_add2"]
    mArgs = formula_string(sArgs, mEnv)
    for sAttr, _ in pairs(self.m_mMainApply2) do
        self:AddMainApply2(sAttr, mArgs[sAttr])
    end

    if iLevel % 3 == 0 then
        local iAttrCount = extend.Table.size(self.m_mSubApply)
        if iAttrCount == 0 then
            self:CreateNewAttr2SubApply()
        elseif iAttrCount == 4 then
            self:ImproveSubApply()
        else
            if random(100) <= 80 then
                self:CreateNewAttr2SubApply()
            else
                self:ImproveSubApply()
            end
        end
    end
    if iLevel == 15 then
        global.oAssistMgr:PushAchieve(oPlayer:GetPid(), "强化等级15符文数量",{value = 1})
    end
    local sKey = string.format("强化符文%s级次数", iLevel)
    global.oAssistMgr:PushAchieve(oPlayer:GetPid(),sKey,{value = 1})
end

function CItem:ImproveSubApply()
    local mKeyList = extend.Table.keys(self.m_mSubApply)
    local mNotFull = {}
    for _, sAttr in ipairs(mKeyList) do
        local iValue = self:GetSubApply(sAttr)
        local mData = self:GetAttrData(sAttr)
        local iAddValue = iValue - mData.sub_init_attr
        local iAddCount = iAddValue // mData.add_sub_attr
        if iAddCount < 4  then
            table.insert(mNotFull, sAttr)
        end
    end
    if next(mNotFull) then
        local iRan = random(#mNotFull)
        local sAttr = mNotFull[iRan]
        local mData = self:GetAttrData(sAttr)
        self:AddSubApply(sAttr, mData.add_sub_attr)
    end
end

function CItem:CreateNewAttr2SubApply()
    local mAttrNameList = self:TotalAttrNameList()
    local mNotHave = {}
    for _, sAttr in pairs(mAttrNameList) do
        local iValue = self:GetSubApply(sAttr)
        if iValue == 0 then
            table.insert(mNotHave, sAttr)
        end
    end
    if next(mNotHave) then
        local iRan = random(#mNotHave)
        local sAttr = mNotHave[iRan]
        local mData = self:GetAttrData(sAttr)
        self:AddSubApply(sAttr, mData.sub_init_attr)
    end
end

function CItem:Remove(oPlayer, sReason)
    if self:IsWield() then
        local iPartnerId = self:GetWield()
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iPartnerId)
        if oPartner then
            oPartner:UnWieldEquip(self, true)
        end
    end
    for iPartnerId, mPlanInfo in pairs(self.m_mPlanInfo) do
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iPartnerId)
        if oPartner then
            for iPlanId, _ in pairs(mPlanInfo) do
                oPartner:SetEquipPlan(iPlanId, self, false)
            end
        end
    end

    local iAmount = self:GetAmount()
    oPlayer.m_oItemCtrl:AddAmount(self, -iAmount, sReason)
end

function CItem:AddMainApply(sAttr,iValue)
    self:Dirty()
    local iOldVal = self.m_mMainApply[sAttr] or 0
    self.m_mMainApply[sAttr] = iOldVal + iValue
end

function CItem:AddSubApply(sAttr, iValue)
    self:Dirty()
    local iOldVal = self.m_mSubApply[sAttr] or 0
    self.m_mSubApply[sAttr] = iOldVal + iValue
end

function CItem:GetMainApply(sAttr)
    return self.m_mMainApply[sAttr] or 0
end

function CItem:GetSubApply(sAttr)
    return self.m_mSubApply[sAttr] or 0
end

function CItem:AddMainApply2(sAttr, iValue)
    self:Dirty()
    local iOldVal = self.m_mMainApply2[sAttr] or 0
    self.m_mMainApply2[sAttr] = iOldVal + iValue
end

function CItem:GetMainApply2(sAttr)
    return self.m_mMainApply2[sAttr] or 0
end

function CItem:GetApply(sAttr,rDefault)
    rDefault = rDefault or 0
    local iValue = self:GetMainApply(sAttr) + self:GetSubApply(sAttr) + self:GetMainApply2(sAttr)
    if iValue == 0 then
        iValue = rDefault
    end
    return iValue
end

function CItem:GetRatioApply(sAttr, rDefault)
    rDefault = rDefault or 0
    sAttr = sAttr .. "_ratio"
    local iValue = self:GetMainApply(sAttr) + self:GetSubApply(sAttr) + self:GetMainApply2(sAttr)
    if iValue == 0 then
        iValue = rDefault
    end
    return iValue
end

function CItem:SetPlan(iPartnerId, iPlanId, bResult)
    self:Dirty()
    if not bResult then
        bResult = nil
    end
    local mPlanInfo = self.m_mPlanInfo[iPartnerId] or {}
    mPlanInfo[iPlanId] = bResult
    self.m_mPlanInfo[iPartnerId] = mPlanInfo
end

function CItem:ResetApply()
    self:Dirty()
    self.m_mApply = {}
end

function CItem:ValidUse(oPlayer, iAmount)
    local oNotifyMgr = global.oNotifyMgr
    if self:EquipType() == 60 then
        oNotifyMgr:Notify(oPlayer:GetPid(), "经验符文不可穿戴")
        return false
    end
    return true
end

function CItem:IsExpEquip()
    return self:EquipType() == 60
end

function CItem:Use(oPlayer, iPartnerId)
    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iPartnerId)
    if not oPartner then
        return
    end
    if not self:ValidUse(oPlayer, 1) then
        return
    end
    if self:IsWield() then
        self:UnWield(oPartner, oPlayer)
    else
        self:Wield(oPartner)
        oPlayer:AddTeachTaskProgress(30004, 1)
    end
end

function CItem:Wield(oPartner)
    self:Dirty()
    oPartner:WieldEquip(self, true)
end

function CItem:UnWield(oPartner, oPlayer)
    self:Dirty()
    local iPid = oPlayer:GetPid()
    local iTarget = oPartner:ID()
    local iWield = self:GetWield()
    if iTarget == iWield then
        oPartner:UnWieldEquip(self, true)
    else
        local o = oPlayer.m_oPartnerCtrl:GetPartner(iWield)
        if o then
            local oCbMgr = global.oCbMgr
            local sEquip = string.format("{link15,%s,%s,%s}",self:ID(),iPid,self:Name())
            local sPartner = string.format("{link19,%s,%s}",o:ID(),o:GetName())
            local sContent = string.format("%s正在被%s使用，是否将符文穿戴至该伙伴上？",sEquip, sPartner)
            local mData = {
                sContent = sContent,
                sConfirm = "是",
                sCancle = "否",
            }
            local iItemId = self:ID()
            mData = oCbMgr:PackConfirmData(nil, mData)
            local func = function(oPlayer, mData)
                local oEquip = oPlayer:HasItem(iItemId)
                if oEquip then
                    oEquip:UnWield1(oPlayer, mData, iWield, iTarget)
                end
            end
            oCbMgr:SetCallBack(iPid, "GS2CConfirmUI", mData, nil, func)
        else
            record.error("partner equip UnWield error, pid:%s, parid:%s, traceno:%s",iPid,iWield,self:TraceNo())
        end
    end
end

function CItem:UnWield1(oPlayer, mData, iWield, iTarget)
    if mData.answer == 1 then
        if iWield ~= self:GetWield() then
            return
        end
        if iWield == iTarget then
            return
        end
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iWield)
        assert(oPartner, string.format("partner equip err: %s", oPlayer:GetPid()))
        local oTarget = oPlayer.m_oPartnerCtrl:GetPartner(iTarget)
        if oTarget then
            oPartner:UnWieldEquip(self, true)
            oTarget:WieldEquip(self, true)
        end
    end
end

function CItem:IsWield()
    if self:GetData("wield", 0) > 0 then
        return true
    else
        return false
    end
end

function CItem:PackApplyInfo()
    local mApplyData = {}

    local mMainApply = {}
    for sAttr, iValue in pairs(self.m_mMainApply) do
        table.insert(mMainApply, {key = sAttr, value = iValue})
    end
    for sAttr, iValue in pairs(self.m_mMainApply2) do
        table.insert(mMainApply, {key = sAttr, value = iValue})
    end
    mApplyData["main_apply"] = mMainApply

    local mSubApply = {}
    for sAttr, iValue in pairs(self.m_mSubApply) do
        table.insert(mSubApply, {key = sAttr, value = iValue})
    end
    mApplyData["sub_apply"] = mSubApply

    return mApplyData
end

function CItem:PackEquipInfo()
    local mEquipInfo = self:PackApplyInfo()
    mEquipInfo["partner_id"] = self:GetData("wield", 0)
    mEquipInfo["level"] = self:GetData("equip_level", 0)
    mEquipInfo["exp"] = self:GetData("equip_exp", 0)
    mEquipInfo["lock"] = self:GetLock()
    mEquipInfo["in_plan"] = self:GetInPlan()

    return mEquipInfo
end

function CItem:PackItemInfo()
    local mNet = super(CItem).PackItemInfo(self)
    mNet["partner_equip_info"] = self:PackEquipInfo()
    return mNet
end

function CItem:GS2CRefreshPartnerEquipInfo(oPlayer)
    oPlayer:Send("GS2CRefreshPartnerEquipInfo", {
        itemid = self:ID(),
        partner_equip_info = self:PackEquipInfo(),
        })
end

function CItem:GetAllAttrs()
    local mCombine = {}
    for sAttr,iValue in pairs(self.m_mMainApply) do
        mCombine[sAttr] = mCombine[sAttr] or 0
        mCombine[sAttr] = mCombine[sAttr] + iValue
    end
    for sAttr,iValue in pairs(self.m_mMainApply2) do
        mCombine[sAttr] = mCombine[sAttr] or 0
        mCombine[sAttr] = mCombine[sAttr] + iValue
    end
    for sAttr,iValue in pairs(self.m_mSubApply) do
        mCombine[sAttr] = mCombine[sAttr] or 0
        mCombine[sAttr] = mCombine[sAttr] + iValue
    end
    return mCombine
end

function CItem:ClearCPowerApply(oPartner)
    local mCombine = self:GetAllAttrs()
    for sAttr,iValue in pairs(mCombine) do
        oPartner:ExecuteCPower("AddSpecialApply","equip",sAttr,-iValue)
    end
end

function CItem:InitCPowerApply(oPartner)
    local mCombine = self:GetAllAttrs()
    for sAttr,iValue in pairs(mCombine) do
        oPartner:ExecuteCPower("AddSpecialApply","equip",sAttr,iValue)
    end
end