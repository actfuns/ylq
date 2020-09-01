--import module
local global = require "global"

local uiobj = import(lualib_path("public.uiobj"))
local interactive = require "base.interactive"

function NewUIMgr()
    local o = CUIMgr:New()
    return o
end

CUIMgr = {}
CUIMgr.__index = CUIMgr
inherit(CUIMgr, uiobj.CUIMgr)

function CUIMgr:New()
    local o = super(CUIMgr).New(self)
    o.m_mKeep = {}
    return o
end

function CUIMgr:GetSendObj(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    return oPlayer
end

function CUIMgr:ShowKeepItem(iPid)
    local lNetItem = self:PackKeepItem(iPid)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local oAssistMgr = global.oAssistMgr
        local iPid = oPlayer:GetPid()
        local iRemoteAddr = oAssistMgr:SelectRemoteAssist(iPid)
        interactive.Send(iRemoteAddr, "common", "ShowKeepItem", {
            pid = iPid,
            data = lNetItem,
        })
    end
    self:ClearKeepItem(iPid)
end

function CUIMgr:ClearKeepItem(iPid)
    local sFlag = string.format("%s_keep_item", iPid)
    self:DelTimeCb(sFlag)
    self.m_mKeep[iPid] = nil
end

function CUIMgr:GS2COpenShop(oPlayer,iShop)
    local mNet = {}
    mNet["shop_id"] = iShop
    if oPlayer then
        oPlayer:Send("GS2COpenShop",mNet)
    end
end

function CUIMgr:GS2COpenCultivateUI(oPlayer)
    local mNet = {}
    if oPlayer then
        oPlayer:Send("GS2COpenCultivateUI", mNet)
    end
end

function CUIMgr:GS2CCloseConfirmUI(oPlayer,iSessionIdx)
    local mNet = {sessionidx = iSessionIdx}
    if oPlayer then
        oPlayer:Send("GS2CCloseConfirmUI", mNet)
    end
end

function CUIMgr:GS2COpenView(oPlayer, vid)
    if oPlayer then
        oPlayer:Send("GS2COpenView", {vid=vid})
    end
end
