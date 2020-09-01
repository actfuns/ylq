
local skynet = require "skynet"

local floor = math.floor
local random = math.random

print = function ( ... )
    local lInfo = table.pack(...)
    local lResult = {}
    for i = 1, #lInfo do
        if type(lInfo[i]) == "table" then
            table.insert(lResult, require("base.extend").Table.serialize(lInfo[i]))
        elseif lInfo[i] == nil then
            table.insert(lResult, "nil")
        else
            table.insert(lResult, lInfo[i])
        end
    end
    skynet.error(table.unpack(lResult))
end

is_production_env = function ()
    return table_in_list({"pro","shenhe"}, get_server_cluster())
end

is_auto_open_measure = function ()
    return IS_AUTO_OPEN_MEASURE ~= 0
end

is_auto_track_baseobject = function ()
    return IS_AUTO_TRACK_BASEOBJECT ~= 0
end

is_auto_monitor = function ()
    return IS_AUTO_MONITOR ~= 0
end

loadfile_ex = function (sFileName, sMode, mEnv)
    sMode = sMode or "bt"
    mEnv = mEnv or _ENV
    local h = io.open(sFileName, "rb")
    assert(h, string.format("loadfile_ex fail %s", sFileName))
    local sData = h:read("*a")
    h:close()
    local f, s = load(sData, sFileName, sMode, mEnv)
    assert(f, string.format("loadfile_ex fail %s", s))
    return f
end

service_path = function (sPath)
    return string.format("service.%s.%s", MY_SERVICE_NAME, sPath)
end

service_file_path = function (sPath)
    return string.format("service/%s/%s", MY_SERVICE_NAME, sPath)
end

lualib_path = function (sPath)
    return string.format("lualib.%s", sPath)
end

serialize_table = function (t)
    return require("base.extend").Table.serialize(t)
end

table_print = function (t)
    print(require("base.extend").Table.serialize(t))
end

table_print_pretty = function (t)
    print(require("base.extend").Table.pretty_serialize(t))
end

baseobj_safe_release = function (o)
    local baserecycle = require "base.baserecycle"
    baserecycle.now_release(o)
end

baseobj_delay_release = function (o)
    local baserecycle = require "base.baserecycle"
    baserecycle.wait_release(o)
end

release = function (o)
    for _, v in ipairs(table_key_list(o)) do
        o[v] = nil
    end
    o._release = true
    setmetatable(o, {__newindex = function (t, k, v)
        error(string.format("attempt to operate a release obj %s %s", k, v))
    end})
end

is_release = function (o)
    return o._release == true
end

inherit = function (child, parent)
    setmetatable(child, parent)
end

super = function (child)
    return getmetatable(child)
end

logic_base_cls = function ()
    local baseobj = import(lualib_path("base.baseobj"))
    return baseobj.CBaseObject
end

local function Trace(sMsg)
    print(debug.traceback(sMsg))
end

safe_call = function (func, ...)
    return xpcall(func, Trace, ...)
end

db_key = function (k)
    return tostring(k)
end

--只取3位小数,不提供其他可能性
decimal = function (val)
    return floor(val*1000)*0.001
end

in_random = function (i, j)
    j = j or 100
    return random(j) <= i
end

save_all = function ()
    local servicesave = require "base.servicesave"
    servicesave.SaveAll()
end

is_cs_server = function()
    return get_server_type() == "cs"
end

is_gs_server = function()
    return get_server_type() == "gs"
end

is_bs_server = function()
    return get_server_type() == "bs"
end

is_ks_server = function()
    return get_server_type() == "ks"
end

get_server_key = function ()
    return MY_SERVER_KEY
end

get_server_cluster = function (server_key)
    server_key = server_key or MY_SERVER_KEY
    return string.match(server_key, "(%w+)_%w+")
end

get_server_tag = function (server_key)
    server_key = server_key or MY_SERVER_KEY
    return string.match(server_key, "%w+_(%w+)")
end

get_server_type = function (server_key)
    server_key = server_key or MY_SERVER_KEY
    return string.match(server_key, "%w+_(%a+)%d*")
end

get_server_id = function (server_key)
    server_key = server_key or MY_SERVER_KEY
    return tonumber(string.match(server_key, "%w+_%a+(%d*)"))
end

make_server_key = function (server_tag)
    assert(server_tag, "make server key error: no server tag")
    return get_server_cluster().."_"..server_tag
end
