HONGBAO_MAX_CNT = 1000000000

local HONGBAO_TYPE = {
    orgchannel = "公会频道红包",
    worldchannel = "世界频道红包",
}

function GetHongBaoTypeName(sType)
    return HONGBAO_TYPE[sType]
end