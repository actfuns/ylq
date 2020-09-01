local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local res = require "base.res"
local extend = require "base.extend"
local record = require "public.record"
local colorstring = require "public.colorstring"


local datactrl = import(lualib_path("public.datactrl"))
local partnerdefine = import(service_path("partner/partnerdefine"))
local partnerskill = import(service_path("partner/partnerskill"))
local partnertime = import(service_path("partner/partnertime"))

local min = math.min
local max = math.max
local AWAKE_TYPE = partnerdefine.PARTNER_AWAKE_TYPE

function NewPartner(iPartnerType,mArgs)
    local o = CPartner:New(iPartnerType,mArgs)
    return o
end

PropHelperFunc = {}

function PropHelperFunc.partner_type(oPartner)
    return oPartner:PartnerType()
end

function PropHelperFunc.parid(oPartner)
    return oPartner:ID()
end

function PropHelperFunc.star(oPartner)
    return oPartner:GetStar()
end

function PropHelperFunc.model_info(oPartner)
    return oPartner:GetModelInfo()
end

function PropHelperFunc.name(oPartner)
    return oPartner:GetName()
end

function PropHelperFunc.grade(oPartner)
    return oPartner:GetGrade()
end

function PropHelperFunc.exp(oPartner)
    return oPartner:GetExp()
end

function PropHelperFunc.hp(oPartner)
    return oPartner:GetData("hp")
end

function PropHelperFunc.patahp(oPartner)
    return oPartner.m_oToday:Query("patahp",oPartner:GetAttr("maxhp"))
end

function PropHelperFunc.attack(oPartner)
    return oPartner:GetAttr("attack")
end

function PropHelperFunc.defense(oPartner)
    return oPartner:GetAttr("defense")
end

function PropHelperFunc.critical_ratio(oPartner)
    return oPartner:GetAttr("critical_ratio")
end

function PropHelperFunc.res_critical_ratio(oPartner)
    return oPartner:GetAttr("res_critical_ratio")
end

function PropHelperFunc.cure_critical_ratio(oPartner)
    return oPartner:GetAttr("cure_critical_ratio")
end

function PropHelperFunc.abnormal_attr_ratio(oPartner)
    return oPartner:GetAttr("abnormal_attr_ratio")
end

function PropHelperFunc.res_abnormal_ratio(oPartner)
    return oPartner:GetAttr("res_abnormal_ratio")
end

function PropHelperFunc.critical_damage(oPartner)
    return oPartner:GetAttr("critical_damage")
end

function PropHelperFunc.speed(oPartner)
    return oPartner:GetAttr("speed")
end

function PropHelperFunc.max_hp(oPartner)
    return oPartner:GetAttr("maxhp")
end

function PropHelperFunc.power(oPartner)
    return oPartner:GetPower()
end

function PropHelperFunc.lock(oPartner)
    return oPartner:GetLock()
end

function PropHelperFunc.awake(oPartner)
    return oPartner:GetAwake()
end

function PropHelperFunc.skill(oPartner)
    return oPartner.m_oSkillCtrl:PackNetInfo()
end

function PropHelperFunc.equip_plan_id(oPartner)
    return oPartner:GetData("equip_plan_id", 1)
end

function PropHelperFunc.equip_plan(oPartner)
    return oPartner:PackEquipPlan()
end

function PropHelperFunc.equip_list(oPartner)
    return oPartner:PackEquip()
end

CPartner = {}
CPartner.__index =CPartner
inherit(CPartner,datactrl.CDataCtrl)

function CPartner:New(iPartnerType,mArgs)
    local o = super(CPartner).New(self)
    o:SetData("partner_type", iPartnerType)
    o:InitAttr(mArgs)
    return o
end

function CPartner:InitAttr(mArgs)
    local mData = self:GetPartnerData()

    self:SetData("grade", 1)
    self:SetData("exp", 0)
    self:SetData("lock", 0)
    self:SetData("fight", 0)
    self:SetData("awake", 0)
    self:SetData("star", mArgs.star or mData.star)
    self:SetData("rare", mArgs.rare or mData.rare)
    self:SetData("create_time", get_time())
    self:SetData("name", mArgs.name or mData.name)
    self:SetData("equip_plan_id", 1)
    self:SetData("info", mData)
    self.m_mAttr = {}
    self.m_mAwakeAttr = {}

    self:InitSkill()
    self:InitEquip()

    self.m_oToday = partnertime.NewToday(self:ID())
end

function CPartner:InitSkill()
    self.m_oSkillCtrl = partnerskill.NewSkillCtrl(self)
    self.m_mExpertSkill = {}

    local mInfoData = self:GetData("info")
    local mSkillList = mInfoData.skill_list

    local iUnlockSK = 0
    if self:GetAwakeType() == AWAKE_TYPE.UNLOCK_SKILL then
        iUnlockSK = tonumber(mInfoData["awake_effect"])
    end
    for _, iSk in ipairs(mSkillList) do
        if iSk ~= iUnlockSK then
            local oSk = partnerskill.NewSkill(iSk)
            assert(oSk, string.format("partner skill err: %s, %s", self:PartnerType(), iSk))
            self.m_oSkillCtrl:AddSkill(oSk)
        end
    end
end

function CPartner:InitEquip()
    local mPlanList = {}
    for i = partnerdefine.EQUIP_PLAN_START, partnerdefine.EQUIP_PLAN_END do
        mPlanList[i] = {}
    end

    self.m_mEquip = {}
    self.m_mEquipPlan = mPlanList
    self.m_mEquipSetAttr = {}
end

function CPartner:Release()
    baseobj_safe_release(self.m_oSkillCtrl)
    super(CPartner).Release(self)
end

function CPartner:SetOwner(iPid)
    self:SetInfo("owner", iPid)
end

function CPartner:Load(mData)
    self:SetData("partner_type", mData.partner_type)
    self:SetData("lock", mData.lock)
    self:SetData("star", mData.star)
    self:SetData("name", mData.name)
    self:SetData("hp", mData.hp)
    self:SetData("grade", mData.grade)
    self:SetData("exp", mData.exp)
    self:SetData("traceno", mData.traceno)
    self:SetData("fight", mData.fight)
    self:SetData("create_time", mData.create_time)
    self:SetData("awake", mData.awake)
    self:SetData("equip_plan_id", mData.equip_plan_id or 1)
    self:SetData("auto_skill",mData.auto_skill or 0)

    self.m_oSkillCtrl:Load(mData.skill)
    self.m_oToday:Load(mData.today)

    self:_CheckAwake(true)
end

function CPartner:_CheckAwake(bLoad)
    if self:IsAwake() then
        local mInfoData = self:GetData("info")
        local iType = self:GetAwakeType()
        if iType == AWAKE_TYPE.ADD_SKILL then
            local iSk = tonumber(mInfoData.awake_effect)
            local iSkLevel = 1
            self.m_mExpertSkill[iSk] = iSkLevel
        elseif iType == AWAKE_TYPE.IMPROVE_SKILL then
            local iSk = tonumber(mInfoData.awake_effect)
            local iSkLevel = 1
            self.m_mExpertSkill[iSk] = iSkLevel
        elseif iType == AWAKE_TYPE.UNLOCK_SKILL then
            if not bLoad then
                local iSk = tonumber(mInfoData.awake_effect)
                local oSk = partnerskill.NewSkill(iSk)
                assert(oSk, string.format("partner skill err: %s, %s", self:PartnerType(), iSk))
                self.m_oSkillCtrl:AddSkill(oSk)
            end
        elseif iType == AWAKE_TYPE.ADD_ATTR then
            --已删掉该类型
        end
        local sEffect = mInfoData.awake_effect_attr
        if sEffect and sEffect ~= "" then
            local mEffect = formula_string(sEffect, {})
            for sAttr, iVal in pairs(mEffect) do
                local i =  self.m_mAwakeAttr[sAttr] or 0
                self.m_mAwakeAttr[sAttr] = i + iVal
            end
        end
        local sEffect = mInfoData.awake_attr
        if sEffect and sEffect ~= "" then
            local mEffect = formula_string(sEffect, {})
            for sAttr, iVal in pairs(mEffect) do
                local i =  self.m_mAwakeAttr[sAttr] or 0
                self.m_mAwakeAttr[sAttr] = i + iVal
            end
        end
    end
end

function CPartner:Save()
    local mData = {}
    mData["partner_type"] = self:GetData("partner_type")
    mData["lock"] = self:GetData("lock")
    mData["star"] = self:GetData("star")
    mData["name"] = self:GetData("name")
    mData["hp"] = self:GetData("hp")
    mData["grade"] = self:GetData("grade")
    mData["exp"] = self:GetData("exp")
    mData["traceno"] = self:GetData("traceno")
    mData["fight"] = self:GetData("fight")
    mData["create_time"] = self:GetData("create_time")
    mData["awake"] = self:GetData("awake")
    mData["equip_plan_id"] = self:GetData("equip_plan_id")
    mData["auto_skill"] = self:GetData("auto_skill")

    mData["skill"] = self.m_oSkillCtrl:Save()
    mData["today"] = self.m_oToday:Save()

    return mData
end

function CPartner:GetPartnerData()
    local res = require "base.res"
    local iPartnerType = self:GetData("partner_type")
    local mData = res["daobiao"]["partner"]["partner_info"][iPartnerType]
    assert(mData, string.format("partnerdata err:%s", iPartnerType))
    return mData
end

function CPartner:PartnerType()
    return self:GetData("partner_type")
end

function CPartner:ID()
    local parid = self.m_iID
    if not parid then
        local pid,parid = table.unpack(self:GetData("traceno",{}))
        self.m_iID = parid
    end
    return self.m_iID
end

function CPartner:GetName()
    return self:GetData("name")
end

function CPartner:Race()
    return self:GetData("info")["race"]
end

function CPartner:Rare()
    return self:GetData("info")["rare"]
end

function CPartner:GetModelInfo()
    local mRet = {}
    mRet.shape = self:GetData("info")["shape"]
    return mRet
end

function CPartner:GetStar()
    return tonumber(self:GetData("star"))
end

function CPartner:GetGrade()
    return self:GetData("grade")
end

function CPartner:GetExp()
    return self:GetData("exp")
end

function CPartner:GetPower()
    local oPubMgr = global.oPubMgr
    local iPower = 0
    local mPower = self:GetPowerData()
    local mAttrName = res["daobiao"]["attrname"]
    for sAttr, mAttr in pairs(mAttrName) do
        local iMul = mPower[sAttr] / 100
        iPower = iPower + (self:GetAttr(sAttr) - oPubMgr:PowerBaseVal(sAttr)) * iMul
    end
    return math.floor(iPower)
end

function CPartner:GetLock()
    return self:GetData("lock")
end

function CPartner:GetAwake()
    return self:GetData("awake")
end

function CPartner:GetEffectType()
    return self:GetData("info")["effect_type"]
end

function CPartner:GetAwakeType()
    return self:GetData("info")["awake_type"]
end

function CPartner:GetEquipPlanID()
    return self:GetData("equip_plan_id")
end

function CPartner:GetPerformList()
    local mSkill = self.m_oSkillCtrl:GetAllPartnerSkill()
    local mPerform = {}
    for iSk, oSk in pairs(mSkill) do
        mPerform[iSk] = oSk:Level()
    end

    for iSk, iLevel in pairs(self.m_mExpertSkill) do
        mPerform[iSk] = iLevel
    end
    return mPerform
end

function CPartner:Setup()
    local mEnv = {
        lv = self:GetGrade(),
    }
    local mAttr = {"maxhp","attack","defense","critical_ratio","res_critical_ratio","critical_damage","cure_critical_ratio","abnormal_attr_ratio","res_abnormal_ratio","speed"}
    local mAttrData = self:GetAttrData()
    for _,sAttr in pairs(mAttr) do
        local sApply = mAttrData[sAttr]
        local iValue = formula_string(sApply,mEnv)
        self.m_mAttr[sAttr] = iValue
    end
    local iHp = self.m_mAttr["hp"]
    if not iHp or iHp > self.m_mAttr["maxhp"] then
        self.m_mAttr["hp"] = self.m_mAttr["maxhp"]
    end
end

function CPartner:GetAttr(sAttr)
    local iValue = self:GetBaseAttr(sAttr) * (10000 + self:GetBaseRatio(sAttr)) / 10000 + math.floor(self:GetAttrAdd(sAttr))
    iValue = math.floor(iValue)
    return iValue
end

function CPartner:GetBaseAttr(sAttr)
    local iBaseValue = self.m_mAttr[sAttr] or 0
    return math.floor(iBaseValue)
end

function CPartner:GetBaseRatio(sAttr)
    local iRatio = 0
    iRatio = iRatio + self:GetRatioApply(sAttr)
    iRatio = iRatio + self.m_oSkillCtrl:GetRatioApply(sAttr)
    iRatio = iRatio + self:GetEquipRatioApply(sAttr)
    iRatio = iRatio + self:GetEquipSetRatioApply(sAttr)
    iRatio = iRatio + self:GetAwakeRatioApply(sAttr)
    return iRatio
end

function CPartner:GetAttrAdd(sAttr)
    local iValue = 0
    iValue = iValue + math.floor(self:GetApply(sAttr))
    iValue = iValue + math.floor(self.m_oSkillCtrl:GetApply(sAttr))
    iValue = iValue + math.floor(self:GetEquipApply(sAttr))
    iValue = iValue + math.floor(self:GetEquipSetApply(sAttr))
    iValue = iValue + math.floor(self:GetAwakeApply(sAttr))
    return iValue
end

function CPartner:GetRatioApply(sAttr)
    local oPlayer = self:GetOwner()
    if not oPlayer then
        return 0
    end
    return oPlayer.m_oPartnerCtrl:GetRatioApply(sAttr)
end

function CPartner:GetApply(sAttr)
    local oPlayer = self:GetOwner()
    if not oPlayer then
        return 0
    end
    return oPlayer.m_oPartnerCtrl:GetApply(sAttr)
end

function CPartner:GetEquipApply(sAttr)
    local iValue = 0
    for iPos, oEquip in pairs(self.m_mEquip) do
        iValue = iValue + oEquip:GetApply(sAttr)
    end
    return iValue
end

function CPartner:GetEquipRatioApply(sAttr)
    local iValue = 0
    for iPos, oEquip in pairs(self.m_mEquip) do
        iValue = iValue + oEquip:GetRatioApply(sAttr)
    end
    return iValue
end

function CPartner:GetEquipSetApply(sAttr)
    return self.m_mEquipSetAttr[sAttr] or 0
end

function CPartner:GetEquipSetRatioApply(sAttr)
    sAttr = sAttr .. "_ratio"
    return self.m_mEquipSetAttr[sAttr] or 0
end

function CPartner:GetAwakeApply(sAttr)
    return self.m_mAwakeAttr[sAttr] or 0
end

function CPartner:GetAwakeRatioApply(sAttr)
    sAttr = sAttr .. "_ratio"
    return self.m_mAwakeAttr[sAttr] or 0
end

function CPartner:GetOwner()
    local iPid = self:GetInfo("pid")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    return oPlayer
end

function CPartner:GetStarData()
    local iStar = self:GetStar()
    local mStar = res["daobiao"]["partner"]["star"][iStar]
    assert(mStar, string.format("partner star err: %s, %s, %s", self:GetInfo("pid"), self:ID(), iStar))
    return mStar
end

function CPartner:GetAwakeCost()
    local mInfoData = self:GetData("info")
    return mInfoData.awake_cost
end

function CPartner:GetAwakeCoinCost()
    local mInfoData = self:GetData("info")
    return mInfoData.awake_coin_cost
end

function CPartner:GetEatExp()
    local mEatExpData = res["daobiao"]["partner"]["eat_exp"]
    local iEffectType = self:GetEffectType()
    local iGrade = self:GetGrade()
    mEatExpData = mEatExpData[iEffectType][iGrade]
    assert(mEatExpData, string.format("partner eat exp data err: %s, %s, %s", self:GetInfo("pid"), iEffectType, self:ID(), iGrade))
    return mEatExpData["add_exp"]
end

function CPartner:GetAttrData(iStar)
    local iStar =  iStar or self:GetStar()
    local iPartnerType = self:PartnerType()
    local mAttrData = res["daobiao"]["partner"]["partner_attr"]
    --debug assert
    assert(mAttrData[iPartnerType], string.format("partner err:  %s, %s", iPartnerType, iStar))
    local mData = mAttrData[iPartnerType][iStar]
    assert(mData, string.format("partner err: %s, %s, %s", self:GetInfo("pid"), iPartnerType, iStar))
    return mData
end

function CPartner:GetPowerData()
    local iType = self:PartnerType()
    local mPower = res["daobiao"]["partner"]["convert_power"][iType]
    local iPid = self:GetInfo("pid")
    assert(mPower, string.format("partner power err: %s, %s, %s", iPid, self:ID(), iType))

    return mPower
end

function CPartner:GetUpGradeCostData()
    local mCostData = res["daobiao"]["partner"]["cost"]
    return mCostData[1]
end

function CPartner:GetUpGradeData()
    local mUpGrade = res["daobiao"]["partner"]["upgrade"]
    return mUpGrade
end

function CPartner:GetRareData()
    local iRare = self:GetData("info")["rare"]
    local mRare = res["daobiao"]["partner"]["rare"][iRare]
    assert(mRare, string.format("partner rare data err: %s, %s", self:PartnerType(), self:ID()))
    return mRare
end

function CPartner:IsGradeLimit()
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local iPid = self:GetInfo("pid")
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return false
    end
    local iPartnerGrade = self:GetGrade()
    local mStarData = self:GetStarData()
    if iPartnerGrade >= mStarData.limit_level then
        local iStar = self:GetStar()
        if iStar < 5 then
            oNotifyMgr:Notify(iPid, "伙伴已达到最大等级，升星后可继续获得经验")
        end
        return true
    end

    return false
end

function CPartner:GetLimitGrade()
    local oWorldMgr = global.oWorldMgr

    local iPid = self:GetInfo("pid")
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local mStarData = self:GetStarData()
    local iStarLimitGrade = mStarData.limit_level

    return iStarLimitGrade
end

function CPartner:GetMaxExp()
    local iLimitGrade = self:GetLimitGrade() - 1
    local mUpGrade = self:GetUpGradeData()
    mUpGrade = mUpGrade[iLimitGrade]
    assert(mUpGrade, "partner upgrade data err: %s, %s, %s", self:GetInfo("pid"), self:ID(), iLimitGrade)
    local iMaxExp = mUpGrade.partner_exp
    return iMaxExp
end

function CPartner:ValidUpgrade()
    return true
end

function CPartner:RewardExp(iVal, sReason, mArgs)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    mArgs = mArgs or {}
    assert(iVal > 0, string.format("partner RewardExp err: %s, %s, %s", self:GetInfo("pid"), self:ID(), iVal))

    local iPid = self:GetInfo("pid")
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not  oPlayer then
        return
    end
    if not self:ValidUpgrade() then
        return
    end
    if self:IsGradeLimit() then
        return
    end

    local iExp = self:GetData("exp")
    local iMaxExp = self:GetMaxExp(oPlayer)
    local iAddExp = min(iVal, iMaxExp - iExp)
    if iAddExp > 0 then
        self:Dirty()

        self:SetData("exp", iExp + iAddExp)
        self:CheckUpGrade()
        self:PropChange("exp")
        if not mArgs.cancel_tip then
            local sMsg = string.format("[%s]获得#exp经验", self:GetName())
            local mNotifyArgs = {
                exp = iAddExp,
            }
            if mArgs.tips then
                sMsg = mArgs.tips
            end
            oNotifyMgr:BroadCastNotify(iPid,{"GS2CNotify"},sMsg,mNotifyArgs)
        end
    end
end

function CPartner:CheckUpGrade()
    local oTeamMgr = global.oTeamMgr

    local mUpGrade = self:GetUpGradeData()
    local iGrade = self:GetGrade()
    local i = iGrade
    while true do
        local m = mUpGrade[i]
        if not m then
            break
        end
        local iGradeExp = m.partner_exp
        if self:GetExp() < iGradeExp then
            break
        end
        self:OnUpGrade()
        i = i + 1
    end
    if i > iGrade then
        self:ActivePropChange("grade")
        local mArgs = {}
        local iPid = self:GetInfo("pid")
        mArgs["grade"] = self:GetGrade()
        mArgs["parid"] = self:ID()
        oTeamMgr:OnMemPartnerInfoChange(iPid,mArgs)
    end
end

function CPartner:OnUpGrade()
    local iNextGrade = self:GetGrade() + 1
    self:SetData("grade", iNextGrade)
    self:Setup()
    self:SetData("hp", self:GetAttr("maxhp"))
    self.m_mAttr["hp"] = self:GetData("hp")
end

function CPartner:IsLimitStar()
    if self:GetStar() >= 5 then
        return true
    else
        return false
    end
end

function CPartner:IsStarLimitGrade()
    local mStar = self:GetStarData()
    local iStarLimitGrade = mStar.limit_level
    if self:GetGrade() >= mStar.limit_level then
        return true
    else
        return false
    end
end

function CPartner:IncreaseStar(iVal)
    self:Dirty()

    assert(iVal > 0, string.format("partner IncreaseStar err: %s, %s, %s", self:GetInfo("pid"), self:ID(), iVal))
    local iStar = self:GetData("star")
    iVal = iStar + iVal
    self:SetData("star", min(iVal, 5))
    self:Setup()
    self:ActivePropChange("star")
end

function CPartner:IsLock()
    if self:GetLock() == 1 then
        return true
    else
        return false
    end
end

function CPartner:SetLock(iLock)
    self:Dirty()

    local oNotifyMgr = global.oNotifyMgr
    local iPid = self:GetInfo("pid")
    local iOldLock = self:GetData("lock")
    if iOldLock ~= iLock then
        self:SetData("lock", iLock)
        if iLock == 0 then
            oNotifyMgr:Notify(iPid, "已解锁")
        else
            oNotifyMgr:Notify(iPid, "已上锁")
        end
        self:PropChange("lock")
    end
end

function CPartner:SetName(sName)
    local oTeamMgr = global.oTeamMgr

    self:Dirty()
    self:SetData("name", sName)
    self:PropChange("name")

    local iPid = self:GetInfo("pid")
    local mArgs = {}
    mArgs["parid"] = self:ID()
    mArgs["name"] = self:GetName()
    oTeamMgr:OnMemPartnerInfoChange(iPid, mArgs)
end

function CPartner:SetModelInfo(mModel)
    local oTeamMgr = global.oTeamMgr

    if mModel then
        self:Dirty()
        self:PropChange("model_info")

        local iPid = self:GetInfo("pid")
        local mArgs = {}
        mArgs["parid"] = self:ID()
        mArgs["name"] = self:GetName()
        oTeamMgr:OnMemPartnerInfoChange(iPid, mArgs)
    end
end

function CPartner:SetFight(iPos)
    local iPid = self:GetInfo("pid")
    local iParid = self:ID()
    assert(iPos >= 0, string.format("partner err: %s, %s, %s", iPid, iParid, iPos))
    self:SetData("fight", iPos)
end

function CPartner:GetFight()
    return self:GetData("fight", 0)
end

function CPartner:SyncTeamPartnerInfo()
    local oTeamMgr = global.oTeamMgr
    local mArgs = {}
    local iPos = self:GetFight()
    local iPid = self:GetInfo("pid")
    mArgs["parid"] = self:ID()
    mArgs["pos"] = iPos
    if iPos > 0 then
        mArgs["name"] = self:GetName()
        mArgs["grade"] = self:GetGrade()
        mArgs["model_info"] = self:GetModelInfo()
    end
    oTeamMgr:OnMemPartnerInfoChange(iPid, mArgs)
end

function CPartner:IsAwake()
    if self:GetAwake() > 0 then
        return true
    else
        return false
    end
end

function CPartner:ValidAwake()
    local oNotifyMgr = global.oNotifyMgr
    local iPid = self:GetInfo("pid")
    if self:IsAwake() then
        oNotifyMgr:Notify(iPid, "伙伴已觉醒")
        return false
    end
    return true
end

function CPartner:Awake(oPlayer)
    self:Dirty()

    self:SetData("awake", 1)
    self:_CheckAwake()
    self:ActivePropChange("awake", "skill")
    oPlayer:Send("GS2CAwakePartner", {
        partnerid = self:ID(),
        })
end

function CPartner:UpGradeSkill(iSkillPoint)
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr

    local mUnFullSkill = self.m_oSkillCtrl:GetUnFullLevelSkill()
    if #mUnFullSkill == 0 then
        return
    end

    local iLen = #mUnFullSkill
    while (iLen > 0 and iSkillPoint > 0) do
        local iRan = math.random(iLen)
        local oSk = mUnFullSkill[iRan]
        oSk:SkillUnEffect()
        local iLevel = oSk:Level() + 1
        oSk:SetLevel(iLevel)
        oSk:SkillEffect()
        if iLevel >= oSk:LimitLevel() then
            mUnFullSkill[iRan] = mUnFullSkill[iLen]
            mUnFullSkill[iLen] = nil
            iLen = iLen - 1
        end
        iSkillPoint = iSkillPoint - 1
    end
    self:ActivePropChange("skill")
end

function CPartner:GetEquipPlan(iPlanId)
    return self.m_mEquipPlan[iPlanId]
end

--符文套装
function CPartner:EffectEquipSet()
    local mAttr = self.m_mEquipSetAttr
    local mSetInfo = {}
    for iPos, oEquip in pairs(self.m_mEquip) do
        local iType = oEquip:EquipType()
        local iSetCount = mSetInfo[iType] or 0
        mSetInfo[iType] = iSetCount + 1
    end
    local mSetData =  res["daobiao"]["partner_item"]["equip_set"]
    for iType, iCount in pairs(mSetInfo) do
        local mData = mSetData[iType]
        local sTwoSet = mData.two_set_buff
        local iSk = mData.four_set_skill
        local iSkLevel = 1
        local mTwoSet = formula_string(sTwoSet, {})
        -- if iCount >= 6 then
        --     for sAttr, iVal in pairs(mTwoSet) do
        --         mAttr[sAttr] = (mAttr[sAttr] or 0) + (iVal * 2)
        --     end
        --     self.m_mExpertSkill[iSk] = iSkLevel
        -- elseif iCount >= 4 then
        --     for sAttr, iVal in pairs(mTwoSet) do
        --         mAttr[sAttr] = (mAttr[sAttr] or 0) + iVal
        --     end
        --     self.m_mExpertSkill[iSk] = iSkLevel
        -- elseif iCount >= 2 then
        --     for sAttr, iVal in pairs(mTwoSet) do
        --         mAttr[sAttr] = (mAttr[sAttr] or 0) + iVal
        --     end
        -- end
        if iCount >= 4 then
            self.m_mExpertSkill[iSk] = iSkLevel
        end
        if iCount >= 2 then
            for sAttr, iVal in pairs(mTwoSet) do
                mAttr[sAttr] = (mAttr[sAttr] or 0) + iVal
            end
        end
    end
end

function CPartner:UnEffectEquipSet()
    local mAttr = self.m_mEquipSetAttr
    local mSetInfo = {}
    for iPos, oEquip in pairs(self.m_mEquip) do
        local iType = oEquip:EquipType()
        local iSetCount = mSetInfo[iType] or 0
        mSetInfo[iType] = iSetCount + 1
    end
    local mSetData = res["daobiao"]["partner_item"]["equip_set"]
    for iType, iCount in pairs(mSetInfo) do
        local mData = mSetData[iType]
        local sTwoSet = mData.two_set_buff
        local mTwoSet = formula_string(sTwoSet, {})
        if iCount >= 4 then
            -- for sAttr, iVal in pairs(mTwoSet) do
            --     mAttr[sAttr] = mAttr[sAttr] - (iVal * 2)
            -- end
            local iSk = mData.four_set_skill
            self.m_mExpertSkill[iSk] = nil
        end
        if iCount >= 2 then
            for sAttr, iVal in pairs(mTwoSet) do
                mAttr[sAttr] = mAttr[sAttr]  - iVal
            end
        end
    end
end

function CPartner:WieldEquip(oEquip, bRefresh)
    self:Dirty()
    local oWorldMgr = global.oWorldMgr

    local iPid = self:GetInfo("pid")
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iPos = oEquip:EquipPos()
    local oOldEquip = self.m_mEquip[iPos]
    if oOldEquip then
        self:UnWieldEquip(oOldEquip)
    end
    self:UnEffectEquipSet()
    oEquip:SetWield(self:ID())
    self.m_mEquip[iPos] = oEquip
    self:EffectEquipSet()
    oEquip:GS2CRefreshPartnerEquipInfo(oPlayer)
    self:SetData("equip_plan_id", 0)
    if bRefresh then
        self:ActivePropChange("equip_list", "equip_plan_id")
    end
end

function CPartner:UnWieldEquip(oEquip, bRefresh)
    self:Dirty()
    local oWorldMgr = global.oWorldMgr

    local iPid = self:GetInfo("pid")
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iPos = oEquip:EquipPos()
    local oOldEquip = self.m_mEquip[iPos]
    if oOldEquip:ID() == oEquip:ID() then
        self:UnEffectEquipSet()
        oEquip:SetWield(0)
        self.m_mEquip[iPos] = nil
        self:EffectEquipSet()
        oEquip:GS2CRefreshPartnerEquipInfo(oPlayer)
        self:SetData("equip_plan_id", 0)
        if bRefresh then
            self:ActivePropChange("equip_list", "equip_plan_id")
        end
    end
end

function CPartner:SaveEquipPlan(oPlayer, iPlanId, mPlan, bRefresh)
    local iPartnerId = self:ID()
    local mOldPlan = self:GetEquipPlan(iPlanId)
    for iPos, oEquip in pairs(mOldPlan) do
        oEquip:SetPlan(iPartnerId, iPlanId, nil)
        oEquip:GS2CRefreshPartnerEquipInfo(oPlayer)
    end
    for iPos, oEquip in pairs(mPlan) do
        oEquip:SetPlan(iPartnerId, iPlanId, true)
        oEquip:GS2CRefreshPartnerEquipInfo(oPlayer)
    end
    self.m_mEquipPlan[iPlanId] = mPlan
    self:SetData("equip_plan_id", 0)
    if bRefresh then
        self:PropChange("equip_plan", "equip_plan_id")
    end
end

function CPartner:SetEquipPlan(iPlanId, oEquip, bPlan)
    local mPlan = self:GetEquipPlan(iPlanId)
    if not mPlan then
        return
    end
    local iId = self:ID()
    local iPos = oEquip:EquipPos()
    local oOldEquip = mPlan[iPos]
    if oOldEquip then
        oOldEquip:SetPlan(iId, iPlanId, nil)
    end

    if bPlan then
        mPlan[iPos] = oEquip
    else
        mPlan[iPos] = nil
    end
    oEquip:SetPlan(iId, iPlanId, bPlan)
    self:PropChange("equip_plan")
end

function CPartner:OnRemove()
    local oWorldMgr = global.oWorldMgr
    local oNotifyMgr = global.oNotifyMgr
    local iId = self:ID()
    local iPid = self:GetInfo("pid")
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    for iPos ,oEquip in pairs(self.m_mEquip) do
        oEquip:SetWield(0)
        oEquip:GS2CRefreshPartnerEquipInfo(oPlayer)
    end
    for iPlanId, mPlan in pairs(self.m_mEquipPlan) do
        for iPos, oEquip in pairs(mPlan) do
            oEquip:SetPlan(iId, iPlanId, nil)
        end
    end
end

function CPartner:ActivePropChange(...)
    self:PropChange("max_hp","attack","defense","hp","critical_ratio","res_critical_ratio","critical_damage",
        "cure_critical_ratio","abnormal_attr_ratio","res_abnormal_ratio","speed","power",...)
    local oPlayer = self:GetOwner()
    oPlayer.m_oPartnerCtrl:AdjustTop4Power(self)
end

function CPartner:PropChange(...)
    local l = table.pack(...)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:SetPartnerPropChange(self:GetInfo("pid"), self:ID(), l)
end

function CPartner:ClientPropChange(oPlayer, m)
    local mInfo = self:PackNetInfo(m)
    oPlayer:Send("GS2CPartnerPropChange", {
        partnerid = self:ID(),
        partner_info = mInfo,
    })
end

function CPartner:PackNetInfo(m)
    local mRet = {}
    if not m then
        m = PropHelperFunc
    end
    for k, _ in pairs(m) do
        local f = assert(PropHelperFunc[k], string.format("RoleInfo fail f get %s", k))
        mRet[k] = f(self)
    end
    return net.Mask("base.Partner", mRet)
end

function CPartner:PackEquipPlan()
    local mNet = {}
    for iPlanId, mPlan in ipairs(self.m_mEquipPlan) do
        local mData = {}
        for iPos, oEquip in pairs(mPlan) do
            table.insert(mData, oEquip:ID())
        end
        table.insert(mNet, {
            plan_id = iPlanId,
            itemid_list = mData,
            })
    end

    return mNet
end

function CPartner:PackEquip()
    local mNet = {}
    for iPos, oEquip in pairs(self.m_mEquip) do
        table.insert(mNet, oEquip:ID())
    end

    return mNet
end

function CPartner:PackWarInfo()
    return {
        type = self:PartnerType(),
        parid = self:ID(),
        star = self:GetStar(),
        model_info = self:GetModelInfo(),
        name = self:GetName(),
        grade = self:GetGrade(),
        max_hp = self:GetAttr("maxhp"),
        hp = self:GetAttr("maxhp"),
        attack = self:GetAttr("attack"),
        defense = self:GetAttr("defense"),
        critical_ratio = self:GetAttr("critical_ratio"),
        res_critical_ratio = self:GetAttr("res_critical_ratio"),
        critical_damage = self:GetAttr("critical_damage"),
        cure_critical_ratio = self:GetAttr("cure_critical_ratio"),
        abnormal_attr_ratio = self:GetAttr("abnormal_attr_ratio"),
        res_abnormal_ratio = self:GetAttr("res_abnormal_ratio"),
        speed = self:GetAttr("speed"),
        power = self:GetPower(),
        perform = self:GetPerformList(),
        awake = self:IsAwake(),
        auto_skill = self:GetAutoSkill(),
        double_attack_suspend = self:IsDoubleAttackSuspend(),
        effect_type = self:GetEffectType(),
    }
end

function CPartner:PackPataWarInfo()
    local data = self:PackWarInfo()
    local iHp = self.m_oToday:Query("patahp",self:GetAttr("maxhp"))
    data.hp = iHp
    return data
end

function CPartner:GetAutoSkill()
    return self:GetData("auto_skill",0)
end

function CPartner:SetAutoSkill(iAutoSkill)
    self:SetData("auto_skill",iAutoSkill)
end

function CPartner:IsDoubleAttackSuspend()
    return true
end

function CPartner:UnDirty()
    super(CPartner).UnDirty(self)
    self.m_oSkillCtrl:UnDirty()
end

function CPartner:IsDirty()
    local bDirty = super(CPartner).IsDirty(self)
   if bDirty then
        return true
    end
    if self.m_oSkillCtrl:IsDirty() then
        return true
    end
    return false
end

function CPartner:TestOP(oPlayer)
    record.info("gtxie partner TestOP")
    table_print(self.m_mExpertSkill)
    table_print(self:GetPerformList())
end