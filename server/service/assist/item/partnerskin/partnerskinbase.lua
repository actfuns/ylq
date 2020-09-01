local global = require "global"
local skynet = require "skynet"
local interactive =  require "base.interactive"

local itembase = import(service_path("item/itembase"))

CItem = {}
CItem.__index = CItem
inherit(CItem,itembase.CItem)
CItem.m_ItemType = "partnerskin"

function NewItem(sid)
    local o = CItem:New(sid)
    return o
end

function CItem:New(sid)
    local o = super(CItem).New(self, sid)
    return o
end

function CItem:PartnerType()
    local mData = self:GetItemData()
    return mData.partner_type
end

function CItem:PartnerShape()
    return self:GetItemData()["shape"]
end

function CItem:SkinType()
    return self:GetItemData()["skin_type"]
end

function CItem:PackModelInfo()
    local mData = self:GetItemData()
    return {
        shape = mData.shape,
        skin = self:SID(),
    }
end

function CItem:TrueUse(oPlayer, iParId, iAmount)
    local oAssistMgr = global.oAssistMgr
    local oPartner = oPlayer.m_oPartnerCtrl:GetPartner(iParId)
    if oPartner then
        if oPartner:PartnerType() == self:PartnerType() then
            oPartner:UseSkin(oPlayer, self)
        else
            oAssistMgr:Notify(oPlayer:GetPid(), "伙伴不可使用该皮肤")
        end
    else
        oAssistMgr:Notify(oPlayer:GetPid(), "伙伴不存在")
    end
end