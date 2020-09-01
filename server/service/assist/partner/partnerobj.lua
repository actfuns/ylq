local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local res = require "base.res"
local extend = require "base.extend"
local record = require "public.record"
local interactive = require "base.interactive"
local fstring = require "public.colorstring"

local cpower = import(lualib_path("public.cpower"))
local datactrl = import(lualib_path("public.datactrl"))
local partnerdefine = import(service_path("partner.partnerdefine"))
local skillobj = import(service_path("partner.partnerskill"))
local timectrl = import(lualib_path("public.timectrl"))
local gamedefines = import(lualib_path("public.gamedefines"))
local loaditem = import(service_path("item/loaditem"))
local itemdefines = import(service_path("item/itemdefines"))

local min = math.min
local max = math.max

local AWAKE_TYPE = gamedefines.PARTNER_AWAKE_TYPE
local MAX_STAR = 10

OPEN_CPOWER = 1

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

function PropHelperFunc.status(oPartner)
    return oPartner:GetStatus()
end

function PropHelperFunc.power_rank(oPartner)
    return oPartner:GetPowerRank()
end

function PropHelperFunc.amount(oPartner)
    return oPartner:GetAmount()
end

function PropHelperFunc.souls(oPartner)
    return oPartner:PackSoulList()
end

function PropHelperFunc.soul_type(oPartner)
    return oPartner:GetSoulType()
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
    self.m_cPower = cpower.NewCPower()

    self:SetData("grade", 1)
    self:SetData("exp", 0)
    self:SetData("lock", 0)
    self:SetData("fight", 0)
    self:SetData("awake", 0)
    self:SetData("star", mArgs.star or mData.star)
    self:SetData("rare", mData.rare)
    self:SetData("create_time", get_time())
    self:SetData("name", mArgs.name or mData.name)
    -- self:SetData("equip_plan_id", 1)
    self:SetData("soul_type", 0)
    self.m_mAttr = {}
    self.m_mAwakeAttr = {}
    self.m_mSoul = {}

    self:InitSkill()
    self:InitEquip()
    self:InitModelInfo()

    self.m_oToday = timectrl.CToday:New(self:ID())
end

function CPartner:ExecuteCPower(sFun,...)
    local oSum = self.m_cPower
    local func = oSum[sFun]
    func(oSum,...)
end

function CPartner:InitSkill()
    self.m_oSkillCtrl = skillobj.NewSkillCtrl(self)
    self.m_mExpertSkill = {}

    local mInfoData = self:GetPartnerData()
    local mSkillList = mInfoData.skill_list

    local iUnlockSK = 0
    if self:GetAwakeType() == AWAKE_TYPE.UNLOCK_SKILL then
        iUnlockSK = tonumber(mInfoData["awake_effect"])
    end
    for _, iSk in ipairs(mSkillList) do
        if iSk ~= iUnlockSK then
            local oSk = skillobj.NewSkill(iSk)
            assert(oSk, string.format("partner skill err: %s, %s", self:PartnerType(), iSk))
            self.m_oSkillCtrl:AddSkill(oSk)
        end
    end
    self:ExecuteCPower("SetSklv",self.m_oSkillCtrl:GetTotalSkLv())
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

function CPartner:InitModelInfo()
    local iSkinSid = self:GetPartnerData().skin
    local oSkin = loaditem.GetItem(iSkinSid)
    self:SetData("model_info", oSkin:PackModelInfo())
end

function CPartner:Release()
    self.m_mExpertSkill = nil
    self.m_mEquip = nil
    self.m_mEquipPlan = nil
    self.m_mEquipSetAttr = nil
    baseobj_safe_release(self.m_oSkillCtrl)
    baseobj_safe_release(self.m_cPower)
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
    self:SetData("model_info", mData.model_info or self:InitModelInfo())
    self:SetData("equal_lock",mData.equal_lock)
    self:SetData("status", mData.status or 0)
    self:SetData("power_rank", mData.power_rank or 0)
    self:SetData("title", mData.title or {})
    -- self:SetData("amount", mData.amount or 1)
    self:SetData("soul_type", mData.soul_type or 0)
    self:SetData("test_attr", mData.test_attr or {})
    self.m_oSkillCtrl:Load(mData.skill)
    self.m_oToday:Load(mData.today)

    self:_CheckAwake(true)
    self:LoadFinish()
end

function CPartner:LoadFinish()
    self:ExecuteCPower("SetSklv",self.m_oSkillCtrl:GetTotalSkLv())
end

function CPartner:_CheckAwake(bLoad)
    if self:IsAwake() then
        local mInfoData = self:GetPartnerData()
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
                local oSk = skillobj.NewSkill(iSk)
                assert(oSk, string.format("partner skill err: %s, %s", self:PartnerType(), iSk))
                self.m_oSkillCtrl:AddSkill(oSk)
                self:ExecuteCPower("SetSklv",self.m_oSkillCtrl:GetTotalSkLv())
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
                self:ExecuteCPower("AddSpecialApply","awake",sAttr,iVal)
            end
        end
        local mAwake = self:GetAwakeData()
        local mAttr = {"maxhp","attack","defense","hp","critical_ratio","res_critical_ratio","critical_damage",
        "cure_critical_ratio","abnormal_attr_ratio","res_abnormal_ratio","speed"}
        for _, sAttr in ipairs(mAttr) do
            local iVal = mAwake[sAttr] or 0
            if iVal > 0 then
                local iHave =  self.m_mAwakeAttr[sAttr] or 0
                self.m_mAwakeAttr[sAttr] = iHave + iVal
                self:ExecuteCPower("AddSpecialApply","awake",sAttr,iVal)
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
    mData["model_info"] = self:GetData("model_info")
    mData["status"] = self:GetData("status")
    mData["test_attr"] = self:GetData("test_attr")
    mData["power_rank"] = self:GetData("power_rank", 0)
    mData["title"] = self:GetTitleList()
    -- mData["amount"] = self:GetAmount()
    mData["soul_type"] =self:GetSoulType()

    mData["skill"] = self.m_oSkillCtrl:Save()
    mData["today"] = self.m_oToday:Save()
    -- mData["equal_lock"] = self:GetData("equal_lock")

    return mData
end

function CPartner:GetPartnerData()
    local res = require "base.res"
    local iPartnerType = self:GetData("partner_type")
    local mData = res["daobiao"]["partner"]["partner_info"][iPartnerType]
    assert(mData, string.format("partnerdata err:%s", iPartnerType))
    return mData
end

function CPartner:GetAwakeData()
    local res = require "base.res"
    local iPartnerType = self:GetData("partner_type")
    local mData = res["daobiao"]["partner"]["partner_awake"][iPartnerType]
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
    return parid
end

function CPartner:SkinSid()
    return self:GetModelInfo().skin
end

function CPartner:GetName()
    return self:GetData("name")
end

function CPartner:GetDefaultName()
    return self:GetPartnerData()["name"]
end

function CPartner:Race()
    return self:GetPartnerData()["race"]
end

function CPartner:Rare()
    return self:GetPartnerData()["rare"]
end

function CPartner:GetModelInfo()
    return self:GetData("model_info")
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

function CPartner:GetAmount()
    return self:GetData("amount", 1)
end

function CPartner:AddAmount(iAdd, reason, mArgs)
    local iHave = min(self:GetAmount() + iAdd, 99999999)
    self:SetData("amount", iHave)
end

function CPartner:GetSoulType()
    return self:GetData("soul_type", 0)
end

function CPartner:SetSoulType(iSoulType)
    self:SetData("soul_type", iSoulType)
end

function CPartner:IsMerge()
    return table_in_list(partnerdefine.MERGE_PARTNER, self:PartnerType())
end

function CPartner:GetPower()
    if OPEN_CPOWER == 1 then
        return self:GetCPower()
    end
    return self:GetLPower()
end

function CPartner:GetLPower()
    local iPower = 0
    local mPower = self:GetPowerData()
    local mAttrName = res["daobiao"]["attrname"]
    for sAttr, mAttr in pairs(mAttrName) do
        local iMul = mPower[sAttr] / 100
        iPower = iPower + (self:GetAttr(sAttr) - self:PowerBaseVal(sAttr)) * iMul
    end
    iPower = iPower + self.m_oSkillCtrl:GetPower(mPower.skill)
    return math.floor(iPower)
end

function CPartner:GetCPower()
    if not self.m_sType then
        self.m_sType = "partner" .. self:PartnerType()
    end
    return math.floor(self.m_cPower:GetPower(self.m_sType))
end

function CPartner:GetLock()
    return 0
end


function CPartner:GetAwake()
    return self:GetData("awake")
end

function CPartner:GetEffectType()
    return self:GetPartnerData()["effect_type"]
end

function CPartner:GetAwakeType()
    return self:GetPartnerData()["awake_type"]
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
        mPerform[iSk] = math.max(iLevel,mPerform[iSk] or 0)
    end
    local mSoulSet = itemdefines.GetParSoulTypeData(self:GetSoulType())
    if mSoulSet then
        mPerform[mSoulSet.skill] = 1
    end
    return mPerform
end

function CPartner:SetStatus(iStatus, bNotRefresh)
    self:Dirty()
    local iBit = 1 << (iStatus - 1)
    local iStatus = self:GetStatus()
    local iBitStatus = iStatus & iBit
    iBitStatus = iBitStatus ~ iBit
    self:SetData("status", ((iStatus & (~iBit)) | iBitStatus))
    if not bNotRefresh then
        self:PropChange("status")
    end
    return  iBitStatus ~= 0
end

function CPartner:GetStatus()
    return self:GetData("status", 0)
end

function CPartner:OnStatus(iStatus)
    local iBit = 1 << (iStatus - 1)
    local iStatus = self:GetStatus()
    local iBitStatus = iStatus & iBit
    return iBitStatus ~= 0
end

function CPartner:GetTitleList()
    return self:GetData("title", {})
end

function CPartner:SetTitle(titles)
    titles = titles or {}
    self:SetData("title", titles)
end

function CPartner:UseTitle(mTitle)
    if not self:ValidUseTitle(mTitle) then
        return
    end
    local titles = self:GetTitleList()
    table.insert(titles, mTitle)
    self:SetTitle(titles)
end

function CPartner:ValidUseTitle(mTitle)
    if not mTitle then
        return false
    end
    local iTid = mTitle.tid
    local mData = partnerdefine.GetPartnerTitle(iTid)
    if not mData then
        return false
    end
    local titles = self:GetTitleList()
    for _, m in ipairs(titles) do
        if m.tid == mTitle.tid then
            return false
        end
    end
    if mData.type ~= 1 then
        return false
    end
    local effects = mData.type_effect or {}
    for _, iType in ipairs(effects) do
        if iType == self:PartnerType() then
            return true
        end
    end
    return false
end

function CPartner:GetPowerRank()
    return self:GetData("power_rank", 0)
end

function CPartner:SetPowerRank(iNew)
    local iOld = self:GetPowerRank()
    if iOld ~= iNew then
        self:Dirty()
        self:SetData("power_rank", iNew)
        self:PropChange("power_rank")
    end
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
        self:ExecuteCPower("SetBaseAttr",sAttr,iValue)
    end
    local iHp = self.m_mAttr["hp"]
    if not iHp or iHp > self.m_mAttr["maxhp"] then
        self.m_mAttr["hp"] = self.m_mAttr["maxhp"]
    end

    self:SetupNextStageAttr()
end

--初始化下一个阶段属性
function CPartner:SetupNextStageAttr()
    local iGrade = self:GetGrade()
    local mAttr = {"maxhp", "attack", "defense"}
    local iNextGrade = min(iGrade+1, self:MaxGrade())
    local mUpgradeEnv = {lv = iNextGrade}
    local mAttrUpgrade = self:GetAttrData()
    self.m_mUpgradeAttr = {}
    for _, sAttr in pairs(mAttr) do
        local iValue = formula_string(mAttrUpgrade[sAttr], mUpgradeEnv)
        self.m_mUpgradeAttr[sAttr] = iValue
    end
    local mUpstarEnv = {lv = iGrade}
    local iStar = min(self:GetStar() + 1, MAX_STAR)
    local mAttrUpstar = self:GetAttrData(iStar)
    self.m_mUpstarAttr = {}
    for _, sAttr in pairs(mAttr) do
        local iValue = formula_string(mAttrUpstar[sAttr], mUpstarEnv)
        self.m_mUpstarAttr[sAttr] = iValue
    end
end

function CPartner:GetAttr(sAttr)
    if OPEN_CPOWER == 1 then
        return self:GetCAttr(sAttr) + self:GetTestAttr(sAttr)
    end
    return self:GetLAttr(sAttr)
end

function CPartner:GetLAttr(sAttr)
    local iValue = self:GetBaseAttr(sAttr) * (10000 + self:GetBaseRatio(sAttr)) / 10000 + math.floor(self:GetAttrAdd(sAttr)) + self:GetTestAttr(sAttr)
    iValue = math.floor(iValue)
    return iValue
end

function CPartner:GetCAttr(sAttr)
    return math.floor(self.m_cPower:GetAttr(sAttr))
end

function CPartner:GetUpGradeAttr(sAttr)
    local iValue = self.m_mUpgradeAttr[sAttr] or 0
    iValue = iValue * (10000 + self:GetBaseRatio(sAttr)) / 10000 + math.floor(self:GetAttrAdd(sAttr)) + self:GetTestAttr(sAttr)
    return math.floor(iValue)
end

function CPartner:GetUpStarAttr(sAttr)
    local iValue = self.m_mUpstarAttr[sAttr] or 0
    iValue = iValue * (10000 + self:GetBaseRatio(sAttr)) / 10000 + math.floor(self:GetAttrAdd(sAttr)) + self:GetTestAttr(sAttr)
    return math.floor(iValue)
end

function CPartner:GetBaseAttr(sAttr)
    local iBaseValue = self.m_mAttr[sAttr] or 0
    return math.floor(iBaseValue)
end

function CPartner:GetBaseRatio(sAttr)
    if OPEN_CPOWER == 1 then
        return self:GetCBaseRatio(sAttr)
    end
    return self:GetLBaseRatio(sAttr)
end

function CPartner:GetLBaseRatio(sAttr)
    local iRatio = 0
    -- iRatio = iRatio + self:GetRatioApply(sAttr)
    iRatio = iRatio + self.m_oSkillCtrl:GetRatioApply(sAttr)
    iRatio = iRatio + self:GetEquipRatioApply(sAttr)
    iRatio = iRatio + self:GetEquipSetRatioApply(sAttr)
    iRatio = iRatio + self:GetAwakeRatioApply(sAttr)
    iRatio = iRatio + self:GetHouseRatioApply(sAttr)
    return iRatio
end

function CPartner:GetCBaseRatio(sAttr)
    return math.floor(self.m_cPower:GetBaseRatio(sAttr))
end

function CPartner:GetHouseRatioApply(sAttr)
    local oPlayer = self:GetOwner()
    if oPlayer then
        return oPlayer.m_oPartnerCtrl:GetHouseRatio(sAttr)
    end
    return 0
end

function CPartner:GetAttrAdd(sAttr)
    if OPEN_CPOWER == 1 then
        return self:GetCAttrAdd(sAttr)
    end
    return self:GetLAttrAdd(sAttr)
end

function CPartner:GetLAttrAdd(sAttr)
    local iValue = 0
    -- iValue = iValue + math.floor(self:GetApply(sAttr))
    iValue = iValue + math.floor(self.m_oSkillCtrl:GetApply(sAttr))
    iValue = iValue + math.floor(self:GetEquipApply(sAttr))
    iValue = iValue + math.floor(self:GetEquipSetApply(sAttr))
    iValue = iValue + math.floor(self:GetAwakeApply(sAttr))
    iValue = iValue + math.floor(self:GetHouseAttr(sAttr))
    return iValue
end

function CPartner:GetCAttrAdd(sAttr)
    return math.floor(self.m_cPower:GetAttrAdd(sAttr))
end

function CPartner:GetHouseAttr(sAttr)
    local oPlayer = self:GetOwner()
    if oPlayer then
        return oPlayer.m_oPartnerCtrl:GetHouseAttr(sAttr)
    end
    return 0
end

function CPartner:GetTestAttr(sAttr)
    local mTestAttr = self:GetData("test_attr", {})
    return mTestAttr[sAttr] or 0
end

function CPartner:GetEquipTraceNoList()
    local mList = {}
    for iPos, oEquip in pairs(self.m_mEquip) do
        local _,iTraceNo = table.unpack(oEquip:GetData("TraceNo",{}))
        table.insert(mList,{name=oEquip:Name(),traceno=iTraceNo})
    end
    return mList
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

function CPartner:GetSoulApply(sAttr)
    local iValue = 0
    for iPos, iSoulId in pairs(self.m_mSoul) do
        local oSoul = self:GetWieldSoul(iPos)
        if oSoul then
            iValue = iValue + oSoul:GetApply(sAttr)
        end
    end
    return iValue
end

function CPartner:GetSoulRatioApply(sAttr)
    -- local iValue = 0
    -- for iPos, iSoulId in pairs(self.m_mSoul) do
    --     local oSoul = self:GetWieldSoul(iPos)
    --     if oSoul then
    --         iValue = iValue + oSoul:GetApply(sAttr)
    --     end
    -- end
    -- return iValue
    return 0
end

function CPartner:GetPid()
    return self:GetInfo("pid")
end

function CPartner:GetOwner()
    local iPid = self:GetInfo("pid")
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    return oPlayer
end

function CPartner:GetStarData()
    local iStar = self:GetStar()
    local mStar = res["daobiao"]["partner"]["star"][iStar]
    assert(mStar, string.format("partner star err: %s, %s, %s", self:GetInfo("pid"), self:ID(), iStar))
    return mStar
end

function CPartner:GetAwakeCost()
    local mInfoData = self:GetPartnerData()
    return mInfoData.awake_cost
end

function CPartner:GetAwakeCoinCost()
    local mInfoData = self:GetPartnerData()
    return mInfoData.awake_coin_cost
end

function CPartner:GetAttrData(iStar)
    local iStar =  iStar or self:GetStar()
    local iPartnerType = self:PartnerType()
    local mAttrData = res["daobiao"]["partner"]["partner_attr"]
    --debug assert
    assert(mAttrData[iPartnerType], string.format("partner err: %s, %s, %s", self:GetPid(), iPartnerType, iStar))
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
    local iRare = self:GetPartnerData()["rare"]
    local mRare = res["daobiao"]["partner"]["rare"][iRare]
    assert(mRare, string.format("partner rare data err: %s, %s", self:PartnerType(), self:ID()))
    return mRare
end

function CPartner:GetDefaultSoulType()
    local mInfo = res["daobiao"]["partner"]["partner_gonglue"][self:PartnerType()]
    return mInfo and mInfo["equip_list"][1]
end

function CPartner:IsGradeLimit(mArgs)
    local oAssistMgr = global.oAssistMgr

    mArgs = mArgs or {}
    local iPid = self:GetInfo("pid")
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if not oPlayer then
        return false
    end
    local iPartnerGrade = self:GetGrade()
    if iPartnerGrade >= oPlayer:GetGrade() + 5 then
        if not mArgs.cancel_tip then
            local sMsg = "#partner_name等级超过主角等级#O5#n级时，伙伴将不再获得经验"
            global.oAssistMgr:BroadCastNotify(iPid,nil ,sMsg,{partner_name = self:GetName()})
        end
        return true
    end
    return false
end

function CPartner:GetLimitGrade()
    local oPlayer = self:GetOwner()
    return oPlayer:GetGrade() + 5
end

function CPartner:MaxGrade()
    local res = require "base.res"
    local mUpGrade = res["daobiao"]["partner"]["upgrade"]
    return table_count(mUpGrade)
end

function CPartner:GetMaxExp(oPlayer)
    local iLimitGrade = self:GetLimitGrade() - 1
    local mUpGrade = self:GetUpGradeData()
    mUpGrade = mUpGrade[iLimitGrade]
    assert(mUpGrade, "partner upgrade data err: %s, %s, %s", self:GetInfo("pid"), self:ID(), iLimitGrade)
    local iMaxExp = mUpGrade.partner_exp
    return iMaxExp
end

function CPartner:NeedExp(iUpgrade)
    local iNeedExp = 0
    local iGrade = self:GetGrade()
    local iLimitGrade = self:GetLimitGrade()
    local iNewGrade = min(iGrade + iUpgrade, iLimitGrade)
    if iNewGrade > iGrade then
        local iCurExp = self:GetExp()
        local mUpGrade = self:GetUpGradeData()[iNewGrade - 1]
        iNeedExp = mUpGrade.partner_exp - iCurExp
    end
    return iNeedExp
end

function CPartner:HasSoulAttrType(iAttrType)
    for iPos, iSoulId in pairs(self.m_mSoul) do
        local oSoul = self:GetWieldSoul(iPos)
        if oSoul and oSoul:AttrType() == iAttrType then
            return true
        end
    end
    return false
end

function CPartner:ValidUpgrade()
    return true
end

function CPartner:ValidRemove(mArgs)
    mArgs = mArgs or {}
    local iPid = self:GetPid()
    local oAssistMgr = global.oAssistMgr
    if self:IsLock() then
        if not mArgs.cancel_tip then
            oAssistMgr:Notify(iPid, "伙伴已上锁")
        end
        return false
    end
    if self:IsEqualArena() then
        if not mArgs.cancel_tip then
            oAssistMgr:Notify(iPid, "伙伴为公平竞技伙伴")
        end
        return false
    end
    if self:IsShow() then
        if not mArgs.cancel_tip then
            oAssistMgr:Notify(iPid, "伙伴为展示伙伴")
        end
        return false
    end
    if self:GetFight() > 0 then
        if not mArgs.cancel_tip then
            oAssistMgr:Notify(iPid, "伙伴已上阵")
        end
        return false
    end
    if self:OnStatus(gamedefines.PARTNER_STATUS.ON_TERRAWARS) then
        if not mArgs.cancel_tip then
            oAssistMgr:Notify(iPid, "伙伴正在驻守据点")
        end
        return false
    end
    if self:IsTravel() or self:IsFrdTravel() then
        if not mArgs.cancel_tip then
            oAssistMgr:Notify(iPid, "伙伴正在游历")
        end
        return false
    end
    if self:IsFollow() then
        if not mArgs.cancel_tip then
            oAssistMgr:Notify(iPid, "伙伴正在跟随")
        end
        return false
    end
    return true
end

function CPartner:CalSkillPoint(iTargetType)
    local iSkillPoint = 0
    if self:PartnerType() == iTargetType then
        local iHaveSkillPoint = self.m_oSkillCtrl:CalPartnerSkillPoint()
        iSkillPoint = iSkillPoint + (iHaveSkillPoint // 2 + iHaveSkillPoint % 2) + 1
    end
    return iSkillPoint
end

function CPartner:ExpCritical(iAddExp)
    iAddExp = iAddExp or 0
    local m = self:GetUpGradeCostData()
    if math.random(10000) <= m.upgrade_crit.rate then
        iAddExp = math.floor(iAddExp * m.upgrade_crit.multiple)
    end
    return iAddExp
end

function CPartner:RewardExp(iVal, sReason, mArgs)
    local oAssistMgr = global.oAssistMgr
    mArgs = mArgs or {}
    assert(iVal > 0, string.format("partner RewardExp err: %s, %s, %s", self:GetInfo("pid"), self:ID(), iVal))

    local iPid = self:GetInfo("pid")
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    if not  oPlayer then
        return
    end
    if not self:ValidUpgrade() then
        return
    end
    if self:IsGradeLimit({cancel_tip = 1}) then
        return
    end

    local iExp = self:GetData("exp")
    local iMaxExp = self:GetMaxExp(oPlayer)
    local iAddExp = min(iVal, iMaxExp - iExp)
    if iAddExp > 0 then
        self:Dirty()
        self:SetData("exp", iExp + iAddExp)
        self:CheckUpGrade(sReason, mArgs)
        self:PropChange("exp")
        local lMessage = {}
        local sMsg = "#partner_name获得#hexp#amount"
        local mNotifyArgs = {
            amount = iAddExp,
            partner_name = self:GetName(),
        }
        sMsg = mArgs.tips or sMsg
        if not mArgs.cancel_tip then
            table.insert(lMessage,"GS2CNotify")
        end
        if not mArgs.cancel_channel then
            table.insert(lMessage,"GS2CConsumeMsg")
        end
        if mArgs.show_ui then
            oPlayer:Send("GS2CUpGradePartner", {parid = self:ID()})
        end
        if #lMessage > 0 then
            oAssistMgr:BroadCastNotify(iPid,lMessage,sMsg,mNotifyArgs)
        end
        self:LogExp(iExp, iAddExp, iExp+iAddExp, sReason)
    end
end

function CPartner:CheckUpGrade(sReason, mArgs)
    mArgs = mArgs or {}
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
        self:AfterUpgrade()
        self:LogGrade(iGrade, self:GetGrade(), sReason)
    end
end

function CPartner:OnUpGrade()
    local oAssistMgr = global.oAssistMgr
    local iNextGrade = self:GetGrade() + 1
    self:SetData("grade", iNextGrade)
    self:Setup()
    self:SetData("hp", self:GetAttr("maxhp"))
    self.m_mAttr["hp"] = self:GetData("hp")

    local iPartnerType = self:PartnerType()
    if iNextGrade == 60 then
        if iPartnerType == 301 then
            oAssistMgr:PushCondition(self:GetPid(), {{key = "升级祁连到60级", value=1}})
        end
    end
    local lGrade = {25,30,40,50,60}
    if table_in_list(lGrade, iNextGrade) then
        local sKey = string.format("伙伴等级%s伙伴数量", iNextGrade)
        oAssistMgr:PushAchieve(self:GetPid(), sKey, {value = 1})
        local sKey = string.format("%s等级升至%s级", self:GetDefaultName(), iNextGrade)
        oAssistMgr:PushCondition(self:GetPid(), {{key = sKey, value=1}})
    end
    oAssistMgr:PushAchieve(self:GetPid(),"伙伴等级",{target = self:PartnerType(),value=self:GetGrade()})
end

function CPartner:AfterUpgrade()
    if self:OnStatus(gamedefines.PARTNER_STATUS.ON_TERRAWARS) then
        self:UpdateTerraWarsInfo()
    end
    if self:IsTravel() or self:IsFrdTravel() then
        self:UpdateTravelInfo({key = "par_grade", value = self:GetGrade()})
    end
    self:ShareUpdateAmount()
end

function CPartner:AfterAwake()
    if self:OnStatus(gamedefines.PARTNER_STATUS.ON_TERRAWARS) then
        self:UpdateTerraWarsInfo()
    end
    if self:IsTravel() or self:IsFrdTravel() then
        self:UpdateTravelInfo({key = "par_awake", value = self:GetAwake()})
    end
    local oPlayer = self:GetOwner()
    if oPlayer then
        local args = {
            {"&role&", oPlayer:GetName()},
            {"&partner&", self:PartnerType()},
        }
        local sMsg = global.oAssistMgr:GetPartnerTextData(1003, args)
        global.oNotifyMgr:SendSysChat(sMsg , 1, 1)
    end
    self:ShareUpdateAmount()
end

function CPartner:AfterIncreaseStar()
    if self:OnStatus(gamedefines.PARTNER_STATUS.ON_TERRAWARS) then
        self:UpdateTerraWarsInfo()
    end
    if self:IsTravel() or self:IsFrdTravel() then
        self:UpdateTravelInfo({key = "par_star", value = self:GetStar()})
    end
end

function CPartner:UpdateTerraWarsInfo()
    interactive.Send(".world","partner", "UpdateTerraWarsInfo", {
            pid = self:GetPid(),
            parid = self:ID(),
            data = self:BackUpTerraWarsInfo(),
            })
end

function CPartner:IsLimitStar()
    if self:GetStar() >= MAX_STAR then
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

function CPartner:IsPlayerGradeLimit(oPlayer)
    if self:GetGrade() >= oPlayer:GetGrade() + 5 then
        return true
    end
    return false
end

function CPartner:IncreaseStar(iVal, mArgs)
    self:Dirty()
    mArgs = mArgs or {}
    assert(iVal > 0, string.format("partner IncreaseStar err: %s, %s, %s", self:GetInfo("pid"), self:ID(), iVal))
    local lOldProp = self:PackStarProp()
    local iOldStar = self:GetData("star")
    iVal = iOldStar + iVal
    self:SetData("star", min(iVal, MAX_STAR))
    self:Setup()
    self:ActivePropChange("star")
    local iStar = self:GetStar()
    if iStar > 3 then
        local sKey = string.format("%s星级达到%s星", self:GetDefaultName(), iStar)
        global.oAssistMgr:PushCondition(self:GetPid(), {{key = sKey, value = iStar}})
    end
    if iStar > 1 then
        local sKey = string.format("拥有%s星伙伴数量", iStar)
        global.oAssistMgr:PushAchieve(self:GetPid(),sKey,{value = 1})
    end
    if iStar > iOldStar then
        global.oAssistMgr:PushAchieve(self:GetPid(),"伙伴总星级",{value= iStar - iOldStar})
        global.oAssistMgr:PushAchieve(self:GetPid(),"伙伴星级",{target = self:PartnerType(),value=iStar})
    end

    if not mArgs.cancel_show then
        self:SendStarChangeInfo({
            parid = self:ID(),
            old_star = iOldStar,
            new_star = iStar,
            old_apply = lOldProp,
            new_apply = self:PackStarProp(),
            max_grade = self:GetLimitGrade(),
            })
    end
    self:AfterIncreaseStar()
    self:ShareUpdateAmount()
end

function CPartner:IsLock()
    return self:OnStatus(gamedefines.PARTNER_STATUS.ON_LOCK)
end

function CPartner:IsEqualArena()
    return self:OnStatus(gamedefines.PARTNER_STATUS.ON_EQUAL_ARENA)
end

function CPartner:IsShow()
    return self:OnStatus(gamedefines.PARTNER_STATUS.ON_SHOW)
end

function CPartner:IsFollow()
    return self:OnStatus(gamedefines.PARTNER_STATUS.ON_FOLLOW)
end

function CPartner:IsTravel()
    return self:OnStatus(gamedefines.PARTNER_STATUS.ON_TRAVEL)
end

function CPartner:IsFrdTravel()
    return self:OnStatus(gamedefines.PARTNER_STATUS.ON_FRD_TRAVEL)
end

function CPartner:IsRank()
    local mData  = self:GetPartnerData()
    return mData.rank == 0
end

function CPartner:SetLock()
    self:Dirty()
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetPid()
    local iStatusType = gamedefines.PARTNER_STATUS.ON_LOCK
    self:SetStatus(iStatusType)
    if self:IsLock() then
        oAssistMgr:Notify(iPid, "已上锁")
    else
        oAssistMgr:Notify(iPid, "已解锁")
    end
end

function CPartner:SetName(sName)
    self:Dirty()
    self:SetData("name", sName)
    self:OnName()
    self:PropChange("name")
end

function CPartner:OnName()
    if self:IsFollow() then
        self:SyncFollowInfo()
    end
    if self:IsTravel() or self:IsFrdTravel() then
        self:UpdateTravelInfo({key = "par_name", value = self:GetName()})
    end
    self:UpdateParRank({name = self:GetName()})
end

function CPartner:SetModelInfo(mModel)
    if mModel then
        self:Dirty()
        self:SetData("model_info", mModel)
        self:OnSetModel()
        self:PropChange("model_info")
    end
end

function CPartner:OnSetModel()
    if self:IsFollow() then
        self:SyncFollowInfo()
    end
    if self:IsTravel() or self:IsFrdTravel() then
        self:UpdateTravelInfo({key = "par_model", value = self:GetModelInfo()})
    end
    self:UpdateParRank({model_info = self:GetModelInfo()})
end

function CPartner:SetFight(iPos)
    self:Dirty()
    local iPid = self:GetInfo("pid")
    local iParid = self:ID()
    assert(iPos >= 0, string.format("partner err: %s, %s, %s", iPid, iParid, iPos))
    self:SetData("fight", iPos)
end

function CPartner:GetFight()
    return self:GetData("fight", 0)
end

function CPartner:IsAwake()
    if self:GetAwake() > 0 then
        return true
    else
        return false
    end
end

function CPartner:ValidAwake()
    local oAssistMgr = global.oAssistMgr
    local iPid = self:GetInfo("pid")

    if self:IsAwake() then
        oAssistMgr:Notify(iPid, "伙伴已觉醒")
        return false
    end
    return true
end

function CPartner:Awake(oPlayer)
    self:Dirty()
    local iOldAwake = self:GetAwake()
    self:SetData("awake", 1)
    self:_CheckAwake()
    self:GiveAwakeSkin()
    self:ActivePropChange("awake", "skill")
    oPlayer:Send("GS2CAwakePartner", {
        partnerid = self:ID(),
        })
    global.oAssistMgr:PushAchieve(self:GetPid(),"伙伴觉醒次数",{value = 1})
    global.oAssistMgr:PushAchieve(self:GetPid(),"伙伴觉醒",{target = self:PartnerType(),value=1})
    local sKey = string.format("觉醒%s", self:GetDefaultName())
    global.oAssistMgr:PushCondition(self:GetPid(), {{key = sKey,value = 1}})
    oPlayer:AddTeachTaskProgress(30029, 1)
    self:LogAwake(iOldAwake, self:GetAwake(), "觉醒伙伴")
    self:AfterAwake()
end

function CPartner:GiveAwakeSkin()
    local mData = self:GetPartnerData()
    if mData.awake_skin > 0 then
        local oPlayer = self:GetOwner()
        local sReason = "伙伴觉醒"
        local oSkin = oPlayer.m_oItemCtrl:GetItemObj(mData.awake_skin)
        if not oSkin then
            oSkin = loaditem.ExtCreate(mData.awake_skin)
            oSkin:SetAmount(1)
            oPlayer.m_oItemCtrl:AddItem(oSkin, sReason, {cancel_tip=1, cancel_channel=1, cancel_show=1})
        end
        self:UseSkin(oPlayer, oSkin, sReason)
        global.oAssistMgr:PushAchieve(self:GetPid(),"伙伴皮肤个数",{value = 1})
    end
end

function CPartner:SkillCost()
    local mData = self:GetPartnerData()
    return mData.skill_cost
end

function CPartner:UpGradeSkill(iSkillPoint)
    if iSkillPoint <= 0 then
        return
    end
    local lUnFullSkill = self.m_oSkillCtrl:GetUnFullLevelSkill()
    if #lUnFullSkill == 0 then
        return
    end
    local mOld = {}
    for _, oSk in ipairs(lUnFullSkill) do
        mOld[oSk:ID()] = oSk:Level()
    end
    local iAddPoint = iSkillPoint
    local mModify = {}
    iSkillPoint = self:_UpGradeSkill(mModify, iSkillPoint)
    if iAddPoint > iSkillPoint then
        local sKey = string.format("%s提升技能次数", self:GetDefaultName())
        global.oAssistMgr:PushCondition(self:GetPid(), {{key = sKey, value=iAddPoint - iSkillPoint}})
    end
    self:ActivePropChange("skill")
    local lNet = {}
    for iSk, iLevel in pairs(mModify) do
        table.insert(lNet, {
            id = iSk,
            old_level = mOld[iSk],
            new_level = iLevel,
            })
    end
    if next(mModify) then
        self:SendOpenPartnerSkillUI(lNet)
    end
end

function CPartner:UpGradeGuideSkill()
    local oPlayer = self:GetOwner()
    local iType = self:PartnerType()
    local iCount = oPlayer.m_oPartnerCtrl:GetParSkillCount(iType)
    local mGuide = partnerdefine.GetParSkillGuideData(iType, iCount + 1)
    if mGuide then
        local skills = mGuide.skill
        local unFull = {}
        for _, iSk in ipairs(skills) do
            local oSk = self.m_oSkillCtrl:GetSkill(iSk)
            if oSk and not oSk:IsMaxLevel() then
                table.insert(unFull, oSk)
            end
        end
        return unFull
    end
    return {}
end

function CPartner:GetUpGradeSkill()
    local unFull = self:UpGradeGuideSkill()
    if not next(unFull) then
        unFull = self.m_oSkillCtrl:GetUnFullLevelSkill()
    end
    return unFull
end

function CPartner:IsAllSkillMax()
    local unFull = self:GetUpGradeSkill()
    if next(unFull) then
        return false
    end
    return true
end

function CPartner:_UpGradeSkill(mModify, iSkillPoint)
    local oPlayer = self:GetOwner()
    if not oPlayer then
        return iSkillPoint
    end
    local skills = self:GetUpGradeSkill()
    while (#skills > 0 and iSkillPoint > 0) do
        local iRan = math.random(#skills)
        local oSk = skills[iRan]
        oSk:SkillUnEffect(self)
        local iLevel = oSk:Level() + 1
        oSk:SetLevel(iLevel)
        oSk:SkillEffect(self)
        iSkillPoint = iSkillPoint - 1
        mModify[oSk:ID()] = oSk:Level()
        skills = self:GetUpGradeSkill()
        oPlayer.m_oPartnerCtrl:AddParSkillCount(self:PartnerType(), 1)
    end
    self:ExecuteCPower("SetSklv",self.m_oSkillCtrl:GetTotalSkLv())
    return iSkillPoint
end

function CPartner:GetEquipPlan(iPlanId)
    return self.m_mEquipPlan[iPlanId]
end

function CPartner:IsFullEquip()
    return table_count(self.m_mEquip) == 4
end

function CPartner:CheckEquipSetStar(iSetStar)
    local oAssistMgr = global.oAssistMgr
    iSetStar = iSetStar or 1
    if not self:IsFullEquip() then
        return false
    end
    for iPos, oEquip in pairs(self.m_mEquip) do
        if oEquip:Star()  < iSetStar then
            return false
        end
    end
    oAssistMgr:PushAchieve(self:GetPid(), string.format("穿戴一套%s星符文", iSetStar), {value = 1})
    return true
end

function CPartner:GetWieldEquip(iPos)
    return self.m_mEquip[iPos]
end

function CPartner:WieldEquip(oEquip, bRefresh)
    self:Dirty()
    local oAssistMgr = global.oAssistMgr

    local oPlayer = self:GetOwner()
    local iHistory =  oPlayer.m_oPartnerCtrl:HistoryMaxEquipSetAmount()

    local iPos = oEquip:EquipPos()
    local oOldEquip = self.m_mEquip[iPos]
    if oOldEquip then
        self:UnWieldEquip(oOldEquip, true)
    end
    oEquip:SetWield(self:ID())
    self.m_mEquip[iPos] = oEquip
    oEquip:InitCPowerApply()
    if bRefresh then
        oEquip:GS2CRefreshPartnerEquipInfo(oPlayer)
        self:ActivePropChange("equip_list")
    end

    local iPid = self:GetPid()
    if self:IsFullEquip() then
        local iNewSet = oPlayer.m_oPartnerCtrl:CountEquipSetAmount()
        if iNewSet > iHistory then
            oPlayer.m_oPartnerCtrl:UpdateEquipSetAmount(iNewSet)
            oAssistMgr:PushAchieve(iPid, "穿戴整套符文", {value = iNewSet - iHistory})
        end
    end
    self:OnEquipChange()
end

function CPartner:OnEquipChange()
end

function CPartner:UnWieldEquip(oEquip, bRefresh)
    self:Dirty()
    local oAssistMgr = global.oAssistMgr

    local iPid = self:GetPid()
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    local iPos = oEquip:EquipPos()
    local oOldEquip = self.m_mEquip[iPos]
    if oOldEquip:ID() == oEquip:ID() then
        oEquip:ClearCPowerApply()
        oEquip:SetWield(0)
        self.m_mEquip[iPos] = nil
        if bRefresh then
            self:ActivePropChange("equip_list")
            oEquip:GS2CRefreshPartnerEquipInfo(oPlayer)
        end
    end
    self:OnEquipChange()
end

function CPartner:CountSoul()
    return table_count(self.m_mSoul)
end

function CPartner:CountEquip()
    return table_count(self.m_mEquip)
end

function CPartner:CountStoneLevel()
    local iCnt = 0
    for iPos, oEquip in pairs(self.m_mEquip) do
        iCnt = iCnt + oEquip:CountStoneLevel()
    end
    return iCnt
end

function CPartner:GetWieldSoul(iPos)
    local oSoul
    local iSoulId = self.m_mSoul[iPos]
    local oPlayer = self:GetOwner()
    if oPlayer then
        oSoul = oPlayer:HasItem(iSoulId)
    end
    return oSoul
end

function CPartner:GetSoulPos(iSoulId)
    for iPos, iSoul in pairs(self.m_mSoul) do
        if iSoulId == iSoul then
            return iPos
        end
    end
end

function CPartner:ValidWieldSoul(iPos, oSoul)
    local oPlayer = self:GetOwner()
    if not oPlayer then
        return false
    end
    if oSoul:ItemType() ~= "parsoul" then
        return false
    end
    if oSoul:IsWield() then
        return false
    end
    if self:GetSoulType() ~= oSoul:GetSoulType() then
        return false
    end
    local mSoulPos = itemdefines.GetParSoulPosData(iPos)
    if not mSoulPos then
        return false
    end
    if oPlayer:GetGrade() < mSoulPos.unlock_grade then
        return false
    end
    if self:HasSoulAttrType(oSoul:AttrType()) then
        return false
    end
    return true
end

function CPartner:WieldSoul(iPos, oSoul, bRefresh)
    if not self:ValidWieldSoul(iPos, oSoul) then
        return
    end
    self:DoWieldSoul(iPos, oSoul)
    if bRefresh then
        oSoul:GS2CRefreshPartnerSoulInfo()
    end
end

function CPartner:DoWieldSoul(iPos, oSoul)
    self:Dirty()
    local oAssistMgr = global.oAssistMgr
    local oOldSoul = self:GetWieldSoul(iPos)
    if oOldSoul then
        self:UnWieldSoul(iPos, true)
    end
    oSoul:SetWield(self:ID(), iPos)
    self.m_mSoul[iPos] = oSoul:ID()
    oSoul:InitCPowerApply()
    self:OnSoulChange()
end

function CPartner:OnSoulChange()
end

function CPartner:UnWieldSoul(iPos, bRefresh)
    local oSoul = self:GetWieldSoul(iPos)
    if not oSoul then
        return
    end
    self:Dirty()
    oSoul:ClearCPowerApply()
    oSoul:SetWield(0, 0)
    self.m_mSoul[iPos] = nil
    if bRefresh then
        oSoul:GS2CRefreshPartnerSoulInfo()
    end
    self:OnSoulChange()
end

function CPartner:UnWieldSoulById(iSoulId, bRefresh)
    local iPos = self:GetSoulPos(iSoulId)
    if iPos then
        self:UnWieldSoul(iPos, bRefresh)
    end
end

function CPartner:ResetSoulType(bRefresh)
    self:Dirty()
    for iPos, iSoulId in pairs(self.m_mSoul) do
        self:UnWieldSoul(iPos, true)
    end
    self:SetSoulType(0)
    if bRefresh then
        self:ActivePropChange("soul_type", "souls")
    end
    self:OnResetSoulType()
end

function CPartner:OnResetSoulType()
end

function CPartner:SaveEquipPlan(oPlayer, iPlanId, mPlan, bRefresh)
    self:Dirty()
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
    global.oAssistMgr:Notify(oPlayer:GetPid(), "保存方案成功")
end

function CPartner:OneKeyPutOnEquip(mTarget, iPlanId, bRefresh)
    local oCbMgr = global.oCbMgr
    local lPutOnList = {}
    for iPos, oEquip in pairs(mTarget) do
        if oEquip:IsWield() and oEquip:GetWield() ~= self:ID() then
            table.insert(lPutOnList, oEquip)
        end
    end
    if next(lPutOnList) then
        local sContent
        local iPid = self:GetPid()
        if #lPutOnList == 1 then
            local oEquip = lPutOnList[1]
            local sEquip = string.format("{link15,%s,%s,%s}",oEquip:ID(),iPid,oEquip:Name())
            local oPlayer = self:GetOwner()
            local iParid = oEquip:GetWield()
            local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParid)
            if oPartner then
                local sPartner = string.format("{link19,%s,%s}",oPartner:ID(),oPartner:GetName())
                sContent = string.format("%s正在被%s使用，是否将符文穿戴至该伙伴上？",sEquip, sPartner)
            else
                record.error("partnerobj OneKeyPutOnEquip error, pid:%s, parid:%s, traceno:%s",iPid,iParid,oEquip:TraceNo())
                return
            end
        else
            local lMsgs = {}
            for _, oEquip in pairs(lPutOnList) do
                local sMsg = string.format("{link15,%s,%s,%s}",oEquip:ID(),self:GetInfo("pid"),oEquip:Name())
                table.insert(lMsgs, sMsg)
            end
            sContent = string.format("方案中的%s与其他伙伴向冲突，是否将符文穿戴至该伙伴上？",table.concat(lMsgs, ", " ))
        end
        local mData = {
            sContent = sContent,
            sConfirm = "是",
            sCancle = "否",
        }
        mData = oCbMgr:PackConfirmData(nil, mData)
        local iParid = self:ID()
        local func = function(oPlayer, mData)
            local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParid)
            if oPartner then
                oPartner:_OneKeyPutOnEquip(oPlayer, mData, mTarget, iPlanId, bRefresh)
            end
        end
        oCbMgr:SetCallBack(self:GetInfo("pid"), "GS2CConfirmUI", mData, nil, func)
    else
        local mData = {
            ["answer"] = 0,
        }
        self:_OneKeyPutOnEquip(nil, mData, mTarget, iPlanId, bRefresh)
    end
end

function CPartner:_OneKeyPutOnEquip(oPlayer, mData, mTarget, iPlanId, bRefresh)
    self:Dirty()

    if mData["answer"] == 1 then
        for iPos, oEquip in pairs(mTarget) do
            local iWield = oEquip:GetWield()
            if iWield > 0 and iWield ~= iPartnerId then
                local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iWield)
                oEquip:UnWield(oPartner, oPlayer)
            end
        end
    end

    for iPos, oEquip in pairs(self.m_mEquip) do
        self:UnWieldEquip(oEquip)
    end

    for iPos, oEquip in pairs(mTarget) do
        if not oEquip:IsWield() then
            self:WieldEquip(oEquip)
        end
    end
    self:SetData("equip_plan_id", iPlanId)
    if bRefresh then
        self:ActivePropChange("equip_plan_id", "equip_plan", "equip_list")
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

function CPartner:UseSkin(oPlayer, oSkin,sReason)
    local sReason = sReason or "使用伙伴皮肤"
    local iUsedSid = self:GetModelInfo().skin
    local mData = self:GetPartnerData()
    if not self:IsAwake() and oSkin:SID() == mData.awake_skin then
        global.oAssistMgr:Notify(oPlayer:GetPid(), "觉醒后获得")
        return
    end
    local oUseSkin = oPlayer.m_oItemCtrl:GetItemObj(iUsedSid)
    if not oUseSkin  then
        oUseSkin = loaditem.ExtCreate(iUsedSid)
        oUseSkin:SetAmount(1)
        oPlayer.m_oItemCtrl:AddItem(oUseSkin, sReason, {cancel_tip=1, use_skin=1, cancel_channel=1, cancel_show=1})
    end
    local mModel = oSkin:PackModelInfo()
    self:SetModelInfo(mModel)
    self:PropChange("model_info")
end

function CPartner:OnRemove()
    local oAssistMgr = global.oAssistMgr
    local oAssistMgr = global.oAssistMgr
    local iId = self:ID()
    local iPid = self:GetInfo("pid")
    local oPlayer = oAssistMgr:GetPlayer(iPid)
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

function CPartner:ShareUpdateAmount()
    local oPlayer = self:GetOwner()
    if oPlayer then
        oPlayer.m_oPartnerCtrl:ShareUpdateAmount()
    end
end

function CPartner:ActivePropChange(...)
    self:PropChange("max_hp","attack","defense","hp","critical_ratio","res_critical_ratio","critical_damage",
        "cure_critical_ratio","abnormal_attr_ratio","res_abnormal_ratio","speed","power",...)
    local oPlayer = self:GetOwner()
    oPlayer.m_oPartnerCtrl:CheckRankPPower(self, true)
    self:ShareUpdateAmount()
end

function CPartner:PropChange(...)
    local l = table.pack(...)
    local oAssistMgr = global.oAssistMgr
    oAssistMgr:SetPartnerPropChange(self:GetPid(), self:ID(), l)
end

function CPartner:ClientPropChange(oPlayer, m)
    local mInfo = self:PackNetInfo(m)
    oPlayer:Send("GS2CPartnerPropChange", {
        partnerid = self:ID(),
        partner_info = mInfo,
    })
    local oPlayer = self:GetOwner()
    if oPlayer then
        oPlayer.m_oPartnerCtrl:PropChange(self)
    end
    self:CheckUpdateRemoteFightPartner()
end

function CPartner:CheckUpdateRemoteFightPartner()
    local iPos = self:GetFight()
    if iPos > 0 then
        interactive.Send(".world","partner", "UpdateRemoteFightPartner", {
            pid = self:GetPid(),
            pos = iPos,
            parid = self:ID(),
            data = self:PackRemoteInfo(),
            })
    end
end

function CPartner:PackSoulList()
    local lNet = {}
    for iPos, iSoulId in pairs(self.m_mSoul) do
        table.insert(lNet, {pos = iPos, itemid = iSoulId})
    end
    return lNet
end

function CPartner:PackLinkInfo()
    local mPartner = self:PackNetInfo()
    local lEquip = {}
    for iPos, oEquip in pairs(self.m_mEquip) do
        table.insert(lEquip,{pos = iPos,equip =  oEquip:PackItemInfo()})
    end
    local lSoul = {}
    for iPos, iSoulId in pairs(self.m_mSoul) do
        local oSoul = self:GetWieldSoul(iPos)
        if oSoul then
            table.insert(lSoul, {pos = iPos, soul = oSoul:PackItemInfo()})
        end
    end
    return{partner=mPartner,equip = lEquip, soul = lSoul}
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

function CPartner:GetRemoteInfo(m)
    local mRet = {}
    if not m then
        m = PropHelperFunc
    end
    for k, info in pairs(m) do
        local sCondition,iTemp = table.unpack(info)
        local f = assert(PropHelperFunc[k], string.format("RoleInfo fail f get %s", k))
        local sValue = f(self)
        if sCondition and sCondition == "gte" then
            if tonumber(iTemp) <= tonumber(sValue) then
                mRet[k] = sValue
            else
                return nil
            end
        elseif sCondition  and sCondition == "include" then
            if k == "status" then
                if not self:OnStatus(tonumber(iTemp)) then
                    mRet[k] = sValue
                else
                    return nil
                end
            end
        else
            mRet[k] = sValue
        end
    end
    return mRet
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
        exp = self:GetExp(),
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
        equip = self:PackWarEquip(),
        effect_type = self:GetEffectType(),
    }
end

function CPartner:PackWarEquip()
    local lSid  = {}
    for iPos, oEquip in pairs(self.m_mEquip) do
        table.insert(lSid, oEquip:SID())
    end
    return lSid
end

function CPartner:PackPataWarInfo()
    local data = self:PackWarInfo()
    local iHp = self.m_oToday:Query("patahp",self:GetAttr("maxhp"))
    data.hp = iHp
    return data
end

function CPartner:BackUpTerraWarsInfo()
    if self:GetGrade() >= 20 then
        return self:PackRemoteInfo()
    end
    return nil
end

function CPartner:PackTerraWarInfo()
    local m = self:PackWarInfo()
    m.rare = self:Rare()
    return m
end

function CPartner:PackRemoteInfo()
    return {
        parid = self:ID(),
        type = self:PartnerType(),
        name = self:GetName(),
        grade = self:GetGrade(),
        exp = self:GetExp(),
        pos = self:GetFight(),
        star = self:GetStar(),
        model_info = self:GetModelInfo(),
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
        skill = self:PackRemoteSkill(),
        awake = self:GetAwake(),
        auto_skill = self:GetAutoSkill(),
        double_attack_suspend = self:IsDoubleAttackSuspend(),
        effect_type = self:GetEffectType(),
        patahp = self.m_oToday:Query("patahp",self:GetAttr("maxhp")),
        equip_plan_id = self:GetData("equip_plan_id", 1),
        equip =  self:PackRemoteEquip(),
        rare = self:Rare(),
        soul = self:PackRemoteSoul(),
    }
end

function CPartner:PackRemoteSkill()
    local lSkill = {}
    local mPerform = self:GetPerformList()
    for iSk, iLevel in pairs (mPerform) do
        table.insert(lSkill, {iSk, iLevel})
    end
    return lSkill
end


function CPartner:PackRemoteEquip()
    local lEquip  = {}
    for iPos, oEquip in pairs(self.m_mEquip) do
        table.insert(lEquip, {pos = iPos, data = oEquip:Save()})
    end
    return lEquip
end

function CPartner:PackRemoteSoul()
    local lSoul = {}
    for iPos, iSoulId in pairs(self.m_mSoul) do
        local oSoul = self:GetWieldSoul(iPos)
        if oSoul then
            table.insert(lSoul, {pos = iPos, data = oSoul:Save()})
        end
    end
    return lSoul
end

function CPartner:PackFollowInfo()
    return {
        name = self:GetName(),
        model_info = self:GetModelInfo(),
        title_info = self:PackSceneTitle(),
    }
end

function CPartner:GetAutoSkill()
    return self:GetData("auto_skill",0)
end

function CPartner:SetAutoSkill(iAutoSkill)
    self:Dirty()
    self:SetData("auto_skill",iAutoSkill)
end

function CPartner:IsDoubleAttackSuspend()
    return true
end

function CPartner:PowerBaseVal(sAttr)
    local iBase = 0
    if sAttr == "critical_damage" then
        iBase = 15000
    end
    if sAttr == "speed" then
        iBase = 400
    end
    return iBase
end

function CPartner:Decompose()
    local mData = self:GetPartnerData()
    return mData.decompose
end

function CPartner:SyncFollowInfo()
    local oPlayer = self:GetOwner()
    if oPlayer then
        oPlayer.m_oPartnerCtrl:SyncFollowInfo(self:PackFollowInfo())
    end
end

function CPartner:UpdateTravelInfo(mData)
    local oPlayer = self:GetOwner()
    if oPlayer then
        local iPos = oPlayer.m_oPartnerCtrl:QueryTravelPos(self:ID())
        if iPos then
            interactive.Send(".world","partner","UpdateTravelPartner", {
                pid = self:GetPid(),
                pos = iPos,
                data = mData,
                })
        end
    end
end

function CPartner:UpdateParRank(mData)
    local oPlayer = self:GetOwner()
    if oPlayer then
        mData.pid = self:GetPid()
        mData.partype = self:PartnerType()
        interactive.Send(".rank","rank","OnUpdatePartner", mData)
    end
end

function CPartner:SendStarChangeInfo(mResult)
    local oPlayer = self:GetOwner()
    if oPlayer then
        oPlayer:Send("GS2CPartnerStarUpStar", mResult)
    end
end

function CPartner:SendOpenPartnerSkillUI(lResult)
    local oPlayer = self:GetOwner()
    if oPlayer then
        oPlayer:Send("GS2COpenPartnerSkillUI", {
            parid = self:ID(),
            skills = lResult,
            })
    end
end

function CPartner:PackStarProp()
    local lApply = {}
    local lProp = {"maxhp", "attack", "defense"}
    for _, sAttr in ipairs(lProp) do
        table.insert(lApply, {
            key = sAttr,
            value = self:GetAttr(sAttr),
            })
    end
    return lApply
end

function CPartner:PackRankInfo()
    local oPlayer = self:GetOwner()
    return {
        pid = oPlayer:GetPid(),
        name = oPlayer:GetName(),
        power = self:GetPower(),
        time = get_time(),
        link = self:PackLinkInfo(),
    }
end

function CPartner:PackSceneTitle()
    return self:GetTitleList()
end

function CPartner:PackUpgradeAttr()
    local mAttr = {"maxhp", "attack", "defense"}
    local l = {}
    for _, sAttr in ipairs(mAttr) do
        table.insert(l, {key = sAttr, value = self:GetUpGradeAttr(sAttr)})
    end
    return l
end

function CPartner:PackUpstarAttr()
    local mAttr = {"maxhp", "attack", "defense"}
    local l = {}
    for _, sAttr in ipairs(mAttr) do
        table.insert(l, {key = sAttr, value = self:GetUpStarAttr(sAttr)})
    end
    return l
end

function CPartner:PackShare()
    return {
        parid = self:ID(),
        name = self:GetName(),
        star = self:GetStar(),
        grade = self:GetGrade(),
        power = self:GetPower(),
        awake =self:GetAwake(),
    }
end

-------------log start------------------
function CPartner:LogExp(iOldExp, iAddExp, iNowExp, sReason)
    local mLog = {
        pid = self:GetPid(),
        parid = self:ID(),
        sid = self:PartnerType(),
        exp_old = iOldExp,
        exp_add = iAddExp,
        exp_now = iNowExp,
        reason = sReason,
    }
    record.user("partner", "exp", mLog)
end

function CPartner:LogGrade(iOldGrade, iNowGrade, sReason)
    local mLog = {
        pid = self:GetPid(),
        parid = self:ID(),
        sid = self:PartnerType(),
        grade_old = iOldGrade,
        grade_now = iNowGrade,
        reason = sReason,
    }
    record.user("partner", "grade", mLog)
end


function CPartner:LogAwake(iOldWake, iNowAwake, sReason)
    local mLog = {
        pid = self:GetPid(),
        parid = self:ID(),
        sid = self:PartnerType(),
        awake_old = iOldWake,
        awake_now = iNowAwake,
        reason = sReason,
    }
end

function CPartner:LogInfo()
    return {
        pid = self:GetPid(),
        sid = self:PartnerType(),
        parid = self:ID(),
        exp = self:GetExp(),
        star = self:GetStar(),
        name = self:GetName(),
        rare = self:Rare(),
        grade = self:GetGrade(),
        lock = self:GetLock(),
        awake = self:GetAwake(),
        fight = self:GetFight(),
        auto_skill = self:GetAutoSkill(),
        skill = ConvertTblToStr(self.m_oSkillCtrl:PackNetInfo()),
        model = ConvertTblToStr(self:GetModelInfo()),
    }
end
---------log end----

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
    if self.m_oToday:IsDirty() then
        return true
    end
    return false
end

function CPartner:BackEndData()
    local _,traceno = table.unpack(self:GetData("traceno",{}))
    return {
        traceno = traceno,
        maxhp = self:GetAttr("maxhp",0),
        attack = self:GetAttr("attack",0),
        defense = self:GetAttr("defense",0),
        speed = self:GetAttr("speed",0),
        critical_ratio = self:GetAttr("critical_ratio",0),
        critical_damage = self:GetAttr("critical_damage",0),
        res_critical_ratio = self:GetAttr("res_critical_ratio",0),
        cure_critical_ratio = self:GetAttr("cure_critical_ratio",0),
        abnormal_attr_ratio = self:GetAttr("abnormal_attr_ratio"),
        res_abnormal_ratio = self:GetAttr("res_abnormal_ratio"),
        fuwen = self:GetEquipTraceNoList(),
        power = self:GetPower(),
    }
end

function CPartner:TestOP(oPlayer)
    --
end