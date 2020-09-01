
local skynet = require "skynet"
local cjson = require "cjson"
local interactive = require "base.interactive"
local record = require "public.record"

local M = {}

local function escape(s)
    return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function decode_func(c)
    return string.char(tonumber(c, 16))
end

local function decode(str)
    local str = str:gsub('+', ' ')
    return str:gsub("%%(..)", decode_func)
end

function M.request(method, host, url, content, func, header)
    interactive.Request(".webrouter", "common", "HttpRequest", {
            method = method,
            host = host,
            url = url,
            content = content,
            header = header,
        },
        function(mRecord, mData)
            if mData.errcode == 0 and mData.statuscode == 200 then
                if func then
                    func(mData.body, mData.header)
                end
            else
                record.warning("httpuse %s (host:%s url:%s content:%s header:%s) warning, errcode:%s statuscode:%s",
                    method, host, url, content, header, mData.errcode, mData.statuscode
                )
            end
        end
    )
end

function M.get(host, url, content, func, header)
    M.request("GET", host, url, content, func, header)
end

function M.post(host, url, content, func, header)
    M.request("POST", host, url, content, func, header)
end

function M.mkcontent_json(m)
    return cjson.encode(m)
end

function M.mkcontent_kv(m)
    local l = {}
    for k, v in pairs(m) do
        table.insert(l, string.format("%s=%s", escape(k), escape(v)))
    end
    return table.concat(l, "&")
end

function M.content_json(s)
    if s == "" then
        return {}
    end
    return cjson.decode(s)
end

function M.content_kv(s)
    local m = {}
    for k, v in s:gmatch "(.-)=([^&]*)&?" do
        m[decode(k)] = decode(v)
    end
    return m
end

function M.mkurl(url, param)
    return string.format("%s?%s", url, M.mkcontent_kv(param))
end

function M.urlencode(s)
    return escape(s)
end

function M.urldecode(s)
    return decode(s)
end

return M
