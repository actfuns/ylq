-- 端口配置
--公共
ROUTER_S_PORTS = "10010,10011,10012,10013"
--CS
CS_GM_CONSOLE_PORT = 10001
CS_DICTATOR_PORT = 10002
CS_WEB_PORT = 10003
CS_QRCODE_PORTS = "10004,10005,10006,10007,10008,10009"
--GS
GS_GM_CONSOLE_PORT = 7001
GS_DICTATOR_PORT = 7002
GS_WEB_PORT = 7003
GS_GATEWAY_PORTS = "7011,7012,27011,27012,27013"
--BS
BS_GM_CONSOLE_PORT = 20001
BS_DICTATOR_PORT = 20002
BS_WEB_PORT = 20003
--KS
KS_GM_CONSOLE_PORT = 20011
KS_DICTATOR_PORT = 20012
KS_WEB_PORT = 20013

-- service count
SCENE_SERVICE_COUNT = 15
WAR_SERVICE_COUNT = 15
WEB_SERVICE_COUNT = 5
PARTNER_SERVICE_COUNT = 5
VERIFY_SERVICE_COUNT = 4
PAY_SERVICE_COUNT = 4
ASSIST_SERVICE_COUNT = 10
PLAYER_SEND_COUNT = 10
KS_WORLD_SERVICE_COUNT = 2
ROUTERS_SERVICE_COUNT = 4
EXTERNAL_SERVICE_COUNT = 4
DATAREPORT_SERVICE_COUNT = 4
GAMEDB_SERVICE_COUNT = 4

-- queue
QUEUE_CNT = 15000
MAX_PLAYER_CNT = 15000

MONGO_USER = "root"
MONGO_PWD = "bCrfAptbKeW8YoZU"

-- router
ROUTER_CLIENT_COUNT = 10

local M = {}

function M.get_gm_console_port()
    if is_gs_server() then
        return GS_GM_CONSOLE_PORT
    elseif is_cs_server() then
        return CS_GM_CONSOLE_PORT
    elseif is_bs_server() then
        return BS_GM_CONSOLE_PORT
    elseif is_ks_server() then
        return KS_GM_CONSOLE_PORT
    end
end

function M.get_dictator_port()
    if is_gs_server() then
        return GS_DICTATOR_PORT
    elseif is_cs_server() then
        return CS_DICTATOR_PORT
    elseif is_bs_server() then
        return BS_DICTATOR_PORT
    elseif is_ks_server() then
        return KS_DICTATOR_PORT
    end
end

function M.get_web_port()
    if is_gs_server() then
        return GS_WEB_PORT
    elseif is_cs_server() then
        return CS_WEB_PORT
    elseif is_bs_server() then
        return BS_WEB_PORT
    elseif is_ks_server() then
        return KS_WEB_PORT
    end
end

function M.get_qrcode_ports()
    if is_cs_server() then
        return CS_QRCODE_PORTS
    end
end

function M.get_gateway_ports()
    if is_gs_server() then
        return GS_GATEWAY_PORTS
    end
end

return M