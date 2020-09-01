-- import file

local lsum = require "lsum"

local Attr2Index = {
    maxhp=0,attack=1,defense=2,speed=3,critical_ratio=4,res_critical_ratio=5,
    critical_damage=6,abnormal_attr_ratio=7,res_abnormal_ratio=8,cure_critical_ratio=9,skill=10,sub_power=11,
    maxhp_ratio=0,attack_ratio=1,defense_ratio=2,
}

MO_PARTNER_ATTR ={
    MO_BASE = 0,
    MO_BR_SKILL = 1,
    MO_BR_EQUIP = 2,
    MO_BR_EQUIP_SET = 3,
    MO_BR_AWAKE = 4,
    MO_BR_HOUSE = 5,
    MO_BR_SOUL = 6,
    MO_ADD_SKILL = 7,
    MO_ADD_EQUIP = 8,
    MO_ADD_EQUIP_SET = 9,
    MO_ADD_AWAKE = 10,
    MO_ADD_HOUSE = 11,
    MO_ADD_SOUL = 12,
}

BR_POS2MO = {
    skill = MO_PARTNER_ATTR.MO_BR_SKILL,
    equip = MO_PARTNER_ATTR.MO_BR_EQUIP,
    equipset = MO_PARTNER_ATTR.MO_BR_EQUIP_SET,
    awake = MO_PARTNER_ATTR.MO_BR_AWAKE,
    house = MO_PARTNER_ATTR.MO_BR_HOUSE,
    soul = MO_PARTNER_ATTR.MO_BR_SOUL,
}

ADD_POS2MO = {
    skill = MO_PARTNER_ATTR.MO_ADD_SKILL,
    equip = MO_PARTNER_ATTR.MO_ADD_EQUIP,
    equipset = MO_PARTNER_ATTR.MO_ADD_EQUIP_SET,
    awake = MO_PARTNER_ATTR.MO_ADD_AWAKE,
    house = MO_PARTNER_ATTR.MO_ADD_HOUSE,
    soul = MO_PARTNER_ATTR.MO_ADD_SOUL,
}

function NewCPower(...)
    return CCPower:New(...)
end

CCPower = {}
CCPower.__index = CCPower
inherit(CCPower, logic_base_cls())

function CCPower:New()
    local o = super(CCPower).New(self)
    o.m_cSum = lsum.lsum_create()
    return o
end

function CCPower:Release()
    self.m_cSum = nil
    super(CCPower).Release(self)
end

function CCPower:GetIndex(sAttr)
    return Attr2Index[sAttr]
end

function CCPower:SetRatioApply(sPos,sAttr,Val)
    local iIndex = self:GetIndex(sAttr)
    if not iIndex then return end
    local oSum = self.m_cSum
    local iMo = BR_POS2MO[sPos]
    if not iMo then return end
    oSum:set(iIndex,iMo,Val)
end

function CCPower:AddRatioApply(sPos,sAttr,Val)
    local iIndex = self:GetIndex(sAttr)
    if not iIndex then return end
    local oSum = self.m_cSum
    local iMo = BR_POS2MO[sPos]
    if not iMo then return end
    oSum:add(iIndex,iMo,Val)
end

function CCPower:ClearRatioApply(sPos)
    local oSum = self.m_cSum
    local iMo = BR_POS2MO[sPos]
    if not iMo then return end
    oSum:clear(iMo)
end

function CCPower:SetApply(sPos,sAttr,Val)
    local iIndex = self:GetIndex(sAttr)
    if not iIndex then return end
    local oSum = self.m_cSum
    local iMo = ADD_POS2MO[sPos]
    if not iMo then return end
    oSum:set(iIndex,iMo,Val)
end

function CCPower:AddApply(sPos,sAttr,Val)
    local iIndex = self:GetIndex(sAttr)
    if not iIndex then return end
    local oSum = self.m_cSum
    local iMo = ADD_POS2MO[sPos]
    if not iMo then return end
    oSum:add(iIndex,iMo,Val)
end

function CCPower:ClearApply(sPos)
    local oSum = self.m_cSum
    local iMo = ADD_POS2MO[sPos]
    if not iMo then return end
    oSum:clear(iMo)
end

function CCPower:SetSklv(iLevel)
    local oSum = self.m_cSum
    oSum:setsklv(iLevel)
end

function CCPower:SetBaseAttr(sAttr,Val)
    local iIndex = self:GetIndex(sAttr)
    if not iIndex then return end
    local oSum = self.m_cSum
    oSum:set(iIndex,MO_PARTNER_ATTR.MO_BASE,Val)
end

function CCPower:GetAttr(sAttr)
    local iIndex = self:GetIndex(sAttr)
    if not iIndex then return 0 end
    local oSum = self.m_cSum
    return oSum:getattr(iIndex)
end

function CCPower:GetBaseRatio(sAttr)
    local iIndex = self:GetIndex(sAttr)
    if not iIndex then return 0 end
    local oSum = self.m_cSum
    return oSum:getbaseratio(iIndex)
end

function CCPower:GetAttrAdd(sAttr)
    local iIndex = self:GetIndex(sAttr)
    if not iIndex then return 0 end
    local oSum = self.m_cSum
    return oSum:getattradd(iIndex)
end

function CCPower:GetPower(sType)
    local oSum = self.m_cSum
    return oSum:getpower(sType)
end

function CCPower:AddSpecialApply(sPos,sAttr,Val)
    local iIndex = self:GetIndex(sAttr)
    if not iIndex then return end
    local oSum = self.m_cSum
    local iMo = ADD_POS2MO[sPos]
    if table_in_list({"maxhp_ratio","attack_ratio","defense_ratio"},sAttr) then
        iMo = BR_POS2MO[sPos]
    end
    if not iMo then return end
    oSum:add(iIndex,iMo,Val)
end

function CCPower:Print(iMo)
    local oSum = self.m_cSum
    oSum:print(iMo)
end

function SyncPowerData(sType,mData)
    local mFliterData = {}
    local iIndex
    for sAttr,Val in pairs(mData) do
        iIndex = Attr2Index[sAttr]
        if iIndex then
            mFliterData[iIndex] = Val
        end
    end
    lsum.lsum_powerdata(sType,mFliterData)
end