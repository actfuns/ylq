local res = require "base.res"
local gamedefines = import(lualib_path("public.gamedefines"))

ORG_POSITION = gamedefines.ORG_POSITION

ORG_APPLY = {
    APPLY = 0,
    INVITED = 1,
}

function GetPositionName(iPosition)
    local mData = res["daobiao"]["org"]["member_limit"][iPosition]
    return mData["pos"]
end

function GetOrgOptionGrade()
    return tonumber(res["daobiao"]["org"]["rule"][1]["min_grade"])
end

function GetBuildData(iBuildType)
    local mData = res["daobiao"]["org"]["org_build"] or {}
    mData = mData[iBuildType]
    return mData
end

function GetOrgSignRewardData(idx)
    local mData = res["daobiao"]["org"]["org_sign_reward"]
    return mData[idx]
end

function GetOrgWishData(iRare)
    local mData = res["daobiao"]["org"]["org_wish"]
    return mData[iRare]
end

function GetOrgWishEquipData(sid)
    local mData = res["daobiao"]["org"]["org_equip_wish"]
    return mData[sid]
end

function GetHongBaoData()
    local mData = res["daobiao"]["org"]["org_hongbao"]
    return mData
end

function GetHongBaoRatio()
    local mData = res["daobiao"]["org"]["hongbao_ratio"]
    return mData
end