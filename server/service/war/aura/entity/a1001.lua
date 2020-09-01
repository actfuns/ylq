--import module

local global = require "global"
local skynet = require "skynet"

local aurabase = import(service_path("aura/aurabase"))

function NewCAura(...)
    local o = CAura:New(...)
    return o
end

CAura = {}
CAura.__index = CAura
inherit(CAura, aurabase.CAura)
