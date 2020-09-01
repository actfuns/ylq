local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local record = require "public.record"

local itembase = import(service_path("item/itembase"))

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "parsoul"

function CItem:New(sid)
    local o = super(CItem).New(self, sid)
    o.m_mApply = {}
    o.m_mRatioApply = {}
    return o
end

function CItem:Load(mData)
    super(CItem).Load(self, mData)
    self:InitApply()
end

function CItem:Save()
    local mData = super(CItem).Save(self)
    return mData
end

function CItem:Create()
    self:InitApply()
end

function CItem:InitApply()
    self.m_mApply = {}
    local mData = self:GetItemData()
    local sVal = mData["attr"]
    if sVal and sVal ~= "" then
        self.m_mApply=formula_string(sVal, {level = self:Level()})
    end
    self.m_mRatioApply = {}
    local sRatio = mData["attr_ratio"]
    if sRatio and sRatio ~= "" then
        self.m_mRatioApply=formula_string(sRatio, {level = self:Level()})
    end
end

function CItem:Level()
    return self:GetData("soul_level", 1)
end

function CItem:Exp()
    return self:GetData("exp", 0)
end

function CItem:AttrType()
    return self:GetItemData()["attr_type"]
end

function CItem:GetSoulType()
    return self:GetItemData()["soul_type"]
end

function CItem:MaxLevel()
    return 15
end

function CItem:IsMaxLevel()
    return self:Level() == self:MaxLevel()
end

function CItem:IsMaxQuality()
    return self:QualityLevel() == 5
end

function CItem:QualityLevel()
    return self:GetItemData()["soul_quality"]
end

function CItem:SetWield(iParId, iPos)
    self:SetData("wield", iParId)
    self:SetData("pos", iPos)
end

function CItem:GetWield()
    return self:GetData("wield", 0)
end

function CItem:IsWield()
    return self:GetWield() ~= 0
end

function CItem:WieldPos()
    return self:GetData("pos", 0)
end

function CItem:BaseExp()
    local res = require "base.res"
    local iQuality = self:QualityLevel()
    local iLevel = 1
    local mData = res["daobiao"]["partner_item"]["soul_upgrade"][iQuality][iLevel]
    return mData.base_exp or 0
end

function CItem:EatExp()
    return self:BaseExp() + self:Exp()
end

function CItem:GetMaxExp()
    local res = require "base.res"
    local iQuality = self:QualityLevel()
    local iMaxLevel = self:MaxLevel()
    local mData = res["daobiao"]["partner_item"]["soul_upgrade"]
    mData =mData[iQuality][iMaxLevel]
    return mData.upgrade_exp
end

function CItem:AddExp(oPlayer, iAddExp, sReason, mArgs)
    local oNotifyMgr = global.oNotifyMgr

    if self:IsMaxLevel() then
        return
    end
    local iExp = self:Exp()
    local iMaxExp = self:GetMaxExp()
    local iAddExp = math.min(iAddExp, iMaxExp - iExp)
    if iAddExp > 0 then
        iExp = iExp + iAddExp
        self:SetData("exp", iExp)
        self:CheckUpGrade(oPlayer)
        self:GS2CRefreshPartnerSoulInfo()
    end
end

function CItem:CheckUpGrade(oPlayer)
    local res = require "base.res"
    local mUpGrade = res["daobiao"]["partner_item"]["soul_upgrade"]
    local iQuality = self:QualityLevel()
    mUpGrade = mUpGrade[iQuality]
    local iLevel = self:Level()
    local i = iLevel
    local iPartnerId = self:GetWield()
    while true do
        local m = mUpGrade[i]
        if not m then
            break
        end
        if self:IsMaxLevel() then
            break
        end
        local iCurMaxExp = m.upgrade_exp
        if self:Exp() < iCurMaxExp then
            break
        end
        i = i + 1
    end
    if i > iLevel then
        self:SetLevel(i)
        self:ClearCPowerApply()
        self:OnUpGrade(oPlayer)
        self:InitApply()
        self:InitCPowerApply(true)
    end
end

function CItem:SetLevel(iLevel)
    self:SetData("soul_level", iLevel)
end

function CItem:OnUpGrade(oPlayer)
end

function CItem:Use(oPlayer, iParId)
end

function CItem:UseSoul(oPlayer, oPartner, iPos)
    if self:IsWield() then
        self:UnWield(oPlayer, oPartner, iPos)
    else
        self:Wield(oPartner, iPos)
    end
end

function CItem:Wield(oPartner, iPos)
    self:Dirty()
    oPartner:WieldSoul(iPos, self, true)
end

function CItem:UnWield(oPlayer, oPartner, iPos)
    self:Dirty()
    local iPid = oPlayer:GetPid()
    local iTarget = oPartner:ID()
    local iWield = self:GetWield()
    if iTarget == iWield then
        oPartner:UnWieldSoul(iPos)
    else
        local o = oPlayer.m_oPartnerCtrl:GetPartner(iWield)
        if o then
            local oCbMgr = global.oCbMgr
            local sEquip = string.format("{link15,%s,%s,%s}",self:ID(),iPid,self:Name())
            local sPartner = string.format("{link19,%s,%s}",o:ID(),o:GetName())
            local sContent = string.format("%s正在被%s使用，是否将御灵穿戴至该伙伴上？",sEquip, sPartner)
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
                    oEquip:UnWield1(oPlayer, mData, iWield, iTarget, iPos)
                end
            end
            oCbMgr:SetCallBack(iPid, "GS2CConfirmUI", mData, nil, func)
        else
            --todo unwield
            record.error("partner equip UnWield error, pid:%s, parid:%s, traceno:%s",iPid,iWield,self:TraceNo())
        end
    end
end

function CItem:UnWield1(oPlayer, mData, iWield, iTarget, iPos)
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
            oPartner:UnWieldSoul(self:WieldPos(), self, true)
            oPartner:ActivePropChange("souls")
            oTarget:WieldSoul(iPos, self, true)
            oTarget:ActivePropChange("souls")
        end
    end
end

function CItem:PreCheckPartner(oPlayer)
    local iWield = self:GetWield()
    local iPos = self:WieldPos()
    local bRefresh = false
    if iWield > 0 and iPos > 0 then
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iWield)
        if oPartner then
            oPartner:DoWieldSoul(iPos, self)
        else
            -- record.user("partner_equip", "error", {
            --     pid = self:GetOwner(),
            --     trace = self:TraceNo(),
            --     sid = self:SID(),
            --     parid = iWield,
            --     reason = "PreCheckPartner,Wield",
            --     })
            self:SetData("wield", 0)
        end
    end
end

function CItem:GetApply(sAttr,rDefault)
    rDefault = rDefault or 0
    return self.m_mApply[sAttr] or rDefault
end

function CItem:GetRatioApply(sAttr,rDefault)
    sAttr = sAttr .. "_ratio"
    return self.m_mRatioApply[sAttr] or rDefault
end

function CItem:GetRatioApply(sAttr, rDefault)
    return 0
end

function CItem:PackSoulInfo()
    local mNet = {}
    mNet["parid"] = self:GetWield()
    mNet["level"] = self:Level()
    mNet["exp"] = self:Exp()
    return mNet
end

function CItem:PackItemInfo()
    local mNet = super(CItem).PackItemInfo(self)
    mNet["partner_soul"] = self:PackSoulInfo()
    return mNet
end

function CItem:GetAllAttrs()
    local mCombine = {}
    for sAttr,iValue in pairs(self.m_mApply) do
        mCombine[sAttr] = mCombine[sAttr] or 0
        mCombine[sAttr] = mCombine[sAttr] + iValue
    end
    for sAttr, iValue in pairs(self.m_mRatioApply) do
        mCombine[sAttr] = mCombine[sAttr] or 0
        mCombine[sAttr] = mCombine[sAttr] + iValue
    end
    return mCombine
end

function CItem:ClearCPowerApply(bRefresh)
    local oPlayer = self:GetPlayerObj()
    if oPlayer then
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(self:GetWield())
        if oPartner then
            local mCombine = self:GetAllAttrs()
            for sAttr,iValue in pairs(mCombine) do
                oPartner:ExecuteCPower("AddSpecialApply","soul",sAttr,-iValue)
            end
            if bRefresh then
                oPartner:ActivePropChange()
            end
        end
    end
end

function CItem:InitCPowerApply(bRefresh)
    local oPlayer = self:GetPlayerObj()
    if oPlayer then
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(self:GetWield())
        if oPartner then
            local mCombine = self:GetAllAttrs()
            for sAttr,iValue in pairs(mCombine) do
                oPartner:ExecuteCPower("AddSpecialApply","soul",sAttr,iValue)
            end
            if bRefresh then
                oPartner:ActivePropChange()
            end
        end
    end
end
function CItem:GS2CRefreshPartnerSoulInfo(oPlayer)
    oPlayer = oPlayer or self:GetPlayerObj(self:GetOwner())
    if oPlayer then
        oPlayer:Send("GS2CRefreshPartnerSoul", {
            itemid = self:ID(),
            partner_soul = self:PackSoulInfo(),
            })
    end
end