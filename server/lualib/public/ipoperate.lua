--import module

function ip2number(sIp)
    local a, b, c, d = string.match(sIp, "(%d+)%.(%d+)%.(%d+)%.(%d+)")
    a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
    return math.floor((a << 24) | (b << 16) | (c << 8) | d)
end

function trans_subnet(sSubnet)
    local sNet, sMask = string.match(sSubnet, "([%d%.]+)%/(%d+)")
    return ip2number(sNet), tonumber(sMask)
end

function is_white_ip(sIp)
    if not sIp then
        return false
    end
    local mWhiteIp = {
        "112.94.5.240/28",      -- liantong
         "219.135.195.92/32",    -- dianxin
         "218.107.21.194/32",   --cilu
         "218.107.21.119/32",
         "61.144.119.153/32",
         "27.47.192.218/32",
         "27.47.155.81/32",
         "110.80.152.38/32",    --kaopu
         "110.80.152.206/32",   --kaopu
         "122.96.92.230/32",    --kaopu
         "110.80.152.11/32",   --kaopu
         "14.29.126.61/32",      --shoumeng
    }
    local iIpNumber = ip2number(sIp)
    for _, sSubnet in ipairs(mWhiteIp) do
        local iNetNumber, iIpMask = trans_subnet(sSubnet)
        local bit = 32 - tonumber(iIpMask)
        if ((iIpNumber >> bit) << bit) == ((iNetNumber >> bit) << bit) then
            return true
        end
    end
    return false
end
