--import module
--与客户端回调管理
local global = require "global"
local extend = require "base.extend"
local interactive = require "base.interactive"
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

function CCBMgr:GetSendObj(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    return oPlayer
end

function CCBMgr:SendCallBack(oPlayer,iSessionIdx,mData)
    local iPid = oPlayer:GetPid()
    local iTrueSessionIdx = iSessionIdx // 1000
    local iAddress = iSessionIdx % 1000
    if iAddress == MY_ADDR then
        local mCallBack = self:GetCallBack(iTrueSessionIdx)
        if not mCallBack then
            return
        end
        local iOwner,fResCallBack,fCallback,iTime,iAddress = table.unpack(mCallBack)
        self:TrueCallback(oPlayer,iTrueSessionIdx,mData)
    else
        local oNowWar = oPlayer:GetNowWar()
        if  oNowWar then
            mData.war_id = oNowWar:GetWarId()
        end
        mData.pid = oPlayer:GetPid()
        interactive.Send(iAddress,"common","SendCallBack",mData)
    end
end


function CCBMgr:GS2CDialog(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CDialog",mNet)
    end
end

function CCBMgr:GS2CShowPlayBoyWnd(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CShowPlayBoyWnd",mNet)
    end
end

--[[
1.使用任务道具taskitem
]]
function CCBMgr:GS2CLoadUI(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CLoadUI",mNet)
    end
end

--[[
npc回调
]]
function CCBMgr:GS2CNpcSay(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CNpcSay",mNet)
    end
end

function CCBMgr:GS2CPopTaskItem(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CPopTaskItem",mNet)
    end
end

function CCBMgr:GS2CConfirmUI(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CConfirmUI",mNet)
    end
end

function CCBMgr:GS2CShowOpenBtn(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CShowOpenBtn",mNet)
    end
end

function CCBMgr:GS2CStartPick(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CStartPick",mNet)
    end
end

function CCBMgr:AutoFindTaskPath(iPid,mNet)
    local oSceneMgr = global.oSceneMgr
    oSceneMgr:SceneAutoFindPath(iPid,mNet["iMapId"],mNet["iPosx"],mNet["iPosy"],nil,mNet["iAutoType"],mNet["sessionidx"],mNet["system"])
end

function CCBMgr:GS2CShowNormalReward(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CShowNormalReward",mNet)
    end
end

function CCBMgr:PackConfirmData(iPid,mData)
    local mNet = {}
    mNet["sContent"] = mData["sContent"]
    mNet["uitype"] = mData["uitype"]
    mNet["simplerole"] = mData["simplerole"]
    mNet["sConfirm"] = mData["sConfirm"] or "确认"
    mNet["sCancle"] = mData["sCancle"] or "取消"
    mNet["time"] = mData["time"] or 0
    mNet["default"] = mData["default"] or 1
    mNet["forceconfirm"] = mData["forceconfirm"] or 0
    mNet["confirmtype"] = mData["confirmtype"] or 0
    mNet["relation"] = mData["relation"] or 0
    mNet["point"] = mData["point"]
    return mNet
end

function CCBMgr:SimpleConfirmUI(iPid,sContent,sConfirm,sCancel,iTime,fback)
    local mNet = {
            sContent = sContent,
            uitype = 0,
            sConfirm = sConfirm or "确定",
            sCancle = sCancel or "取消",
            default = 0,
            time = iTime or 0,
        }
    local m = self:PackConfirmData(nil, mNet)
    self:SetCallBack(iPid,"GS2CConfirmUI",m ,nil,fback)
end

function CCBMgr:GS2CTeamEnterGameUI(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CTeamEnterGameUI",mNet)
    end
end

function CCBMgr:GS2CShowCaiQuanWnd(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CShowCaiQuanWnd",mNet)
    end
end

function CCBMgr:GS2CShowCaiQuanResult(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CShowCaiQuanResult",mNet)
    end
end

function CCBMgr:GS2CHongBaoUI(iPid,mNet)
    local oPlayer = self:GetSendObj(iPid)
    if oPlayer then
        oPlayer:Send("GS2CHongBaoUI",mNet)
    end
end