-- import file

local md5 = require "md5"
local httpuse = require "public.httpuse"
local cbc = require "base.crypt.pattern.cbc"
local des = require("base.crypt.algo.des-c")
local padding = require "base.crypt.padding.pkcs5"
local array = require("base.crypt.common.array")
local serverdefines = require "public.serverdefines"

local serverinfo = import(lualib_path("public.serverinfo"))

function NewYYBaoSdk(...)
    return CYYBaoSdk:New(...)
end

YYBAO_SIGN_KEY = "13CE0EEC7EA9241E793FEB8E19240E59"
YYBAO_DES_KEY = "!~btusd."

CYYBaoSdk = {}
CYYBaoSdk.__index = CYYBaoSdk

function CYYBaoSdk:New()
    local o = setmetatable({}, self)
    return o
end

function CYYBaoSdk:Init()
    self.m_DesObj = cbc.Create(des, padding, "!~btusd.")
end

function CYYBaoSdk:Encode(str)
    local sEncode = self.m_DesObj:Encode(string.lower(httpuse.urlencode(str)))
    return array.toHex(array.fromString(sEncode))
end

function CYYBaoSdk:EnterSign(mParam)
    local lKey = table_key_list(mParam)
    table.sort(lKey)
    local s = ""
    for _, sKey in ipairs(lKey) do
        if sKey ~= "device" then
            s = s .. mParam[sKey]
        end
    end
    s = s .. YYBAO_SIGN_KEY
    return md5.sumhexa(s)
end

function CYYBaoSdk:BackSign(code,timestamp)
    timestamp = timestamp or get_time()
    local s = ""
    s = s .. code .. timestamp
    s = s .. YYBAO_SIGN_KEY
    return md5.sumhexa(s)
end
