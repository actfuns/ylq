--import module

local baseshop = import(service_path("store.shop"))

CShop = {}
CShop.__index = CShop
CShop.m_ID=204
CShop.m_SelectByWeight = 1
inherit(CShop, baseshop.CPlayerShop)


function NewShop()
    return CShop:New()
end



