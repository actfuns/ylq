local global = require "global"

local datactrl = import(lualib_path("public.datactrl"))
local skillobj = import(service_path("skill/skillobj"))

function NewSkill(...)
    local o = CPartnerSkill:New(...)
    return o
end

function NewSkillCtrl(...)
    local o = CSkillCtrl:New(...)
    return o
end

CPartnerSkill = {}
CPartnerSkill.__index = CPartnerSkill
inherit(CPartnerSkill, skillobj.CSkill)

function CPartnerSkill:New(iSk)
    local o = super(CPartnerSkill).New(self, iSk)
    o:SetData("level", 1)
    o:InitMaxLevel()
    return o
end

function CPartnerSkill:InitMaxLevel()
    local mData = self:GetSkillData()
    local lLevel = table_key_list(mData)
    self.m_iMaxLevel = math.max(table.unpack(lLevel))
end

function CPartnerSkill:GetSkillData()
    local res = require "base.res"
    local iSk = self:ID()
    local mData = res["daobiao"]["skill"][iSk]
    assert(mData,string.format("GetSkillData err:%s", iSk))

    return mData
end

function CPartnerSkill:PackNetInfo()
    local mNet = {}
    mNet["sk"] = self:ID()
    mNet["level"] = self:Level()

    return mNet
end

function CPartnerSkill:SkillEffect(oPartner)
    local iLevel = self:Level()
    if iLevel <= 0 then
        return
    end
    local mEnv = {
        level = self:Level()
    }
    local mData = self:GetSkillData()
    mData = mData[iLevel]
    assert(mData, string.format("partner skill err: %s, %s", self:ID(), iLevel))
    local sArgs = mData["attr_value_list"]
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs,mEnv)
        for sApply,iValue in pairs(mArgs) do
            iValue = math.floor(iValue)
            -- oPartner.m_oSkillMgr:AddApply(sApply, self:ID(), iValue)
            self:AddApply(sApply,iValue)
        end
    end

    local sArgs = mData["attr_ratio_list"]
    if sArgs and sArgs ~= "" then
        local mArgs = formula_string(sArgs, mEnv)
        for sApply,iValue in pairs(mArgs) do
            -- oPartner.m_oSkillMgr:AddRatioApply(sApply, self:ID(), iValue)
            self:AddRatioApply(sApply, iValue)
        end
    end
end

function CPartnerSkill:SkillUnEffect(oPartner)
    self.m_mApply = {}
    self.m_mRatioApply = {}
end

function CPartnerSkill:LimitLevel(oPartner)
    return self.m_iMaxLevel
end

function CPartnerSkill:IsMaxLevel()
    return self:Level() >= LimitLevel() 
end


CSkillCtrl = {}
CSkillCtrl.__index = CSkillCtrl
inherit(CSkillCtrl, datactrl.CDataCtrl)

function CSkillCtrl:New(oPartner)
    local o = super(CSkillCtrl).New(self)
    o.m_mPartnerSkill = {}

    o.m_oContainer = oPartner
    return o
end

function CSkillCtrl:Release()
    for _, oSk in pairs(self.m_mPartnerSkill) do
        baseobj_safe_release(oSk)
    end
    super(CSkillCtrl).Release(self)
end

function CSkillCtrl:Load(mData)
    mData = mData or {}
    for sSk, mSkill in pairs(mData) do
        local iSk = tonumber(sSk)
        local oSk = NewSkill(iSk)
        oSk:Load(mSkill)
        oSk:SkillEffect()
        self.m_mPartnerSkill[iSk] = oSk
    end
end

function CSkillCtrl:Save()
    local mData = {}
    for iSk, oSk in pairs(self.m_mPartnerSkill) do
        mData[db_key(iSk)] = oSk:Save()
    end
    
    return mData
end

function CSkillCtrl:AddSkill(oSk, sReason)
    self:Dirty()

    local iSk = oSk:ID()
    local oOld = self:GetSkill(iSk)
    assert(not oOld, string.format("add partner skill err: %s, %s", self:GetOwnerID(), iSk))
    self.m_mPartnerSkill[iSk] = oSk
end

function CSkillCtrl:GetSkill(iSk)
    return self.m_mPartnerSkill[iSk]
end

function CSkillCtrl:GetAllPartnerSkill()
    return self.m_mPartnerSkill
end

function CSkillCtrl:GetUnFullLevelSkill()
    local mList = {}
    for iSk, oSk in pairs(self.m_mPartnerSkill) do
        if oSk:Level() < oSk:LimitLevel() then
            table.insert(mList, oSk)
        end
    end

    return mList
end

function CSkillCtrl:GetOwnerID()
    if self.m_oContainer then
        return self.m_oContainer:PartnerType()
    end
end

function CSkillCtrl:GetApply(sApply)
    local iRet = 0
    for iSk, oSk in pairs(self.m_mPartnerSkill) do
        iRet = iRet + oSk:GetApply(sApply)
    end
    return iRet
end

function CSkillCtrl:GetRatioApply(sApply)
    local iRet = 0
    for iSk, oSk in pairs(self.m_mPartnerSkill) do
        iRet = iRet + oSk:GetRatioApply(sApply)
    end

    return iRet
end

function CSkillCtrl:CalPartnerSkillPoint()
    local iTotalPoint = 0
    for iSk, oSk in pairs(self.m_mPartnerSkill) do
        iTotalPoint = iTotalPoint + (oSk:Level() - 1)
    end

    return iTotalPoint
end

function CSkillCtrl:PackNetInfo()
    local mNet = {}
    for iSk, oSk in pairs(self.m_mPartnerSkill) do
        table.insert(mNet, oSk:PackNetInfo())
    end

    return mNet
end

function CSkillCtrl:UnDirty()
    super(CSkillCtrl).UnDirty(self)
    for _, oSk in pairs(self.m_mPartnerSkill) do
        oSk:UnDirty()
    end
end

function CSkillCtrl:IsDirty()
    local bDirty = super(CSkillCtrl).IsDirty(self)
   if bDirty then
        return true
    end
    for _, oSk in pairs(self.m_mPartnerSkill) do
        if oSk:IsDirty() then
            return true
        end
    end
    return false
end