local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))

function NewImageMgr()
    return CImageMgr:New()
end

CImageMgr = {}
CImageMgr.__index = CImageMgr
inherit(CImageMgr, logic_base_cls())

function CImageMgr:New()
    local o = super(CImageMgr).New(self)
    o.m_iRemoteAddr = ".image"
    return o
end

function CImageMgr:OnLogin(oPlayer, bReEnter)
    interactive.Send(self.m_iRemoteAddr, "common", "OnLogin", {
        pid = oPlayer:GetPid(),
    })
end

function CImageMgr:OnLogout(oPlayer)
    interactive.Send(self.m_iRemoteAddr, "common", "OnLogout", {
        pid = oPlayer:GetPid(),
        })
end

function CImageMgr:OnDisconnected(oPlayer)
    interactive.Send(self.m_iRemoteAddr,"common", "Disconnected", {
        pid = oPlayer:GetPid(),
        })
end

function CImageMgr:Forward(sCmd, iPid, mData)
    interactive.Send(self.m_iRemoteAddr, "common", "Forward", {
        pid = iPid, cmd = sCmd, data = mData,
    })
end

function CImageMgr:TestCmd(sCmd, iPid, mData)
    interactive.Send(self.m_iRemoteAddr, "common", "TestCmd", {
        pid = iPid, cmd = sCmd, data = mData,
    })
end

function CImageMgr:CloseGS()
    interactive.Send(self.m_iRemoteAddr, "common", "CloseGS", {})
end