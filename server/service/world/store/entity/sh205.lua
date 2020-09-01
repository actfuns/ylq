--import module
local global  = require "global"

local baseshop = import(service_path("store.shop"))
local loaditem = import(service_path("item/loaditem"))

CShop = {}
CShop.__index = CShop
CShop.m_ID=205
inherit(CShop, baseshop.CShop)


function NewShop()
    return CShop:New()
end

