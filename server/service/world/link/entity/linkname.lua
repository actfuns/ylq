--import module
local global = require "global"


local baselink = import(service_path("link.linkobj"))

CLink = {}
CLink.__index = CLink
inherit(CLink, baselink.CLink)

function NewCLink(...)
    return CLink:New(...)
end

function CLink:SetLink(oPlayer,mData)
    local oWorldMgr = global.oWorldMgr
    local iPid = oPlayer:GetPid()
    oWorldMgr:LoadProfile(mData.pid,function (oProfile)
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer and oProfile then
            self:_SendLink(oPlayer,oProfile,mData)
        end
        end)
end




function CLink:_SendLink(oPlayer,oProfile,mData)
    if oProfile then
        mData["pid"] = oProfile:GetPid()
        mData["name"] = oProfile:GetName()
        self:OnSetLink(oPlayer,mData)
    else
        self:OnSetLink(oPlayer,nil)
    end
end

function CLink:PackLink(oPlayer,mData)
    if not mData then
        return
    end
    return {
        pid = mData["pid"],
        name = mData["name"],
        }
end
