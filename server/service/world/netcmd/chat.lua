--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))
local CHANNEL_TYPE = gamedefines.CHANNEL_TYPE

function C2GSChat(oPlayer, mData)
    local sMsg = mData.cmd
    local iType = mData.type
    local iExtraArgs = mData.extraargs
    local oChatMgr = global.oChatMgr
    if oChatMgr:IsBanChat(oPlayer) then
        oPlayer:NotifyMessage("您已被禁言")
        return
    end
    if not oChatMgr:ValidChat(oPlayer) then
        return
    end
    if iType == CHANNEL_TYPE.WORLD_TYPE then
        oChatMgr:HandleWorldChat(oPlayer, sMsg)
    elseif iType == CHANNEL_TYPE.TEAM_TYPE then
        oChatMgr:HandleTeamChat(oPlayer, sMsg,false,iExtraArgs)
    elseif iType == CHANNEL_TYPE.CURRENT_TYPE then
        oChatMgr:HandleCurrentChat(oPlayer, sMsg)
    elseif iType == CHANNEL_TYPE.ORG_TYPE then
        oChatMgr:HandleOrgChat(oPlayer, sMsg)
    elseif iType == CHANNEL_TYPE.TEAMPVP_TYPE then
        oChatMgr:HandleTeamPVPChat(oPlayer,sMsg)
    end
end

function C2GSSendHongBao(oPlayer,mData)
    -- local iGold = mData.gold
    -- local iAmount = mData.amount
    -- local sType = mData.type
    -- local oHbMgr = global.oHbMgr
    -- oHbMgr:SendHongBao(oPlayer,sType,iGold,iAmount)
end

function C2GSHongBaoOption(oPlayer,mData)
    local action = mData.action
    local id = mData.id
    local oHbMgr = global.oHbMgr
    oHbMgr:HongBaoOption(oPlayer,action,id)
end

local function ReportPlayer(oPlayer,target,mArgs)
    local oWorldMgr = global.oWorldMgr
    local oTarget = oWorldMgr:GetOnlinePlayerByPid(target)
    if not oTarget then
        return false
    end
    local iLeftTime = oPlayer.m_oThisTemp:QueryLeftTime("banreport")
    if iLeftTime > 0 then
        oPlayer:NotifyMessage("您的账号被屏蔽举报功能，将于"..get_second2string(iLeftTime).."后解除")
        return false
    end
    if oPlayer.m_oToday:Query("reportcnt",0) > 10 then
        oPlayer:NotifyMessage("每天能对10名玩家进行举报")
        return false
    end
    local mList = oPlayer.m_oToday:Query("report_player",{})
    if table_in_list(mList,target) then
        oPlayer:NotifyMessage("今天已经举报过该玩家，请耐心等待审核结果")
        return
    end
    table.insert(mList,target)
    oPlayer.m_oToday:Set("report_player",mList)
    oPlayer.m_oToday:Add("reportcnt",1)
    local iCharge = 0
    if oTarget:HistoryCharge() > 0 then
        iCharge = 1
    end
    interactive.Send(".report", "common", "DoAddNew", {data = {
            account = oPlayer:GetAccount(),
            pid = oPlayer:GetPid(),
            name = oPlayer:GetName(),
            target = oTarget:GetPid(),
            t_account = oTarget:GetAccount(),
            reason = mArgs.reason,
            other = mArgs.other,
            ptime = get_time(),
            tname = oTarget:GetName(),
            charge = iCharge,
        }})
    oPlayer:NotifyMessage("系统已收到您的举报，24小时内予以审核")
    return true
end

function C2GSReportPlayer(oPlayer,mData)
    oPlayer:Send("GS2CReportResult",{bsuc=ReportPlayer(oPlayer,mData.target,mData)})
end