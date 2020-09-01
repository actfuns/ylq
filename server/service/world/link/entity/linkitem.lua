--import module
local global = require "global"


local baselink = import(service_path("link.linkobj"))

CLink = {}
CLink.__index = CLink
inherit(CLink, baselink.CLink)

function NewCLink(...)
    return CLink:New(...)
end

function CLink:SetLink(oPlayer,mNetData,mArgs)
    local iItemid = mNetData.itemid
    local fCallback = function (mRecord,mData)
        self:OnSetLink(oPlayer,mNetData,mData)
    end
    oPlayer.m_oItemCtrl:GetItemLink(oPlayer,iItemid,fCallback)
end

function CLink:PackLink(oPlayer,mData,mArgs)
    return {
        item = mArgs.item
    }
end
