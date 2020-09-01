local global = require "global"

local partnerobj = import(service_path("partner/partnerobj"))
local partnerctrl = import(service_path("playerctrl/partnerctrl"))

function GetPartnerData(iSid)
    local res = require "base.res"
    return res["daobiao"]["partner"]["partner_info"][iSid]
end

function CreatePartner(iSid, mArgs)
    mArgs = mArgs or {}
    local mPartnerData = GetPartnerData(iSid)
    if not mArgs.star then
        mArgs.star = mPartnerData["star"]
    end
    local oPartner = partnerobj.NewPartner(iSid,mArgs)
    oPartner:Setup()
    return oPartner
end

function LoadPartner(iSid,mData)
    local mArgs = {}
    local oPartner = partnerobj.NewPartner(iSid,mArgs)
    oPartner:Load(mData)
    oPartner:Setup()
    return oPartner
end

function NewPartner(iPid, mData)
    return partnerctrl.NewPartner(iPid, mData)
end