--import module
local global = require "global"
local interactive = require "base.interactive"

local baselink = import(service_path("link.linkobj"))


CLink = {}
CLink.__index = CLink
inherit(CLink, baselink.CLink)

function NewCLink(...)
    return CLink:New(...)
end

function CLink:SetLink(oPlayer,mData)
    local iPartner = mData.parid
    local iPid =  oPlayer:GetPid()
    local oWorldMgr = global.oWorldMgr
    local iAddr = oPlayer.m_oPartnerCtrl:GetRemoteAddr()
    interactive.Request(iAddr,"partner","GetLinkPartnerInfo",{pid=iPid,partner=iPartner,},function(mRecord,mResult)
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
            if oPlayer then
                mData.result = mResult
                self:OnSetLink(oPlayer,mData)
            end
    end)
end

function CLink:PackLink(oPlayer,mData)
    mData = mData.result.data
    if not mData.partner then
        return
    end
    local mNet = {
    parinfo = mData.partner,
    equip = mData.equip,
    soul = mData.soul,
    pid = oPlayer:GetPid(),
    name = oPlayer:GetName(),
    }
    return {par = mNet}
end


