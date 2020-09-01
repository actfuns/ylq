--import module

local global = require "global"
local skynet = require "skynet"


function C2GSUseTitle(oPlayer, mData)
    local iTid = mData.tid
    local iFlag = mData.flag
    local oTitleMgr = global.oTitleMgr
    local oNotifyMgr = global.oNotifyMgr
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oScene:QueryLimitRule("bantitle") then
        oNotifyMgr:Notify(oPlayer:GetPid(),"该场景无法操作称谓")
        return
    end
    if iFlag == 1 then
        oTitleMgr:UseTitle(oPlayer, iTid)
    else
        oTitleMgr:UnUseTitle(oPlayer,iTid)
    end
end

function C2GSTitleInfoList(oPlayer, mData)
    local oTitleMgr = global.oTitleMgr
    oTitleMgr:OpenTitleListUI(oPlayer)
end