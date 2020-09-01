--import module

local global = require "global"
local skynet = require "skynet"

function C2GSOpenArena(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("arenagame")
    oHuoDong:OpenArenaUI(oPlayer)
end

function C2GSArenaMatch(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("arenagame")
    oHuoDong:EnterMatch(oPlayer)
end

function C2GSArenaCancelMatch(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("arenagame")
    oHuoDong:LeaveMatch(oPlayer)
end


function C2GSArenaHistory(oPlayer,mData)
    global.oNotifyMgr:Notify(oPlayer:GetPid(),"功能暂未开放，敬请期待！")
    -- local oHDMgr = global.oHuodongMgr
    -- local oHuoDong = oHDMgr:GetHuodong("arenagame")
    -- oHuoDong:OpenArenaHistory(oPlayer)
end

function C2GSArenaSetShowing(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("arenagame")
    oHuoDong:SetShowRecord(oPlayer,mData.fid)
end

function C2GSArenaReplayByRecordId(oPlayer,mData)
    global.oNotifyMgr:Notify(oPlayer:GetPid(),"功能暂未开放，敬请期待！")
    -- local iFilm = mData.fid
    -- local iView = mData.view or 1
    -- if not iFilm then
    --     return
    -- end
    -- local oWarFilmMgr = global.oWarFilmMgr
    -- local mArgs = {}
    -- local iPid = oPlayer:GetPid()
    -- mArgs["observer_view"] = iView
    -- oWarFilmMgr:StartFilm(oPlayer,iFilm,mArgs)
end

function C2GSArenaOpenWatch(oPlayer,mData)
    global.oNotifyMgr:Notify(oPlayer:GetPid(),"功能暂未开放，敬请期待！")
    -- local oHDMgr = global.oHuodongMgr
    -- local oHuoDong = oHDMgr:GetHuodong("arenagame")
    -- oHuoDong:ShowTopRecord(oPlayer)
end

function C2GSArenaReplayByPlayerId(oPlayer,mData)
    global.oNotifyMgr:Notify(oPlayer:GetPid(),"功能暂未开放，敬请期待！")
    -- local iPid = oPlayer:GetPid()
    -- local iTarget = mData["id"]
    -- local oWorldMgr = global.oWorldMgr
    -- local oNotifyMgr = global.oNotifyMgr
    -- local oWarFilmMgr = global.oWarFilmMgr

    -- oWorldMgr:LoadProfile(iTarget,function (oProfile)
    --     if not oProfile then
    --         return
    --     end
    --     local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    --     local mShow = oProfile:GetData("war_record")
    --     if not oPlayer then
    --         return
    --     end
    --     if not mShow or not mShow.fid then
    --         oNotifyMgr:Notify(oPlayer:GetPid(),"对方没有设置展示录像")
    --         return
    --     end
    --     local mFight = mShow["fight"]
    --     local mArgs = {observer_view=1,}
    --     if mShow["camp"] and mShow["camp"][iTarget] then
    --         mArgs["observer_view"] = mShow["camp"][iTarget]
    --     end
    --     local iFilm = mShow.fid
    --     oWarFilmMgr:StartFilm(oPlayer,iFilm,mArgs)
    -- end)
end

function C2GSGuaidArenaWar(oPlayer,mData)
    local oModule = import(service_path("templ"))
    local oTempl = oModule.CTempl:New()
    local oWar = oPlayer.m_oActiveCtrl:GetNowWar()
    if oWar then
        return
    end
    oTempl:CreateWar(oPlayer.m_iPid,nil,14008,{war_type = 14008,remote_war_type = guidance})
end

--====公平竞技====

function C2GSOpenEqualArena(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("equalarena")
    oHuoDong:OpenArenaUI(oPlayer)
end

function C2GSSetEqualArenaPartner(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("equalarena")
    oHuoDong:SetEqualArenaPartner(oPlayer,mData.partner)
end


function C2GSEqualArenaMatch(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("equalarena")
    oHuoDong:EnterMatch(oPlayer)
end

function C2GSEqualArenaCancelMatch(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("equalarena")
    oHuoDong:LeaveMatch(oPlayer)
end

function C2GSSelectEqualArena(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("equalarena")
    oHuoDong:SelectOperate(oPlayer,mData.select_par,mData.select_item)
end

function C2GSConfigEqualArena(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("equalarena")
    oHuoDong:ConfigArena(oPlayer,mData.select_par,mData.select_item,mData.handle_type)
end

function C2GSSyncSelectInfo(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("equalarena")
    oHuoDong:SyncSelectInfo(oPlayer,mData)
end

function C2GSEqualArenaHistory(oPlayer,mData)
    global.oNotifyMgr:Notify(oPlayer:GetPid(),"功能暂未开放，敬请期待！")
    -- local oHDMgr = global.oHuodongMgr
    -- local oHuoDong = oHDMgr:GetHuodong("equalarena")
    -- oHuoDong:OpenArenaHistory(oPlayer)
end

function C2GSEqualArenaSetShowing(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("equalarena")
    oHuoDong:SetShowRecord(oPlayer,mData.fid)
end

function C2GSEqualArenaOpenWatch(oPlayer,mData)
    global.oNotifyMgr:Notify(oPlayer:GetPid(),"功能暂未开放，敬请期待！")
    -- local oHDMgr = global.oHuodongMgr
    -- local oHuoDong = oHDMgr:GetHuodong("equalarena")
    -- oHuoDong:ShowTopRecord(oPlayer)
end



--===========协同比武===========

function C2GSTeamPVPMatch(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("teampvp")
    oHuoDong:EnterMatch(oPlayer)
end

function C2GSTeamPVPCancelMatch(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("teampvp")
    oHuoDong:LeaveMatch(oPlayer)
end

function C2GSOpenTeamPVPRank(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("teampvp")
    oHuoDong:OpenMainRank(oPlayer)
end

function C2GSGetTeamPVPInviteList(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("teampvp")
    oHuoDong:GetInviteList(oPlayer)
end

function C2GSTeamPVPToInviteList(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("teampvp")
    oHuoDong:InvitePlayer(oPlayer,mData.plist)
end

function C2GSTeamPVPLeaveScene(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("teampvp")
    oHuoDong:FindLeavePath(oPlayer)
end

function C2GSTeamPVPLeader(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("teampvp")
    oHuoDong:SetLeader(oPlayer,mData.target)
end

function C2GSTeamPVPLeave(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("teampvp")
    oHuoDong:LeaveTeam(oPlayer)
end

function C2GSTeamPVPKickout(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("teampvp")
    oHuoDong:KickoutTeam(oPlayer,mData.target)
end


--==============clubarena============

function C2GSOpenClubArenaMain(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("clubarena")
    oHuoDong:OpenMainUI(oPlayer)
end

function C2GSOpenClubArenaInfo(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("clubarena")
    oHuoDong:OpenClubUI(oPlayer,mData.club)
end

function C2GSClubArenaFight(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("clubarena")
    oHuoDong:ClubArenaFight(oPlayer,mData)
end

function C2GSResetClubArena(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("clubarena")
    oHuoDong:ResetEnemy(oPlayer,mData["club"])
end

function C2GSClubArenaAddFightCnt(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("clubarena")
    oHuoDong:AddClubArenaFightCnt(oPlayer)
end

function C2GSSaveClubArenaLineup(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("clubarena")
    oHuoDong:SaveClubArenaLineup(oPlayer,mData)
end

function C2GSOpenClubArenaDefense(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("clubarena")
    oHuoDong:SendClubArenaDefensePartner(oPlayer)
end

function C2GSShowClubArenaHistory(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("clubarena")
    oHuoDong:ShowClubArenaHistory(oPlayer)
end

function C2GSCleanClubArenaCD(oPlayer,mData)
    local oHDMgr = global.oHuodongMgr
    local oHuoDong = oHDMgr:GetHuodong("clubarena")
    oHuoDong:CleanCBTime(oPlayer)
end

