-- import module

local PLATFORM = import(lualib_path("public.gamedefines")).PLATFORM
local PUBLISHER = import(lualib_path("public.gamedefines")).PUBLISHER

SERVER_DESC = {
    all = 0,
    kp_mix = 1,
    kp_android = 2,
    kp_ios = 3,
    kp_pioneer = 4,
    sm_mix = 5,
    sm_android = 6,
    sm_ios = 7,
}

SERVER_DESC_NAME = {
    [SERVER_DESC.all] = "全类型服",
    [SERVER_DESC.kp_mix] = "混服-靠谱",
    [SERVER_DESC.kp_android] = "安卓-靠谱",
    [SERVER_DESC.kp_ios] = "IOS-靠谱",
    [SERVER_DESC.kp_pioneer] = "官方测试服-靠谱",

    [SERVER_DESC.sm_mix] = "混服-手盟",
    [SERVER_DESC.sm_android] = "安卓-手盟",
    [SERVER_DESC.sm_ios] = "IOS-手盟",
}

PUBLISHER_MATCH = {
    [SERVER_DESC.all] = PUBLISHER.none,
    [SERVER_DESC.kp_mix] = PUBLISHER.kp,
    [SERVER_DESC.kp_android] = PUBLISHER.kp,
    [SERVER_DESC.kp_ios] = PUBLISHER.kp,      
    [SERVER_DESC.kp_pioneer] = PUBLISHER.kp,

    [SERVER_DESC.sm_mix] = PUBLISHER.sm,
    [SERVER_DESC.sm_android] = PUBLISHER.sm,
    [SERVER_DESC.sm_ios] = PUBLISHER.sm,
}

PLATFORM_MATCH = {
    [SERVER_DESC.all] = {PLATFORM.android, PLATFORM.rootios, PLATFORM.ios, PLATFORM.pc},

    [SERVER_DESC.kp_mix] = {PLATFORM.android, PLATFORM.rootios, PLATFORM.ios, PLATFORM.pc},
    [SERVER_DESC.kp_android] = {PLATFORM.android, PLATFORM.pc},
    [SERVER_DESC.kp_ios] = {PLATFORM.rootios, PLATFORM.ios, PLATFORM.pc},
    [SERVER_DESC.kp_pioneer] = {PLATFORM.android, PLATFORM.pc},

    [SERVER_DESC.sm_mix] = {PLATFORM.android, PLATFORM.rootios, PLATFORM.ios, PLATFORM.pc},
    [SERVER_DESC.sm_android] = {PLATFORM.android, PLATFORM.pc},
    [SERVER_DESC.sm_ios] = {PLATFORM.rootios, PLATFORM.ios, PLATFORM.pc},
}

CHANNEL_MATCH = {
    [SERVER_DESC.all] = "all",
    [SERVER_DESC.kp_mix] = "kp_mix",
    [SERVER_DESC.kp_android] = "kp_android",
    [SERVER_DESC.kp_ios] = "kp_ios",
    [SERVER_DESC.kp_pioneer] = {1039,},

    [SERVER_DESC.sm_mix] = "sm_mix",
    [SERVER_DESC.sm_android] = "sm_android",
    [SERVER_DESC.sm_ios] = "sm_ios",
}

CPS_CHANNEL_MATCH = {
    [SERVER_DESC.all] = "all",

    [SERVER_DESC.kp_mix] = "all",
    [SERVER_DESC.kp_android] = "all",
    [SERVER_DESC.kp_ios] = "all",
    [SERVER_DESC.kp_pioneer] = "all",

    [SERVER_DESC.sm_mix] = "all",
    [SERVER_DESC.sm_android] = "all",
    [SERVER_DESC.sm_ios] = "all",
}


function get_server_desc_name(server_desc)
    return SERVER_DESC_NAME[server_desc]
end

function get_publisher(server_desc)
    return PUBLISHER_MATCH[server_desc]
end

function is_matched_publisher(server_desc, publisher)
    local pub_match = PUBLISHER_MATCH[server_desc]
    if pub_match == PUBLISHER.none then
        return true
    else
        return pub_match == publisher
    end
end

function get_open_platforms(server_desc)
    return PLATFORM_MATCH[server_desc]
end

function get_open_channels(server_desc)
    local res = require "base.res"
    local channel = CHANNEL_MATCH[server_desc]
    if channel == "all" then
        return res["daobiao"]["allchannel"]
    elseif type(channel) == "string" then
        return res["daobiao"]["platchannel"][channel]
    else
        return channel
    end
end

function is_opened_cps(server_desc, cps)
    local cps_ps = CPS_CHANNEL_MATCH[server_desc]
    if cps_ps == "all" then
        return true
    else
        local bDefault = true
        for _, cps_p in ipairs(cps_ps) do
            if string.sub(cps_p, 1, 1) == "-" then
                if string.match(cps, string.sub(cps_p, 2, -1)) then
                    return false
                end
            else
                bDefault = false
                if string.match(cps, cps_p) then
                    return true
                end
            end
        end

        return bDefault
    end
end