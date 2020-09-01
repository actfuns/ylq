
local global = require "global"
local defines = import(service_path("link.defines"))


CLink = {}
CLink.__index = CLink
inherit(CLink, logic_base_cls())


function CLink:New(iID,sNet,sName)
    local o = super(CLink).New(self)
    o.m_ID = iID
    o.m_Net =  sNet
    o.m_Name = sName
    return o
end

function CLink:SetLink(oPlayer,mData,mArgs)
    mArgs = mArgs or {}
    self:OnSetLink(oPlayer,mData,mArgs)
end

function CLink:OnSetLink(oPlayer,mData,mArgs)
    local mNet = self:PackLink(oPlayer,mData,mArgs)
    if  not  mNet then
        local oNotifyMgr = global.oNotifyMgr
        oPlayer:Send("GS2CreateCLink",{idx=0})
        oNotifyMgr:Notify(oPlayer:GetPid(),"无效链接")
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    local oLinkMgr  = global.oLinkMgr
    local idx = oLinkMgr:PushNewNet(self:Name(),mNet)
    oPlayer:Send("GS2CreateCLink",{idx=idx,rand=mData.rand or 0})
end



function CLink:PackLink(oPlayer,mData)
    return {}
end

function CLink:NetHead()
    return self.m_Net
end

function CLink:Name()
    return self.m_Name
end

