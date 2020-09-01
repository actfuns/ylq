--import module

local serverinfo = import(lualib_path("public.serverinfo"))

BACKEND = {
    backend = {
        host = serverinfo.get_cs_host(),
        url = "/backend",
    },
}

URLDEMI = {
    prefix = "/demisdk",
    dev_prefix = "/demisdkdev",
    url = {
        channel_verify = "/v1/sdkc/area/info.json",
        login_verify = "/v1/sdkc/integration/verify.json",
        pre_pay = "/v1/sdkc/integration/prePay.json",
    }
}

XGPUSH = {
    prefix = "/xgpush",
    url = {
        single_account = "/v2/push/single_account",
        single_device = "/v2/push/single_device",
    }
}

URLKAOPU = {
    prefix = "/kpreport/game",
    url_ios = {
        userlogin = "/userlogin/1438",
        usernumberonline  = "/usernumberonline/1438",
        GainMoney = "/GainMoney/1438",
        consume = "/consume/1438",
    },
    url_android = {
        userlogin = "/userlogin/1305",
        usernumberonline  = "/usernumberonline/1305",
        GainMoney = "/GainMoney/1305",
        consume = "/consume/1305",
    }
}

function get_out_host()
    return serverinfo.get_out_host()
end

function get_xg_url(key)
    return XGPUSH.prefix..XGPUSH.url[key]
end

function get_demi_url(key)
    local sPrefix
    if serverinfo.DEMI_SDK.pro_env then
        sPrefix = URLDEMI.prefix
    else
        sPrefix = URLDEMI.dev_prefix
    end
    local sUrl = URLDEMI.url[key]
    return sPrefix..sUrl
end

function get_kaopu_url(splatform,key)
    local sPrefix = URLKAOPU.prefix
    local sUrl = URLKAOPU["url_"..splatform][key]
    if not sUrl then
        return
    end
    return sPrefix..sUrl
end