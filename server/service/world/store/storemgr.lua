--import module
local global = require "global"

local exchange = import(service_path("store.exchange"))
local defines = import(service_path("store.defines"))


function  NewStoreMgr()
    return CStoreMgr:New()
end


CStoreMgr = {}
CStoreMgr.__index = CStoreMgr
inherit(CStoreMgr, logic_base_cls())


function CStoreMgr:New()
    local o = super(CStoreMgr).New(self)
    o.m_mShop = {}
    o.m_Exchange = exchange.NewExchange()
    for k,v in pairs(defines.SHOP_REGISTER) do
        o:NewShop(k,v)
    end
    return o
end

function CStoreMgr:GetShop(iShop)
    return self.m_mShop[iShop]
end

function CStoreMgr:ExChange()
    return self.m_Exchange
end


function CStoreMgr:NewShop(sName,iID)
    local sPath = string.format("store/entity/sh%d",iID)
    local oModule = import(service_path(sPath))
    assert(oModule,string.format("NewShop err:%d",iID))
    local oShop = oModule.NewShop()
    oShop.m_Name = sName
    self.m_mShop[oShop.m_ID] = oShop
    return oShop
end

function CStoreMgr:GetItem(iItem)
    local res = require "base.res"
    local mStoreItem = res["daobiao"]["shopinfo"]["npcstore"]["data"][iItem]
    assert(mStoreItem,string.format("storeitem err : %d",iItem))
    return mStoreItem
end

function CStoreMgr:ShopGoods(iShop)
    local res = require "base.res"
    local mShopGoods = res["daobiao"]["shopinfo"]["npcstore"]["index"][iShop]
    assert(mShopGoods,string.format("shopgoods err : %d",iShop))
    return mShopGoods
end

function CStoreMgr:GlobalControlKey()
    return "shop"
end

function CStoreMgr:IsClose()
    local oWorldMgr = global.oWorldMgr
    local sKey = self:GlobalControlKey()
    if oWorldMgr:IsClose(sKey) then
        return true
    end
    return false
end

function CStoreMgr:GetRuleData(iRule)
    local res = require "base.res"
    local mRule = res["daobiao"]["shopinfo"]["rule"]
    return mRule[iRule]
end

function CStoreMgr:GetShopInfo(iShop)
    local res = require "base.res"
    local mShop = res["daobiao"]["shopinfo"]["shop"]
    return mShop[iShop]
end

function CStoreMgr:RMBPlay(oPlayer,iShop,sid,bNoRefresh)
    local oShop = self:GetShop(iShop)
    oShop:RMBPlay(oPlayer,sid,bNoRefresh)
end








