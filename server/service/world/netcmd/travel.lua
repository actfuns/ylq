local global = require "global"

function C2GSSetPartnerTravelPos(oPlayer, mData)
    local oTravel = oPlayer:GetTravel()
    if oTravel:IsTravel() then
        oPlayer:NotifyMessage("正在游历，不可更换伙伴")
        return
    end
    oPlayer.m_oPartnerCtrl:Forward("C2GSSetPartnerTravelPos", oPlayer:GetPid(), mData)
end

function C2GSSetFrdPartnerTravel(oPlayer, mData)
    local iPid = oPlayer:GetPid()
    local iFrdPid = mData["frd_pid"]
    local iParId = mData["parid"]
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:SetMinePartner2Frd(oPlayer, iFrdPid, iParId)
    end
end

function C2GSAcceptTravelRwd(oPlayer, mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:AcceptTravelReward(oPlayer)
    end
end

function C2GSAcceptFrdTravelRwd(oPlayer, mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:AcceptMineTravelReward(oPlayer)
    end
end

function C2GSGetFrdTravelInfo(oPlayer, mData)
    local iFrdPid = mData["frd_pid"]
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:GetFrdTravelInfo(oPlayer, iFrdPid)
    end
end

function C2GSCancelSpeedTravel(oPlayer, mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:CancelSpeed(oPlayer)
    end
end

function C2GSStartTravel(oPlayer, mData)
    local iTravel = mData["travel_type"]
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        if oHuodong:ValidStartTravel(oPlayer) then
            oHuodong:TravelStart(oPlayer, iTravel)
        end
    end
end

function C2GSStopTravel(oPlayer, mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:TravelStop(oPlayer)
    end
end

function C2GSInviteTravel(oPlayer, mData)
    local lFrdPids = mData["frd_pids"]
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:InviteTravel(oPlayer, lFrdPids)
    end
end

function C2GSDelTravelInvite(oPlayer, mData)
    local iFrdPid = mData["frd_pid"]
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:DelTravelInvite(oPlayer, iFrdPid)
    end
end

function C2GSClearTravelInvite(oPlayer, mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:ClearTravelInvite(oPlayer)
    end
end

function C2GSQueryTravelInvite(oPlayer, mData)
    local oTravel = oPlayer:GetTravel()
    if oTravel then
        oTravel:QueryFrdInvite()
    end
end


----------------------------翻牌-------------------------------
function C2GSStartTravelCard(oPlayer, mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:StartTravelCardGame(oPlayer)
    end
end

function C2GSStopTravelCard(oPlayer, mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:StopTravelCardGame(oPlayer)
    end
end

function C2GSShowTravelCard(oPlayer, mData)
    local iPos = mData["pos"]
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:ShowTravelCard(oPlayer,iPos)
    end
end

function C2GSFirstOpenTraderUI(oPlayer, mData)
    local oHuodong = global.oHuodongMgr:GetHuodong("travel")
    if oHuodong then
        oHuodong:FirstOpenTravelUI(oPlayer)
    end
end