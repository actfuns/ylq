local global = require "global"
local extend = require "base/extend"

local loaditem = import(service_path("item/loaditem"))

local function GetEquipAttrData()
    local res = require "base.res"
    return res["daobiao"]["equip_attr"]
end

local function GetAttrData()
    local res = require "base.res"
    return res["daobiao"]["attrname"]
end

local function GetEquipWaveData()
    local res = require "base.res"
    return res["daobiao"]["equip_wave"]
end

local function GetEquipQualityData(iQuality)
    local res = require "base.res"
    local mData = res["daobiao"]["equip_quality"][iQuality]
    assert(mData,string.format("equip_quality err:%d",iQuality))
    return mData
end

--计算波动系数
function CalculateK(oEquip)
    local iLevel = oEquip:GetData("equip_level",1)
    if iLevel == 1 then
        return 100
    end
    local mData = GetEquipWaveData()
    local mLevelData = mData[iLevel]
    local iMinRatio = mLevelData["min_ratio"]
    local iMaxRatio = mLevelData["max_ratio"]
    local iK = math.random(iMinRatio,iMaxRatio)
    return iK
end

function MakeEquip(oEquip,mArgs)
    mArgs = mArgs or {}
    local iEquipLevel = mArgs.equip_level
    local iStoneShape = mArgs.equip_stone                   --装备石
    if not iEquipLevel then
        iEquipLevel = 1
    end
    oEquip:SetData("equip_level",iEquipLevel)
    if iStoneShape then
        CalculateApply(oEquip,iStoneShape)
    end
end

function CalculateApply(oEquip,iStoneShape)
    local iQuality = oEquip:GetData("equip_level")
    local mQuality = GetEquipQualityData(iQuality)
    local iBaseRatio = mQuality["ratio"] or 100
    local oStone = loaditem.GetItem(iStoneShape)
    local mStoneData = oStone:GetItemData()
    local mAttrs = itemdefines.GetAttrData()
    for sAttr,_ in pairs(mAttrs) do
        local iValue = mStoneData[sAttr]
        if iValue and iValue > 0 then
            local iK = CalculateK(oEquip)
            local iRatio = iK * iBaseRatio / 100
            iValue = math.floor(iValue * iRatio /100)
            oEquip:AddApply(sAttr,iValue)
        end
    end
end