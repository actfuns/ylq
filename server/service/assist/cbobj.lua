--import module
--与客户端回调管理
local global = require "global"
local extend = require "base.extend"
local cbobj = import(lualib_path("public.cbobj"))

function NewCBMgr()
    local oMgr = CCBMgr:New()
    return oMgr
end

CCBMgr = {}
CCBMgr.__index = CCBMgr
inherit(CCBMgr,cbobj.CCBMgr)

function CCBMgr:New()
    local o = super(CCBMgr).New(self)
    return o
end

function CCBMgr:PackConfirmData(iPid,mData)
    local mNet = {}
    mNet["sContent"] = mData["sContent"]
    mNet["uitype"] = mData["uitype"] or 0
    mNet["simplerole"] = mData["simplerole"]
    mNet["sConfirm"] = mData["sConfirm"] or "确认"
    mNet["sCancle"] = mData["sCancle"] or "取消"
    mNet["time"] = mData["time"] or 0
    mNet["default"] = mData["default"] or 1
    mNet["forceconfirm"] = mData["forceconfirm"] or 0
    mNet["confirmtype"] = mData["confirmtype"] or 0
    mNet["relation"] = mData["relation"] or 0
    return mNet
end

function CCBMgr:GS2CShowNormalReward(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CShowNormalReward",mNet)
    end
end

function CCBMgr:GetSendObj(iPid)
    local oAssistMgr = global.oAssistMgr
    local oPlayer = oAssistMgr:GetPlayer(iPid)
    return oPlayer
end

function CCBMgr:GS2CConfirmUI(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CConfirmUI",mNet)
    end
end