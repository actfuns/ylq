local skynet = require "skynet"

local M = {}

local pm
local nm

function M.Init()
    pm = require "base.protobuf"
    nm = require "base.netfind"
    pm.register_file(skynet.getenv("proto_file"))
    nm.Init(skynet.getenv("proto_define"))
end

function M.Update()
    package.loaded["base.protobuf"] = nil
    package.loaded["base.netfind"] = nil
    M.Init()
end

function M.ProtobufFunc(sFunc, ...)
    return pm[sFunc](...)
end

function M.NetfindFunc(sFunc, ...)
    return nm[sFunc](...)
end

return M
