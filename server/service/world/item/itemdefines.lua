ITEM_KEY_BIND = 1                               --绑定
ITEM_KEY_TIME = 2                               --时效道具

EQUIP_WEAPON  =  1
EQUIP_NECK = 2
EQUIP_CLOTH = 3
EQUIP_RING = 4
EQUIP_BELT = 5
EQUIP_SHOE = 6
EQUIP_BACK_WEAPON = 11

CONTAINER_TYPE = {
    COMMON = 1,     --普通道具
    MATERIAL = 2,   --材料
    GEM = 3,            --宝石
    EQUIP = 4,          --角色装备
    PARTNER_EQUIP = 5, --伙伴符文装备
    EQUIP_STONE = 6,       --装备灵石
    PARTNER_CHIP = 7, --伙伴碎片
    PARTNER_AWAKE = 8, --伙伴觉醒道具
    PARTNER_SKIN = 9,   --伙伴皮肤
    PARTNER_TRAVEL = 10, --游历道具
    PARTNER_STONE = 11, --伙伴符石
}

local mApplyName = {
    ["attack"] = "攻击",
    ["defnese"] = "防御",
    ["hp"] = "气血",
    ["speed"] = "速度",
}

function GetApplyName(sAttr)
    return mApplyName[sAttr] or ""
end

function GetEquipFuWen(oEquip)
    local iPos = oEquip:EquipPos()
    local iLevel = oEquip:EquipLevel()
    local iFuWenShape = 19000 + (iPos -1) * 100 + iLevel // 10
    return iFuWenShape
end

function GetEquipShape(oPlayer,iPos,iLevel)
    local iShape
    if iPos == 1 then
        --
    else
        local iSex = oPlayer:GetSex()
        if table_in_list({EQUIP_CLOTH,EQUIP_BELT,EQUIP_SHOE},iPos) then
            iShape = 20000 + iPos * 1000 + iSex * 100 + iLevel // 10
        else
            iShape = 20000 + iPos * 1000 + iLevel // 10
        end
        return iShape*100
    end
    return iShape
end

function GetEquipStoneShape(oPlayer, iPos, iLevel, iQuality, iWeapon)
    local iShape
    if iPos == 1 then
        iShape = 30000 + iWeapon * 1000 + (iQuality -1) *20 + iLevel // 10
    else
        local iSex = oPlayer:GetSex()
        if table_in_list({EQUIP_CLOTH,EQUIP_BELT,EQUIP_SHOE},iPos) then
            iShape = 40000 + (iPos - 2) * 1000 + (iSex - 1) * 100 + (iQuality -1) *20 + iLevel // 10
        else
            iShape = 40000 + (iPos - 2) * 1000 + (iQuality -1) *20 + iLevel // 10
        end
    end

    return iShape * 100
end

function GetEquipAttrData()
    local res = require "base.res"
    return res["daobiao"]["equip_attr"]
end

function GetAttrData()
    local res = require "base.res"
    return res["daobiao"]["attrname"]
end

function GetEquipWaveData()
    local res = require "base.res"
    return res["daobiao"]["equip_wave"]
end

function GetEquipQualityData(iQuality)
    local res = require "base.res"
    local mData = res["daobiao"]["equip_quality"][iQuality]
    assert(mData,string.format("equip_quality err:%d",iQuality))
    return mData
end

function GetFuWenData(iEquipPos, iEquipLevel)
    local res = require "base.res"
    local record = require "public.record"
    local mData = res["daobiao"]["fuwen"][iEquipPos][iEquipLevel]
    assert(mData, string.format("equip fuwen data err: %s, %s", iEquipPos, iEquipLevel))
    return mData
end

function GetFuWenQualityData(iQuality, iLevel)
    local res = require "base.res"
    local record = require "public.record"
    local mData = res["daobiao"]["fuwen_quality"][iQuality]
    mData = mData and mData[iLevel]
    assert(mData, string.format("equip fuwen_quality data err: %s ,%s", iQuality, iLevel))
    return mData
end

function GetPartnerEquipStarData(iStar)
    local res = require "base.res"
    local mStarData = res["daobiao"]["partner_item"]["equip_star"][iStar]
    assert(mStarData, string.format("partner equip data error:%s", iStar))
    return mStarData
end

function GetSchoolWeaponType(iSchool, iBranch)
    local res = require "base.res"
    local mWeaponData = res["daobiao"]["schoolweapon"]["weapon"][iSchool][iBranch]
    assert(mWeaponData, string.format("schoolweapon config not exist! %s, %s", iSchool, iBranch))
    return mWeaponData.weapon
end

function GetItemData(iShape)
    local res = require "base.res"
    local mItem = res["daobiao"]["item"][iShape]
    assert(iShape, string.format("item config id:%s not exist!", iShape))
    return mItem
end

function GetComposeEquipData(iPos, iGrade)
    local res = require "base.res"
    local mData = res["daobiao"]["equip_compose"][iPos]
    if mData then
        return mData[iGrade]
    end
    return nil
end

function GetPartnerEquipShape(iPos, iStar, iLevel)
    return 6000000 + iPos * 100000 + iStar * 1000 + iLevel
end

function GetPartnerStoneShape(iPos, iLevel)
    return 300000 + iPos * 10000 + iLevel
end

function GetParEquipStarData(iStar)
    local res = require "base.res"
    local mItem = res["daobiao"]["partner_item"]["equip_star"]
    return mItem[iStar]
end

function GetParStonePosData(iPos)
    local res = require "base.res"
    local mItem = res["daobiao"]["partner_item"]["stone_pos"]
    return mItem[iPos]
end


function GetParSoulPosData(iPos)
    local res = require "base.res"
    local mItem = res["daobiao"]["partner_item"]["soul_pos"]
    return mItem[iPos]
end

function GetParSoulTypeData(iSoulType)
    local res = require "base.res"
    local mItem = res["daobiao"]["partner_item"]["soul_set"]
    return mItem[iSoulType]
end

function GetEquipExchangeData(iEquipSid)
    local res = require "base.res"
    local mData = res["daobiao"]["exchange_equip"][iEquipSid]
    return mData
end

--根据品质随机御灵
function RandomParSoulByQuality(iSetType, iQuality, iAttrType)
    local res = require "base.res"
    if not iSetType then
        local mSet = res["daobiao"]["partner_item"]["soul_set"]
        iSetType = table_random_key(mSet)
    end
    if not iQuality then
        local mQuality = res["daobiao"]["partner_item"]["soul_quality"]
        iQuality = table_random_key(mQuality)
    end
    if not iAttrType then
        local mAttr = res["daobiao"]["partner_item"]["soul_attr"]
        iAttrType = table_random_key(mAttr)
    end

    return 7000000 + iSetType * 10000 + iQuality * 100 + iAttrType
end

NOT_EXIST_ITEM = {
        [21051] = 1,
        [21052] = 1,
        [21061] = 1,
        [21062] = 1,
        [21151] = 1,
        [21152] = 1,
        [21161] = 1,
        [21162] = 1,
        [21251] = 1,
        [21252] = 1,
        [21261] = 1,
        [21262] = 1,
        [21351] = 1,
        [21352] = 1,
        [21361] = 1,
        [21362] = 1,
        [21451] = 1,
        [21452] = 1,
        [21461] = 1,
        [21462] = 1,
        [21551] = 1,
        [21552] = 1,
        [21561] = 1,
        [21562] = 1,
        [21651] = 1,
        [21652] = 1,
        [21661] = 1,
        [21662] = 1,
        [23051] = 1,
        [23052] = 1,
        [23061] = 1,
        [23062] = 1,
        [23151] = 1,
        [23152] = 1,
        [23161] = 1,
        [23162] = 1,
        [23251] = 1,
        [23252] = 1,
        [23261] = 1,
        [23262] = 1,
        [23351] = 1,
        [23352] = 1,
        [23361] = 1,
        [23362] = 1,
        [24051] = 1,
        [24052] = 1,
        [24061] = 1,
        [24062] = 1,
        [24151] = 1,
        [24152] = 1,
        [24161] = 1,
        [24162] = 1,
        [24251] = 1,
        [24252] = 1,
        [24261] = 1,
        [24262] = 1,
        [24351] = 1,
        [24352] = 1,
        [24361] = 1,
        [24362] = 1,
        [24451] = 1,
        [24452] = 1,
        [24461] = 1,
        [24462] = 1,
        [25051] = 1,
        [25052] = 1,
        [25061] = 1,
        [25062] = 1,
        [25151] = 1,
        [25152] = 1,
        [25161] = 1,
        [25162] = 1,
        [25251] = 1,
        [25252] = 1,
        [25261] = 1,
        [25262] = 1,
        [25351] = 1,
        [25352] = 1,
        [25361] = 1,
        [25362] = 1,
        [25451] = 1,
        [25452] = 1,
        [25461] = 1,
        [25462] = 1,
        [25551] = 1,
        [25552] = 1,
        [25561] = 1,
        [25562] = 1,
}