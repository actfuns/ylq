--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))

local function ExecuteWarForward(oPlayer,sCmd, iPid, mData)
    local oNowWar = oPlayer:GetNowWar()
    if not oNowWar then
        return
    end
    local iWarId = oNowWar:GetWarId()
    if oNowWar.m_KFProxy then
        iWarId = oNowWar:GetRemoteWarId()
    end
    if oNowWar and iWarId == mData.war_id then
        oNowWar:Forward(sCmd, iPid, mData)
    end
end

function C2GSWarSkill(oPlayer, mData)
    ExecuteWarForward(oPlayer,"C2GSWarSkill", oPlayer:GetPid(), mData)
end

function C2GSWarNormalAttack(oPlayer, mData)
    ExecuteWarForward(oPlayer,"C2GSWarNormalAttack", oPlayer:GetPid(), mData)
end

function C2GSWarProtect(oPlayer, mData)
    ExecuteWarForward(oPlayer,"C2GSWarProtect", oPlayer:GetPid(), mData)
end

function C2GSWarEscape(oPlayer, mData)
    ExecuteWarForward(oPlayer,"C2GSWarEscape", oPlayer:GetPid(), mData)
end

function C2GSWarDefense(oPlayer, mData)
    ExecuteWarForward(oPlayer,"C2GSWarDefense", oPlayer:GetPid(), mData)
end

function C2GSWarStop(oPlayer,mData)
    ExecuteWarForward(oPlayer,"C2GSWarStop", oPlayer:GetPid(), mData)
end

function C2GSWarStart(oPlayer,mData)
    ExecuteWarForward(oPlayer,"C2GSWarStart", oPlayer:GetPid(), mData)
end

function C2GSWarPartner(oPlayer,mData)
    local oNotifyMgr = global.oNotifyMgr
    local iPid = oPlayer.m_iPid
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oNowWar and (oNowWar:GetWarId() == mData.war_id or oNowWar:GetRemoteWarId() ==  mData.war_id) then
        if oPlayer.m_oPartnerCtrl:ValidWarFightPos(mData["partner_list"]) then
            oPlayer.m_oPartnerCtrl:SetWarPartner(oNowWar, mData["partner_list"])
        end
    end
end

function C2GSWarPrepareCommand(oPlayer,mData)
    if oPlayer.m_oPartnerCtrl:ValidWarFightPos(mData["partner_list"]) then
        ExecuteWarForward(oPlayer,"C2GSWarPrepareCommand", oPlayer:GetPid(), mData)
    end
end

function C2GSWarAutoFight(oPlayer,mData)
    ExecuteWarForward(oPlayer,"C2GSWarAutoFight", oPlayer:GetPid(), mData)
end

function C2GSChangeAutoSkill(oPlayer,mData)
    ExecuteWarForward(oPlayer,"C2GSChangeAutoSkill", oPlayer:GetPid(), mData)
end

function C2GSWarTarget(oPlayer,mData)
    ExecuteWarForward(oPlayer,"C2GSWarTarget", oPlayer:GetPid(), mData)
end

function C2GSSelectCmd(oPlayer,mData)
    ExecuteWarForward(oPlayer,"C2GSSelectCmd", oPlayer:GetPid(), mData)
end

function C2GSSolveKaji(oPlayer,mData)
    local oWarMgr = global.oWarMgr
    oWarMgr:SolveKaji(oPlayer)
end

function C2GSEndFilmBout(oPlayer,mData)
    local oNowWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if not oNowWar or not oNowWar.m_IsWarFilm then
        return
    end
    if oNowWar:GetData("war_film_id") == mData.war_id then
        interactive.Send(oNowWar.m_iRemoteAddr, "war", "C2GSEndFilmBout", {war_id = oNowWar.m_iWarId, data = mData})
    end
end

function C2GSNextBoutStart(oPlayer,mData)
    ExecuteWarForward(oPlayer,"C2GSNextBoutStart", oPlayer:GetPid(), mData)
end

function C2GSWarSetPlaySpeed(oPlayer,mData)
    ExecuteWarForward(oPlayer,"C2GSWarSetPlaySpeed", oPlayer:GetPid(), mData)
end

function C2GSDebugPerform(oPlayer,mData)
    ExecuteWarForward(oPlayer,"C2GSDebugPerform", oPlayer:GetPid(), mData)
end

function C2GSWarBattleCommand(oPlayer,mData)
    ExecuteWarForward(oPlayer,"C2GSWarBattleCommand", oPlayer:GetPid(), mData)
end

function C2GSCleanWarBattleCommand(oPlayer,mData)
    ExecuteWarForward(oPlayer,"C2GSCleanWarBattleCommand", oPlayer:GetPid(), mData)
end

function C2GSNextActionEnd(oPlayer,mData)
   ExecuteWarForward(oPlayer,"C2GSNextActionEnd", oPlayer:GetPid(), mData)
end



