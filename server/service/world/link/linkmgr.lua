local global = require "global"
local net = require "base.net"

local defines = import(service_path("link.defines"))

function NewLinkMgr(...)
    local o = CLinkMgr:New(...)
    return o
end

CLinkMgr = {}
CLinkMgr.__index = CLinkMgr
inherit(CLinkMgr, logic_base_cls())

function CLinkMgr:New()
    local o = super(CLinkMgr).New(self)
    o.m_mLink = {}
    o.m_NetPackList = {}
    o.m_NetLen = 0
    o.m_CacheLimit = 15000
    o.m_CacheTime = 20*60
    for sName,mInfo in pairs(defines.LINK_REGISTER) do
        local iId = mInfo[1]
        local sNet = mInfo[2]
        o:NewLink(sName,iId,sNet)
    end
    o:CheckTimeOut()
    return o
end



function CLinkMgr:NewLink(sName,iID,sNet)
    local sPath = string.format("link/entity/link%s",sName)
    local oModule = import(service_path(sPath))
    assert(oModule,string.format("NewLink err:%s",sName))
    local oLink = oModule.NewCLink(iID,sNet,sName)
    self.m_mLink[sName] = oLink
    return oLink
end

function CLinkMgr:GetLink(sName)
    return self.m_mLink[sName]
end

function CLinkMgr:NewLinkID()
    local oWorldMgr = global.oWorldMgr
    local idx,bReset = oWorldMgr:NewLinkID()
    if bReset then
        self.m_CleanIdex = nil
    end
    return idx
end



function CLinkMgr:PushNewNet(sName,mNet)
    local iLink  = self:NewLinkID()
    local mData = {idx=  iLink}
    mData[sName]  = mNet
    local mSendNet  =  net.Mask("GS2CLinkInfo", mData)
    self.m_NetPackList[iLink] = {net=mSendNet,time=get_time()}
    self.m_NetLen = self.m_NetLen + 1
    return iLink
end

function CLinkMgr:GetNet(idx)
    return self.m_NetPackList[idx]
end

function CLinkMgr:CheckTimeOut()
    self:DelTimeCb("check_timeout")
    local func = function()
        self:CheckTimeOut()
        self:CheckLinkTimeOut()
    end
    self:AddTimeCb("check_timeout",30*1000,func)
end


function CLinkMgr:CheckLinkTimeOut()
    if self.m_NetLen == 0 then
        return
    end
     if not self.m_CleanIdex  then
        local iMin = 2100000001
        for iLink,_ in pairs(self.m_NetPackList) do
            if iMin > iLink then
                iMin = iLink
            end
        end
        self.m_CleanIdex = iMin
    end
    local iTime =  self.m_CacheTime
    local iLink  = self.m_CleanIdex
    local iNow = get_time()
    while self.m_NetLen > 0 do
        local mData = self.m_NetPackList[iLink]
        if mData and iNow- mData["time"] <  iTime then
            break
        end
        self.m_NetPackList[iLink] = nil
        iLink = iLink + 1
        self.m_NetLen  = self.m_NetLen - 1
    end

    while self.m_CacheLimit < self.m_NetLen do
        self.m_NetPackList[iLink] = nil
        iLink = iLink + 1
        self.m_NetLen  = self.m_NetLen - 1
    end
    if self.m_NetLen == 0 then
        self.m_NetPackList = {}
        iLink = nil
    end
    self.m_CleanIdex = iLink
end


function  CLinkMgr:ClickLink(oPlayer,idx)
    local oNotifyMgr = global.oNotifyMgr
    local oNetObj  = self:GetNet(idx)
    if not oNetObj then
        oNotifyMgr:Notify(oPlayer:GetPid(),"链接已失效")
        return
    end
    oPlayer:Send("GS2CLinkInfo",oNetObj["net"])
end

