local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"
local res = require "base.res"

local itembase = import(service_path("item/itembase"))
local itemdefines = import(service_path("item/itemdefines"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "equipstone"

function NewItem(sid)
    local o = CItem:New(sid)
    o.m_mApply = {}
    o.m_mRatioApply = {}
    o.m_mK = {}
    return o
end

function CItem:Load(mData)
    super(CItem).Load(self,mData)
    self.m_mApply = mData["apply"] or self.m_mApply
    self.m_mRatioApply = mData["ratio_apply"] or self.m_mRatioApply
    self.m_mK = mData["k"]
end

function CItem:Save()
    local mData = super(CItem).Save(self)
    mData["apply"] = self.m_mApply
    mData["ratio_apply"] = self.m_mRatioApply
    mData["k"] = self.m_mK
    return mData
end

function CItem:Level()
    return self:GetItemData()["level"]
end

function CItem:WieldPos()
    return self:GetItemData()["pos"]
end

--武器类型
function CItem:WeaponType()
    return self:GetItemData()["weapon_type"]
end

function CItem:Sex()
    return self:GetItemData()["sex"]
end

--套装类型
function CItem:SetType()
    return self:GetItemData()["set_type"]
end

function CItem:GetStoneShape()
    return self:SID()
end

function CItem:SkillLevel()
    return self:GetItemData()["skill_level"]
end

function CItem:CalculateK()
    local iLevel = self:Quality()
    if table_in_list({1,2},iLevel) then
        return 100
    end
    local mData = itemdefines.GetEquipWaveData()
    local mChoose = {}
    for i, m in ipairs(mData) do
        mChoose[i] = m["ratio"]
    end
    local id = table_choose_key(mChoose)
    local mLevelData = mData[id]
    local iMinRatio = mLevelData["min_ratio"]
    local iMaxRatio = mLevelData["max_ratio"]
    local iK = math.random(iMinRatio,iMaxRatio)
    return iK
end

function CItem:Create(...)
    local iQuality = self:Quality()
    local mQuality = itemdefines.GetEquipQualityData(iQuality)
    local iBaseRatio = mQuality["ratio"] or 100
    local mStoneData = self:GetItemData()
    local mAttrs = itemdefines.GetAttrData()
    for sAttr,_ in pairs(mAttrs) do
        local iValue = mStoneData[sAttr]
        if iValue and iValue > 0 then
            local iK = self:CalculateK()
            -- local iRatio = iK * iBaseRatio / 100
            iValue = math.floor(iValue * iK /100)
            self:SetK(sAttr,iK)
            self:AddApply(sAttr,iValue)
        end
    end
end

function CItem:SetK(sAttr,iRatio)
    self:Dirty()
    self.m_mK[sAttr] = iRatio
end

function CItem:SetLock()
    if self:IsLock() then
        self:SetData("lock", 0)
    else
        self:SetData("lock", 1)
    end
end

function CItem:IsLock()
    return self:GetData("lock", 0) == 1
end

function CItem:AddApply(sAttr,iValue)
    self:Dirty()
    self.m_mApply[sAttr] = iValue
end

function CItem:GetApply(sAttr,rDefault)
    return self.m_mApply[sAttr] or rDefault
end

function CItem:GetApplyList()
    return self.m_mApply or {}
end

function CItem:GetRatioApplyList()
    return self.m_mRatioApply or {}
end

function CItem:AddRatioApply(sAttr,iValue)
    self:Dirty()
    self.m_mRatioApply[sAttr] = iValue
end

function CItem:GetRatioApply(sAttr,rDefault)
    return self.m_mRatioApply[sAttr] or rDefault
end

function CItem:ResetApply()
    self:Dirty()
    self.m_mApply = {}
    self.m_mRatioApply = {}
    self.m_mK = {}
end

function CItem:ApplyInfo()
    local mData = {}
    for sAttr,iValue in pairs(self.m_mApply) do
        table.insert(mData,{key=sAttr,value=iValue})
    end
    for sAttr,iValue in pairs(self.m_mRatioApply) do
        table.insert(mData,{key=sAttr,value=iValue})
    end
    table.insert(mData, {key = "lock", value = self:GetData("lock")})
    table.insert(mData, {key = "equip_power", value = self:GetPower() + self:SEPower()})
    return mData
end

function CItem:StoneSE()
    local mData = res["daobiao"]["equip_se"][self:SID()] or {}
    return mData["skill_id"]
end

function CItem:SEPower()
    local mData = res["daobiao"]["equip_se"][self:SID()] or {}
    return mData.power or 0
end

function CItem:Model()
    return self:GetItemData()["model"]
end

function CItem:GetPower(iSchool)
    local oAssistMgr = global.oAssistMgr
    local iPower = 0
    local iPid = self:GetOwner()
    local oPlayer = oAssistMgr:GetOnlinePlayerByPid(iPid)
    local iSchool = iSchool or oPlayer:GetSchool()
    local mPower = res["daobiao"]["school_convert_power"][iSchool]
    assert(mPower, string.format("equip power err: %s, %s, %s", iPid, self:ID(), iSchool))

    local mAttrName = res["daobiao"]["attrname"]
    for sAttr, mAttr in pairs(mAttrName) do
        local iMul = mPower[sAttr] / 100
        iPower = iPower + self:GetApply(sAttr, 0) * iMul
    end
    return math.floor(iPower)
end

function CItem:PackSE()
    local m = res["daobiao"]["equip_se"][self:SID()]
    if m then
        local mRet = {}
        mRet[m.skill_id] = m.level
        return mRet
    end
    return nil
end

function CItem:PackApplyData(iSchool)
    return {
        shape = self:Shape(),
        name = self:Name(),
        apply_list = self:GetApplyList(),
        ratio_apply_list = self:GetRatioApplyList(),
        se = self:PackSE(),
        equip_power = self:GetPower(iSchool) + self:SEPower()
    }
end