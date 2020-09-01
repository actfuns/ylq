--import module

local baseshop = import(service_path("store.shop"))

CShop = {}
CShop.__index = CShop
CShop.m_ID=212
inherit(CShop, baseshop.CShop)


function NewShop()
    return CShop:New()
end


function CShop:BuyItem(oPlayer,mData)
    local bResult = super(CShop).BuyItem(self,oPlayer,mData)
    if bResult then
        oPlayer:AddSchedule("buy_giftbag")
    end
    return bResult
end


