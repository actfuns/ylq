local global = require "global"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))
local gmcommon = import(service_path("gm/gm_common"))

Commands = {}

function Commands.SendPublicEmail(mRecord, mArgs)
    local oMailMgr = global.oMailMgr
    oMailMgr:SendReadySysMail(mArgs)
end

function Commands.SendPrivateEmail(mRecord, mArgs)
    local lPlayerId = mArgs["playerids"]
    if #lPlayerId <= 0 then return end
    local oMailMgr = global.oMailMgr
    oMailMgr:SendReadySysMail(mArgs)
end

function Commands.SendSysChat(mRecord, mArgs)
    local sMsg = mArgs["content"]
    local iHorse = mArgs["type"]
    local oChatMgr = global.oChatMgr
    oChatMgr:HandleSysChat(sMsg, 0, iHorse)
end

function Commands.BanPlayerChat(mRecord, mArgs)
    local iPid = mArgs["pid"]
    local iSecond = mArgs["seconds"]

    local oBackendMgr = global.oBackendMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iTime = get_time() + iSecond
    if oPlayer then
        oBackendMgr:BanPlayerChat(oPlayer, iTime)
    else
        oBackendMgr:OnlineExecute(iPid, "BanPlayerChat", {iTime})
    end
end

function Commands.BanPlayerLogin(mRecord, mArgs)
    local iPid = mArgs["pid"]
    local iSecond = mArgs["seconds"] or 0
    local oBackendMgr = global.oBackendMgr
    oBackendMgr:BanPlayerLogin(iPid, iSecond)
end

function Commands.FinePlayerMoney(mRecord, mArgs)
    local iPid = mArgs["pid"]
    local iMoneyType = mArgs["money_type"]
    local iValue = mArgs["value"]
    local sReason = mArgs["reason"]

    local oBackendMgr = global.oBackendMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oBackendMgr:FinePlayerMoney(oPlayer, iMoneyType, iValue)
    else
        oBackendMgr:OnlineExecute(iPid, "FinePlayerMoney", {iMoneyType, iValue})
    end
end

function Commands.RemovePlayerItem(mRecord, mArgs)
    local iPid = mArgs["pid"]
    local iItem = mArgs["item"]
    local iValue = mArgs["value"]
    local oBackendMgr = global.oBackendMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oBackendMgr:RemovePlayerItem(oPlayer, iItem, iValue)
    else
        oBackendMgr:OnlineExecute(iPid, "RemovePlayerItem", {iMoneyType, iValue})
    end
end

function Commands.KickPlayer(mRecord, mArgs)
    local iPid = mArgs["pid"]
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:Logout(iPid)
end

function Commands.ForceWarEnd(mRecord, mArgs)
    local iPid = mArgs["pid"]
    local oBackendMgr = global.oBackendMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        local oWar = oPlayer:GetNowWar()
        if oWar then
            oWar:TestCmd("warend",iPid,{war_result = 2})
        end
    end
end

function Commands.ForceLeaveTeam(mRecord, mArgs)
    local iPid = mArgs["pid"]
    local oBackendMgr = global.oBackendMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oBackendMgr:ForceLeaveTeam(oPlayer)
    else
        oBackendMgr:OnlineExecute(iPid, "ForceLeaveTeam", {})
    end
end

function Commands.ForceChangeScene(mRecord, mArgs)
    local iPid = mArgs["pid"]
    local oBackendMgr = global.oBackendMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oBackendMgr:ForceChangeScene(oPlayer)
    else
        oBackendMgr:OnlineExecute(iPid, "ForceChangeScene", {})
    end
end

function Commands.SearchPlayerInfo(mRecord, mArgs)
    local iPid = mArgs["pid"]
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local oBackendMgr = global.oBackendMgr

    local mRet = {online=false}
    if oPlayer then
        mRet = oBackendMgr:PackPlayer2Backend(oPlayer)
    end
    return mRet
end

function Commands.ReportWarning(mRecord,mArgs)
    local iPid = mArgs.pid
    if iPid then
        local oMailMgr = global.oMailMgr
        local mMail, sMail = oMailMgr:GetMailInfo(50)
        oMailMgr:SendMail(0, sMail, iPid, mMail)
    end
end

function Commands.ReportPunish(mRecord,mArgs)
    local iPid = mArgs.pid
    local iCoin = mArgs.coin
    if iPid and iCoin then
        local oBackendMgr = global.oBackendMgr
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oBackendMgr:ResumeCoin(oPlayer, iCoin,"恶意举报处罚")
        else
            oBackendMgr:OnlineExecute(iPid, "ResumeCoin", {iCoin,"恶意举报处罚"})
        end

        local oMailMgr = global.oMailMgr
        local mMail, sMail = oMailMgr:GetMailInfo(51)
        mMail.context = string.gsub(mMail.context,"$coin",tostring(iCoin))
        oMailMgr:SendMail(0, sMail, iPid, mMail)
    end
end

function Commands.BanReport(mRecord,mArgs)
    local iPid = mArgs.pid
    local iTime = mArgs.time
    iTime = iTime * 60
    if iTime < 0  or iTime > 7 * 24 * 3600 then
        record.warning("ban report too long "..iTime)
        return
    end
    if iPid then
        local oBackendMgr = global.oBackendMgr
        local oWorldMgr = global.oWorldMgr
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oBackendMgr:BanPlayerReport(oPlayer, iTime)
        else
            oBackendMgr:OnlineExecute(iPid, "BanPlayerReport", {iTime})
        end
        local oMailMgr = global.oMailMgr
        local mMail, sMail = oMailMgr:GetMailInfo(52)
        oMailMgr:SendMail(0, sMail, iPid, mMail)
    end
end

function Commands.ReportReward(mRecord,mArgs)
    local iPid = mArgs.pid
    local iCoin = mArgs.coin
    if iPid then
        local oMailMgr = global.oMailMgr
        local mMail, sMail = oMailMgr:GetMailInfo(53)
        oMailMgr:SendMail(0, sMail, iPid, mMail,{{sid = gamedefines.COIN_FLAG.COIN_COIN, value = iCoin}})
    end
end

function Commands.BanPlayerselfChat(mRecord,mArgs)
    local iPid = mArgs.pid
    local iTime = mArgs.seconds or 0
    if iTime <= 0 then return end
    local oBackendMgr = global.oBackendMgr
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oBackendMgr:BanPlayerChatSelf(oPlayer, iTime)
    else
        oBackendMgr:OnlineExecute(iPid, "BanPlayerChatSelf", {iTime})
    end
end