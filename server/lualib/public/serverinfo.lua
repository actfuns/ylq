--import module
local skynet = require "skynet"
local serverdefines = require "public.serverdefines"

local serverdesc = import(lualib_path("public.serverdesc"))

if get_server_cluster() == "pro" then
    CS_INFO = {
        ip = "172.18.123.208", domain = "csn1.cilugame.com",
    }
    BS_INFO = {
        ip = "172.18.123.216", domain = "bsn1.cilugame.com"
    }
    KS_INFO = {
        ip = "172.18.123.208"
    }
    ROUTER_IP = "172.18.123.208"
    GS_INFO = {
        ["pro_gs20001"] = {name= "妖之轨迹",master_db_ip = "172.18.123.210", http_host = "172.18.123.210",slave_db_ip = "172.18.123.206", slave_db_port = 27017,
        client_host = "120.79.155.163", desc = serverdesc.SERVER_DESC.sm_mix,open_game={"ylq","ylwy","ylzh","ylqy","yjwz","mmwy"},
        },
        ["pro_gs20002"] = {name= "圣之制裁",master_db_ip = "172.18.14.122", http_host = "172.18.14.122",slave_db_ip = "172.18.123.206", slave_db_port = 27020,
        client_host = "120.79.184.63", desc = serverdesc.SERVER_DESC.sm_mix,open_game={"ylq","ylwy","ylzh","ylqy","yjwz","mmwy"},
        },
        ["pro_gs20003"] = {name= "千钧之戟",master_db_ip = "172.18.123.220", http_host = "172.18.123.220",slave_db_ip = "172.18.123.206", slave_db_port = 27015,
        client_host = "119.23.212.90", desc = serverdesc.SERVER_DESC.sm_mix,open_game={"ylq","ylwy","ylzh","ylqy","yjwz","mmwy"},
        },
    }
    OUT_HOST = "172.18.123.218:80"
    DEMI_SDK = {
        pro_env = true,app_id = 2, app_key = "AqF6txOQ9iXQAttP", machine_id = 2
    }
    KAOPU_REPORT = {
        android_app_id = 10481001,
        ios_app_id = 10481002,
    }
elseif get_server_cluster() == "testwaifu" then
    CS_INFO = {
        ip = "172.18.123.216",
    }
    BS_INFO = {
        ip = "172.18.123.216",
    }
    KS_INFO = {
        ip = "172.18.123.216"
    }
    ROUTER_IP = "172.18.123.216"
    GS_INFO = {
        ["testwaifu_gs20002"] = {name= "言叶之庭",master_db_ip = "172.18.123.216", http_host = "172.18.123.216",slave_db_ip = "172.18.123.216", slave_db_port = 27019,
        client_host = "39.108.81.182", desc = serverdesc.SERVER_DESC.all,open_game={"ylq","ylwy"},
        }
    }
    OUT_HOST = "172.18.123.218:80"
    DEMI_SDK = {
        pro_env = true,app_id = 2, app_key = "AqF6txOQ9iXQAttP", machine_id = 2
    }
    KAOPU_REPORT = {
        android_app_id = 10481001,
        ios_app_id = 10481002,
    }
elseif get_server_cluster() == "cbt" then
    CS_INFO = {
        ip = "172.18.205.11", domain = "cbtn1.cilugame.com"
    }
    BS_INFO = {
        ip = "172.18.205.11",domain = "cbtn1.cilugame.com"
    }
    KS_INFO = {
        ip = "172.18.205.11"
    }
    ROUTER_IP = "127.0.0.1"
    GS_INFO = {
        ["cbt_gs10001"] = {name="删档测试服",master_db_ip = "127.0.0.1",http_host = "127.0.0.1",slave_db_ip = "127.0.0.1", slave_db_port = 27017,
        client_host = "119.23.202.42", desc = serverdesc.SERVER_DESC.kp_mix,open_game={"ylq"},
        }
    }
    OUT_HOST = "172.18.123.218:80"
    DEMI_SDK = {
        pro_env = true,app_id = 8, app_key = "XdfOIJDFLDFj", machine_id = 2
    }
    KAOPU_REPORT = {
        android_app_id = 10481001,
        ios_app_id = 10481002,
    }
elseif get_server_cluster() == "bus" then
    CS_INFO = {
        ip = "127.0.0.1", domain = "businessn1.cilugame.com"
    }
    BS_INFO = {
        ip = "127.0.0.1", domain = "businessn1.cilugame.com"
    }
    KS_INFO = {
        ip = "127.0.0.1", domain = "businessn1.cilugame.com"
    }
    ROUTER_IP = "127.0.0.1"
    GS_INFO = {
        ["bus_gs10001"] = {name="刀剑神域",master_db_ip = "127.0.0.1", http_host = "127.0.0.1",slave_db_ip = "127.0.0.1", slave_db_port = 27017,
        client_host = "businessn1.cilugame.com", desc = serverdesc.SERVER_DESC.all,open_game={"ylq","lhsh","ylwy","ylzjb"},
        }--英梨梨2019.9.4
    }
    OUT_HOST = "127.0.0.1:80"
    DEMI_SDK = {
        pro_env = true,app_id = 2, app_key = "AqF6txOQ9iXQAttP", machine_id = 2
    }
    KAOPU_REPORT = {
        android_app_id = 10481001,
        ios_app_id = 10481002,
    }
elseif get_server_cluster() == "shenhe" then
    CS_INFO = {
        ip = "172.18.123.213",domain = "shenhen1.cilugame.com"
    }
    BS_INFO = {
        ip = "172.18.123.213",
    }
    KS_INFO = {
        ip = "172.18.123.213",
    }
    ROUTER_IP = "127.0.0.1"
    GS_INFO = {
        ["shenhe_gs10001"] = {name="渠道审核服",master_db_ip = "172.18.123.213",http_host = "172.18.123.213",slave_db_ip="172.18.123.213",slave_db_port = 27017,
        client_host = "shenhen1.cilugame.com", desc = serverdesc.SERVER_DESC.all,open_game={"ylq"},
        }
    }
    OUT_HOST = "172.18.123.218:80"
    DEMI_SDK = {
        pro_env = true,app_id = 2, app_key = "AqF6txOQ9iXQAttP", machine_id = 2
    }
    KAOPU_REPORT = {
        android_app_id = 10481001,
        ios_app_id = 10481002,
    }
elseif get_server_cluster() == "iosshenhe" then
    CS_INFO = {
        ip = "172.18.205.7",domain = "iosshenhen1.cilugame.com"
    }
    BS_INFO = {
        ip = "172.18.205.7",
    }
    KS_INFO = {
        ip = "172.18.205.7",
    }
    ROUTER_IP = "127.0.0.1"
    GS_INFO = {
        ["iosshenhe_gs10001"] = {name="ios审核服",master_db_ip = "172.18.205.7",http_host = "172.18.205.7",slave_db_ip="172.18.205.7",slave_db_port = 27017,
        client_host = "iosshenhen1.cilugame.com", desc = serverdesc.SERVER_DESC.all,open_game={"ylq","ylwy","ylzh","ylqy","ylzjb"},
        }
    }
    OUT_HOST = "172.18.123.218:80"
    DEMI_SDK = {
        pro_env = true,app_id = 2, app_key = "AqF6txOQ9iXQAttP", machine_id = 2
    }
    KAOPU_REPORT = {
        android_app_id = 10481001,
        ios_app_id = 10481002,
    }
elseif get_server_cluster() == "adapt" then
    CS_INFO = {
        ip = "10.13.94.33", slave_db_ip = "10.13.94.33" , slave_db_port = 27017
    }
    BS_INFO = {
        ip = "10.13.94.33"
    }
    KS_INFO = {
        ip = "10.13.94.33"
    }
    ROUTER_IP = "10.13.94.33"
    GS_INFO = {
        ["adapt_gs10001"] = {name="适配服",master_db_ip = "10.13.94.33",http_host = "10.13.94.33",slave_db_ip="10.13.94.33",slave_db_port = 27017,
        client_host = "106.75.138.9", desc = serverdesc.SERVER_DESC.kp_mix,open_game={"ylq"}
        }
    }
    OUT_HOST = "127.0.0.1:2001"
    DEMI_SDK = {
        pro_env = false,app_id = 2, app_key = "AqF6txOQ9iXQAttP", machine_id = 2
    }
    KAOPU_REPORT = {
        android_app_id = 10481001,
        ios_app_id = 10481002,
    }
elseif get_server_cluster() == "dev" then
    CS_INFO = {
        ip = "127.0.0.1", domain = "g58.n1.cilugame.com", slave_db_ip = "127.0.0.1" , slave_db_port = 27017
    }
    BS_INFO = {
        ip = "127.0.0.1", domain = "g58.n1.cilugame.com"
    }
    KS_INFO = {
        ip = "127.0.0.1", domain = "g58.n1.cilugame.com"
    }
    ROUTER_IP = "127.0.0.1"
    GS_INFO = {
        ["dev_gs10001"] = {name="开发服",master_db_ip = "127.0.0.1", http_host = "127.0.0.1",slave_db_ip = "127.0.0.1", slave_db_port = 27017,
        client_host = "192.168.1.224", desc = serverdesc.SERVER_DESC.all,open_game={"ylq","lhsh","ylwy"},
        }
    }
    OUT_HOST = "127.0.0.1:2001"
    DEMI_SDK = {
        pro_env = false,app_id = 8, app_key = "test2", machine_id = 2
    }
    KAOPU_REPORT = {
        android_app_id = 10481001,
        ios_app_id = 10481002,
    }
elseif get_server_cluster() == "outertest" then
    CS_INFO = {
        ip = "127.0.0.1", domain = "testn1.cilugame.com", slave_db_ip = "127.0.0.1" , slave_db_port = 27017
    }
    BS_INFO = {
        ip = "127.0.0.1", domain = "testn1.cilugame.com"
    }
    KS_INFO = {
        ip = "127.0.0.1", domain = "testn1.cilugame.com"
    }
    ROUTER_IP = "127.0.0.1"
    GS_INFO = {
        ["outertest_gs10001"] = {name="外网测试服",master_db_ip = "127.0.0.1", http_host = "127.0.0.1",slave_db_ip = "127.0.0.1", slave_db_port = 27017,
        client_host = "testn1.cilugame.com", desc = serverdesc.SERVER_DESC.all,open_game={"ylq","lhsh","ylwy","ylzjb","yjwz"},
        }
    }
    OUT_HOST = "172.18.123.218:80"
    DEMI_SDK = {
        pro_env = true,app_id = 2, app_key = "AqF6txOQ9iXQAttP", machine_id = 2
    }
    KAOPU_REPORT = {
        android_app_id = 10481001,
        ios_app_id = 10481002,
    }
elseif get_server_cluster() == "branchtest" then
    CS_INFO = {
        ip = "127.0.0.1", domain = "g58.n1.cilugame.com", slave_db_ip = "127.0.0.1" , slave_db_port = 27017
    }
    BS_INFO = {
        ip = "127.0.0.1", domain = "g58.n1.cilugame.com"
    }
    KS_INFO = {
        ip = "127.0.0.1", domain = "g58.n1.cilugame.com"
    }
    ROUTER_IP = "127.0.0.1"
    GS_INFO = {
        ["branchtest_gs10001"] = {name="分支测试服",master_db_ip = "127.0.0.1", http_host = "127.0.0.1",slave_db_ip = "127.0.0.1", slave_db_port = 27017,
        client_host = "192.168.8.138", desc = serverdesc.SERVER_DESC.all,open_game={"ylq","lhsh","yaolingwuyu"},
        }
    }
    OUT_HOST = "127.0.0.1:2001"
    DEMI_SDK = {
        pro_env = false,app_id = 8, app_key = "test2", machine_id = 2
    }
    KAOPU_REPORT = {
        android_app_id = 10481001,
        ios_app_id = 10481002,
    }
elseif get_server_cluster() == "pressure" then
    CS_INFO = {
        ip = "192.168.8.157", domain = "g58.n1.cilugame.com", slave_db_ip = "127.0.0.1" , slave_db_port = 27017
    }
    BS_INFO = {
        ip = "192.168.8.157", domain = "g58.n1.cilugame.com"
    }
    KS_INFO = {
        ip = "192.168.8.131", domain = "g58.n1.cilugame.com"
    }
    ROUTER_IP = "192.168.8.157"
    GS_INFO = {
        ["pressure_gs10001"] = {name="压测服",master_db_ip = "127.0.0.1", http_host = "127.0.0.1",slave_db_ip = "127.0.0.1", slave_db_port = 27017,
        client_host = "g58.n1.cilugame.com", desc = serverdesc.SERVER_DESC.all,
        },
        --[[ 暂时屏蔽
        ["pressure_gs10002"] = {name="压测服",master_db_ip = "127.0.0.1", http_host = "127.0.0.1",slave_db_ip = "127.0.0.1", slave_db_port = 27017,
        client_host = "g58.n1.cilugame.com", desc = serverdesc.SERVER_DESC.all,
        }
        ]]
    }
    OUT_HOST = "127.0.0.1:2001"
    DEMI_SDK = {
        pro_env = false,app_id = 8, app_key = "test2", machine_id = 2
    }
    KAOPU_REPORT = {
        android_app_id = 10481001,
        ios_app_id = 10481002,
    }
end

function get_cs_ip()
    return CS_INFO["ip"]
end

function get_cs_host()
    return string.format("%s:%d",get_cs_ip(),CS_WEB_PORT)
end

function get_router_host()
    return ROUTER_IP
end

function get_cs_domain()
    return CS_INFO["domain"]
end

function get_out_host()
    return OUT_HOST
end

function get_gs_host(serverkey)
    if not GS_INFO[serverkey] then
        return
    end
    return string.format("%s:%d",GS_INFO[serverkey]["http_host"],serverdefines.GS_WEB_PORT)
end

function get_local_dbs()
    local host = "127.0.0.1"
    local sUser = MONGO_USER
    local sPwd = MONGO_PWD
    if is_cs_server() then
        host = CS_INFO["ip"]
    elseif is_bs_server() then
        host = BS_INFO["ip"]
    elseif is_ks_server() then
        host = KS_INFO["ip"]
    else
        host = GS_INFO[get_server_key()]["master_db_ip"]
    end
    return {
        game = {host=host, port=27017,username=sUser,password=sPwd},
        gamelog = {host=host, port=27017,username=sUser,password=sPwd},
        unmovelog = {host=host, port=27017,username=sUser,password=sPwd},
        backend = {host=host, port=27017,username=sUser,password=sPwd},
        datacenter = {host=host, port=27017,username=sUser,password=sPwd},
        chatlog = {host=host, port=27017,username=sUser,password=sPwd},
    }
end

function get_slave_dbs(serverkeys)
    serverkeys = serverkeys or table_key_list(GS_INFO)
    local sUser = MONGO_USER
    local sPwd = MONGO_PWD
    local ret = {}
    for _,key in ipairs(serverkeys) do
        if GS_INFO[key] then
            local slave_ip = GS_INFO[key]["slave_db_ip"]
            local slave_db_port = GS_INFO[key]["slave_db_port"]
            local info = {
                game = {host=slave_ip, port=slave_db_port,username=sUser,password=sPwd},
                gamelog = {host=slave_ip, port=slave_db_port,username=sUser,password=sPwd},
                gameumlog = {host=slave_ip, port=slave_db_port,username=sUser,password=sPwd},
                chatlog = {host=slave_ip, port=slave_db_port,username=sUser,password=sPwd},
            }
            ret[key] = info
        end
    end
    return ret
end

function get_cs_slave_dbs()
    local sUser = MONGO_USER
    local sPwd = MONGO_PWD
    return {
        game = {host=CS_INFO["slave_db_ip"],port=CS_INFO["slave_db_port"],username=sUser,password=sPwd}
    }
end

function get_gs_info(serverkey)
    return GS_INFO[serverkey]
end

function get_gs_list()
    return table_key_list(GS_INFO)
end

function get_server_name(serverkey)
    serverkey = serverkey or get_server_key()
    local info = GS_INFO[serverkey]
    if not info then
        return
    end
    return info.name
end

function get_client_host(serverkey)
    serverkey = serverkey or get_server_key()
    local info = GS_INFO[serverkey]
    if not info then
        return
    end
    return info.client_host
end

function get_server_desc(serverkey)
    serverkey = serverkey or get_server_key()
    local info = GS_INFO[serverkey]
    if not info then
        return
    end
    return info.desc
end

function get_open_platforms(serverkey)
    local desc = get_server_desc(serverkey)
    if not desc then
        return
    end
    local mData = serverdesc.get_open_platforms(desc)
    return mData
end

function is_matched_platform(platform, serverkey)
    local platforms = get_open_platforms(serverkey)
    if not platforms then
        return false
    end
    return table_in_list(platforms, platform)
end

function get_open_channels(serverkey)
    local desc = get_server_desc(serverkey)
    if not desc then
        return
    end
    local mData = serverdesc.get_open_channels(desc)
    return mData
end

function is_opened_channel(channel, serverkey)
    local channels = get_open_channels(serverkey)
    if not channels then
        return false
    end
    return table_in_list(channels, channel)
end

function is_opened_cps(cps, serverkey)
    local desc = get_server_desc(serverkey)
    if not desc then
        return false
    end
    return serverdesc.is_opened_cps(desc, cps)
end

function is_matched_game(gametype,serverkey)
    local info = GS_INFO[serverkey]
    if not info then
        return false
    end
    if table_in_list({"shenhe","iosshenhe","outertest","dev","branchtest"}, get_server_cluster()) then
        return true
    end
    local lOpenGame = info.open_game or {}
    if not table_in_list(lOpenGame,gametype) then
        return false
    end
    return true
end

--能否进行角色互通
function is_role_interflow(publisher,serverkey)
    serverkey = serverkey or get_server_key()
    if not publisher or publisher ~= "sm" then
        return false
    end
    local desc = get_server_desc(serverkey)
    if desc == serverdesc.SERVER_DESC.sm_mix then
        return true
    end
    return false
end