local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
local record = require "public.record"
local playersend = require "base.playersend"

function NewMailAddrMgr(...)
    return CMailAddrMgr:New(...)
end

CMailAddrMgr = {}
CMailAddrMgr.__index = CMailAddrMgr
inherit(CMailAddrMgr, logic_base_cls())

function CMailAddrMgr:New(lAddrRemote)
    local o = super(CMailAddrMgr).New(self)
    o.m_lAddrRemote = lAddrRemote
    return o
end

function CMailAddrMgr:GetRemoteAddr()
    return self.m_lAddrRemote
end

function CMailAddrMgr:GetUpdateService(oPlayer)
    return {
        self:GetRemoteAddr(),
        {global.oAchieveMgr:GetRemoteAddr(),},
        {".broadcast",".clientupdate",".image",".rank",".org",".autoteam"},
        global.oAssistMgr:GetRemoteAddr(),
        global.oSceneMgr:GetRemoteAddr(),
        global.oWarMgr:GetRemoteAddr(),
    }
end

function CMailAddrMgr:OnConnectionChange(oPlayer)
    local mService = self:GetUpdateService()
    local sCmd = [[
        local playersend = require "base.playersend"
    ]]
    local iPid = oPlayer:GetPid()
    local mMailAddr = oPlayer:MailAddr()
    playersend.UpdatePlayerMail(iPid,mMailAddr)
    if not mMailAddr then
        mMailAddr = "nil"
    else
        mMailAddr = ConvertTblToStr(mMailAddr)
    end
    sCmd =sCmd.."playersend.UpdatePlayerMail("..iPid..",".. mMailAddr .. ")"
    for _,mRemoteAddr in pairs(mService) do
        for _,iRemoteAddr in ipairs(mRemoteAddr) do
            interactive.Send(iRemoteAddr, "default", "ExecuteString", {cmd = sCmd})
        end
    end
end