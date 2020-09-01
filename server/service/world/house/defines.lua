--import module
local global = require "global"


LOCK_STATUS = {
    LOCKED = 0,
    UNLOCKED = 1,
}

FURNITURE_STATUS = {
    NULL = 0,
    UP_LEVEL_NOTMEET = 1,            --不满足升级条件
    UP_LEVEL_MEET = 2,                    --满足升级条件
    UP_LEVEL_MEETING = 3,             --升级中
}

FURNITURE_TYPE = {
    NULL = 0,
    SOFA = 1,
    WORK_DESK = 2,
    CWAREHOUSE = 3,
    CPAN = 4,
    CBOOK = 5,
}

--工作台状态
WORKDESK_STATUS = {
    FREE = 1,                                      --闲置
    TALENT_SHOW = 2,                     --才艺展示
    TALENT_GIFT = 3,                        --礼物待领取
}

TRAIN_STATUS = {
    FREE = 0,                                       --未特训
    TRAINING = 1,                              --特训中
    TRAINED = 2,                                --特训完成
}

RANDOM_COIN_TIME = {
    MIN_TIME = 3 * 60 * 60,
    MAX_TIME = 6 * 60 * 60,
}

PARTNER_MAX_LOVE_CNT = 10
PARTNER_MAX_GIFT_CNT = 10

FURNITURE_UPLEVEL_ITEM = 12020
TOTAL_LOVE_BUFF_STAGE = 10

WORK_DESK_OPEN_LEVEL = 80

PARTNER_PART = {
    [1] = "head",
    [2] = "brease",
    [3] = "gold_point",
    [4] = "hand",
    [5] = "leg"
}

function GetDaobiaoDefines(sKey)
    local res = require "base.res"
    local mData = res["daobiao"]["housedefines"][sKey]
    assert(mData,string.format("housedefines err:%s",sKey))
    local iValue = mData["value"]
    return iValue
end

function GetFurnitureData(iType,iLevel)
    local res = require "base.res"
    local mData = res["daobiao"]["furniture"][iType]
    assert(mData,string.format("furniture err:%s",iType))
    mData = mData[iLevel]
    return mData
end

function GetFurnitureEffect(iType,iLevel)
    local mData = GetFurnitureData(iType,iLevel)
    local sEffect = mData["effect"]
    local mArgs = {}
    if not sEffect or sEffect == "" then
        return mArgs
    end
    mArgs = formula_string(sEffect,{})
    return mArgs
end

--灵感数据
function GetTalentGiftData()
    local res = require "base.res"
    return res["daobiao"]["talent_gift"]
end

function GetPartnerBodyPartName(iPart)
    return PARTNER_PART[iPart]
end

function GetPartnerPathData()
    local res = require "base.res"
    return res["daobiao"]["partner_path"]
end

function GetPartnerData()
    local res = require "base.res"
    return res["daobiao"]["housepartner"]
end

function GetWorkDeskData()
    local res = require "base.res"
    return res["daobiao"]["house_workdesk"]
end

function GetLoveBuffData(iStage)
    local res = require "base.res"
    return res["daobiao"]["house_lovebuff"][iStage]
end

function GetFurniture(iPid,iType)
    local oHouseMgr = global.oHouseMgr
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        return
    end
    local oFurniture = oHouse:GetFurniture(iType)
    return oFurniture
end

function GetFurnitureDesk(iPid,iPos)
    local oHouseMgr = global.oHouseMgr
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        return
    end
    local iType = FURNITURE_TYPE.WORK_DESK
    local oFurniture = oHouse:GetFurniture(iType)
    if not oFurniture then
        return
    end
    local oDesk = oFurniture:GetWorkDesk(iPos)
    return oDesk
end

function GetFriendDesk(iPid)
    local oHouseMgr = global.oHouseMgr
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        return
    end
    local iType = FURNITURE_TYPE.WORK_DESK
    local oFurniture = oHouse:GetFurniture(iType)
    if not oFurniture then
        return
    end
    return oFurniture:GetFriendWorkDesk()
end

function GetPartner(iPid,iType)
    local oHouseMgr = global.oHouseMgr
    local oHouse = oHouseMgr:GetHouse(iPid)
    if not oHouse then
        return
    end
    local oPartner = oHouse:GetPartner(iType)
    return oPartner
end