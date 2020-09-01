local global = require "global"

local partnerobj = import(service_path("partner.partnerobj"))

function GetPartnerData(iSid)
    local res = require "base.res"
    local mData = res["daobiao"]["partner"]["partner_info"][iSid]
    -- assert(mData, string.format("partner data :%s not exist!", iSid))
    return mData
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


function PartnerColorName(iParType)
    local mData = GetPartnerData(iParType)
    if mData then
        local res = require "base.res"
        local mColor = res["daobiao"]["partnercolor"][mData.rare]
        if mColor then
            return string.format(mColor.color, mData.name)
        end
    end
    return ""
end