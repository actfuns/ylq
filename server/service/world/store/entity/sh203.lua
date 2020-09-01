--import module
local global = require "global"
local skynet = require "skynet"
local extend = require "base.extend"

local baseshop = import(service_path("store.shop"))

CShop = {}
CShop.__index = CShop
CShop.m_ID=203
inherit(CShop,  baseshop.CShop)


function NewShop()
    return CShop:New()
end
