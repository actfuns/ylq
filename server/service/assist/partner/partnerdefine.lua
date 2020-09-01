local res = require "base.res"

EQUIP_PLAN_START = 1
EQUIP_PLAN_END = 2

CHIP_MAX_OVERLAY = 99999                --碎片叠加上限
AWAKE_ITEM_MAX_OVERLAY = 99999  --觉醒道具叠加上限
PARTNER_OVERLAY = 3000                 --伙伴数量上限

PARTNER_LIST_PAGE = 200

MIN_PARTNER_STAR = 1 --伙伴最低星级
MAX_PARTNER_STAR = 5 --伙伴最高星级

MERGE_PARTNER = {1754} --合并伙伴

UPSKILL_ITEM = 14011 --伙伴技能消耗道具
UPGRADE_ITEM = 14001 --伙伴升级消耗道具

MASTER_CHIP = 14002 --万能碎片


function GetPartnerChipData(iChip)
    local mChipData = res["daobiao"]["partner"]["partner_chip"][iChip]
    assert(mChipData, string.format("partner chip data err: %s", iChip))
    return mChipData
end

function GetPartnerRareData(iRare)
    local mRareData = res["daobiao"]["partner"]["rare"][iRare]
    assert(mRareData, string.format("partner rare data err: %s", iRare))
    return mRareData
end

function GetParSkillGuideData(iParType, iCount)
    local mGuideData = res["daobiao"]["partner"]["skill_guide"][iParType]
    return mGuideData and mGuideData[iCount]
end

function GetPartnerTitle(iTid)
    local mData = res["daobiao"]["title"]["title"][iTid]
    return mData
end

function GetChipByParType(iParType)
    local iChipSid = res["daobiao"]["partner_item"]["partype2chip"][iParType]
    return iChipSid
end

function GetPartnerData(iSid)
    local res = require "base.res"
    local mData = res["daobiao"]["partner"]["partner_info"][iSid]
    -- assert(mData, string.format("partner data :%s not exist!", iSid))
    return mData
end

function FormatPartnerColorName(iRare, sMsg)
    local mData = res["daobiao"]["partnercolor"][iRare]
    return string.format(sMsg, mData.color)
end

function PartnerColorName(iParType)
    local mData = GetPartnerData(iParType)
    if mData then
        local res = require "base.res"
        local mColor = res["daobiao"]["partnercolor"][mData.rare]
        if mColor then
            return string.format(mColor.color, mData.name)
        end
    end
    return ""
end