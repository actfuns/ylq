local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local record = require "public.record"

local itembase = import(service_path("item/itembase"))
local stonectrl = import(service_path("item/parequip/stonectrl"))
local itemdefines = import(service_path("item.itemdefines"))

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "parequip"

function CItem:New(sid)
    local o = super(CItem).New(self, sid)
    o.m_mMainApply = {}
    return o
end

function CItem:Load(mData)
    super(CItem).Load(self, mData)

    local mStone = mData["stone"]
    if mStone then
        self.m_oStoneCtrl = stonectrl.NewStoneCtrl(self:GetPid(), self:ID())
        self.m_oStoneCtrl:Load(mStone)
        self.m_oStoneCtrl:Setup()
        self:CalStoneLevel()
    end
    self:InitMainApply()
end

function CItem:Save()
    local mData = super(CItem).Save(self)

    if self.m_oStoneCtrl then
        mData["stone"] = self.m_oStoneCtrl:Save()
    end
    return mData
end

function CItem:Create()
    self:InitMainApply()
end

function CItem:InitMainApply()
    self.m_mMainApply = {}
    local mData = self:GetItemData()
    local sVal = mData["attr"]
    if sVal and sVal ~= "" then
        self.m_mMainApply=formula_string(sVal, {})
    end
end

function CItem:EquipPos()
    return self:GetItemData()["pos"]
end

function CItem:EquipLevel()
    return self:GetItemData()["level"]
end

function CItem:Star()
    return self:GetItemData()["star"]
end

function CItem:UpgradeCoin()
    return self:GetItemData()["upgrade_coin"]
end

function CItem:UpgradeItem()
    return self:GetItemData()["upgrade_item"] or {}
end

function CItem:UpstarCoin()
    return self:GetItemData()["upstar_coin"]
end

function CItem:UpstarItem()
    return self:GetItemData()["upstar_item"] or {}
end


function CItem:IsMaxLevel()
    return self:EquipLevel() == 10
end

function CItem:IsMaxStar()
    return self:Star() == 6
end

function CItem:GetStoneLevel()
    return self:GetInfo("stone_level", 1)
end

function CItem:CalStoneLevel()
    if self.m_oStoneCtrl then
        local iLevel = self.m_oStoneCtrl:MaxStoneLevel()
        local mPosData = itemdefines.GetParStonePosData(iLevel)
        if mPosData then
            self:SetInfo("stone_level", mPosData.equip_quality)
        end
    end
end

function CItem:SetWield(iParId)
    self:SetData("wield", iParId)
end

function CItem:GetWield()
    return self:GetData("wield", 0)
end

function CItem:IsWield()
    return self:GetWield() ~= 0
end

function CItem:Use(oPlayer, iParId)
    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
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
    local iSetStar = 2
    oPartner:CheckEquipSetStar(iSetStar)
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
            --todo unwield
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

function CItem:OnStrength(oPlayer, iNewShape)
    self:ClearCPowerApply()
    self.m_SID = iNewShape
    self:InitMainApply()
    self:InitCPowerApply(true)
    self:Refresh()
end

function CItem:OnUpstar(oPlayer, iNewShape)
    self:ClearCPowerApply()
    self.m_SID = iNewShape
    self:InitMainApply()
    self:InitCPowerApply(true)
    self:Refresh()
    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(self:GetWield())
    if oPartner then
        local iSetStar = 2
        oPartner:CheckEquipSetStar(iSetStar)
    end
end

function CItem:PreCheckPartner(oPlayer)
    local iWield = self:GetWield()
    local bRefresh = false
    if iWield > 0 then
        local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iWield)
        if oPartner then
            oPartner:WieldEquip(self, bRefresh)
        else
            record.user("partner_equip", "error", {
                pid = self:GetOwner(),
                trace = self:TraceNo(),
                sid = self:SID(),
                parid = iWield,
                reason = "PreCheckPartner,Wield",
                })
            self:SetData("wield", 0)
        end
    end
end

function CItem:CountInlayStone(iPos)
    local iCount = 0
    if self.m_oStoneCtrl then
        iCount = self.m_oStoneCtrl:CountStone(iPos)
    end
    return iCount
end

function CItem:AddStone(iPos, iShape)
    if not self.m_oStoneCtrl then
        self.m_oStoneCtrl = stonectrl.NewStoneCtrl(self:GetPid(), self:ID())
    end
    self:ClearCPowerApply()
    local bAdd = self.m_oStoneCtrl:AddStone(iPos, iShape)
    self:CalStoneLevel()
    self:InitCPowerApply(true)
end

function CItem:CountStoneLevel()
    local iCnt = 0
    if self.m_oStoneCtrl then
        iCnt = self.m_oStoneCtrl:CountStoneLevel()
    end
    return iCnt
end

function CItem:PackStoneInfo()
    local mNet  = {}
    if self.m_oStoneCtrl then
        mNet["stone_info"] = self.m_oStoneCtrl:PackStoneInfo()
    end
    return mNet
end

function CItem:PackEquipInfo()
    local mNet = self:PackStoneInfo()
    mNet["parid"] = self:GetWield()
    mNet["stone_level"] = self:GetStoneLevel()
    return mNet
end

function CItem:PackItemInfo()
    local mNet = super(CItem).PackItemInfo(self)
    mNet["partner_equip"] = self:PackEquipInfo()
    return mNet
end

function CItem:GetAllAttrs()
    local mCombine = {}
    if self.m_oStoneCtrl then
        self.m_oStoneCtrl:GetAllAttrs(mCombine)
    end
    for sAttr,iValue in pairs(self.m_mMainApply) do
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
                oPartner:ExecuteCPower("AddSpecialApply","equip",sAttr,-iValue)
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
                oPartner:ExecuteCPower("AddSpecialApply","equip",sAttr,iValue)
            end
            if bRefresh then
                oPartner:ActivePropChange()
            end
        end
    end
end

function CItem:IsDirty()
    if super(CItem).IsDirty(self) then
        return true
    end
    if self.m_oStoneCtrl and self.m_oStoneCtrl:IsDirty() then
        return true
    end
    return false
end

function CItem:UnDirty()
    super(CItem).UnDirty(self)
    if self.m_oStoneCtrl then
        self.m_oStoneCtrl:UnDirty()
    end
end

function CItem:GS2CRefreshPartnerEquipInfo(oPlayer)
    oPlayer:Send("GS2CRefreshPartnerEquip", {
        itemid = self:ID(),
        partner_equip = self:PackEquipInfo(),
        })
end