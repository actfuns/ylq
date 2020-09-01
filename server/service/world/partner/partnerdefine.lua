local res = require "base.res"

PARTNER_AWAKE_TYPE = {
    ADD_SKILL = 1,                  --添加技能
    UNLOCK_SKILL = 2,           --解锁技能
    IMPROVE_SKILL = 3,         --强化技能
    ADD_ATTR = 4,                   --添加属性
}

EQUIP_PLAN_START = 1
EQUIP_PLAN_END = 2


function GetPartnerChipData(iChip)
    local mChipData = res["daobiao"]["partner_item"]["partner_chip"][iChip]
    assert(mChipData, string.format("partner chip data err: %s", iChip))
    return mChipData
end

function GetPartnerRareData(iRare)
    local mRareData = res["daobiao"]["partner"]["rare"][iRare]
    assert(mRareData, string.format("partner rare data err: %s", iRare))
    return mRareData
end

function GetPartnerDecomposeAmount(iPartnerId)
    local mRareData = res["daobiao"]["partner"]["partner_info"][iPartnerId]
    assert(mRareData, string.format("partner Decompose data err: %s", iPartnerId))
    return mRareData["decompose"]
end

function FormatPartnerColorName(iRare, sMsg)
    local mData = res["daobiao"]["partnercolor"][iRare]
    return string.format(sMsg, mData.color)
end