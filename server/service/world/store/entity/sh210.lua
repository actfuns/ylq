--import module

local baseshop = import(service_path("store.shop"))

CShop = {}
CShop.__index = CShop
CShop.m_ID=210
inherit(CShop, baseshop.CShop)


function NewShop()
    return CShop:New()
end

function CShop:Amount(oPlayer,mItem,iPos)
    local iItem = mItem.item_id
    if oPlayer:GetItemAmount(iItem) > 0 then
        return 0
    end
    return 1
end



function CShop:PackItem(oPlayer,iItem,iPos)
    local mPack = super(CShop).PackItem(self,oPlayer,iItem,iPos)
    mPack["limit"] = 1
    return mPack
end

function CShop:BuyItem(oPlayer,mData)
    local b = super(CShop).BuyItem(self,oPlayer,mData)
    if b then
        local iPos = mData.pos
        local mNet = self:PackItem(oPlayer,mData.buy_id,iPos)
        if mNet then
            mNet["amount"] = 0
            oPlayer:Send("GS2CStoreRefresh",{shop_id= self.m_ID,goodsInfo=mNet})
        end
    end
    return b
end








