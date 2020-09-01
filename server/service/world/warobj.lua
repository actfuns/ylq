--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local colorstring = require "public.colorstring"

local warbaseobj = import(service_path("warbaseobj"))
local gamedefines = import(lualib_path("public.gamedefines"))

function NewWarMgr(...)
    local o = CWarMgr:New(...)
    return o
end

function NewWar(...)
    local o = CWar:New(...)
    return o
end

function NewKFWar(...)
    local o = CKFProxyWar:New(...)
    return o
end

CWarMgr = {}
CWarMgr.__index = CWarMgr
inherit(CWarMgr,warbaseobj.CWarMgr)


function CWarMgr:NewWar(id,mInfo)
    return NewWar(id, mInfo)
end

function CWarMgr:GetPlayerObject(iPid)
    return global.oWorldMgr:GetOnlinePlayerByPid(iPid)
end

function CWarMgr:TeamEnterWar(oPlayer,iWarId,mInfo,bForce)
    local oNewWar = self:GetWar(iWarId)
    assert(oNewWar, string.format("EnterWar error %d", iWarId))

    local oWorldMgr = global.oWorldMgr
    local mMem = mInfo["team_list"] or oPlayer:GetTeamMember()
    local mPlayer = {}
    for _,pid in ipairs(mMem) do
        local oMemPlayer = self:GetPlayerObject(pid)
        table.insert(mPlayer,oMemPlayer)
    end

    for _,oMemPlayer in pairs(mPlayer) do
        self:CheckLeaveWar(oPlayer,bForce)
    end

    for _,oMemPlayer in ipairs(mPlayer) do
        oNewWar:EnterPlayer(oMemPlayer,mInfo)
    end
    local fPackFightPartner = oNewWar.m_fPackFightPartner
    local mData = {}
    if fPackFightPartner then
        mData = fPackFightPartner(oNewWar,oPlayer,mPlayer)
    else
        local iCnt = table_count(mPlayer)
        local mFightPartner = oPlayer:GetFightPartner()
        local mPartnerList  = {}
        for iPos=iCnt+1,4 do
            local oPartner = mFightPartner[iPos]
            if oPartner then
                local mPartnerData = {
                    partnerdata = oPartner:PackWarInfo(),
                }
                table.insert(mPartnerList,mPartnerData)
                oNewWar:AddFightCnt(oPlayer:GetPid())
            end
        end
        table.insert(mData,{id = oPlayer:GetPid(),data=mPartnerList})
    end

    if #mData > 0 then
        for _,m in ipairs(mData) do
            self:PreparePartner(iWarId,{data = m["data"], camp_id = mInfo.camp_id,owner_id = m["id"]})
        end
        --self:PreparePartner(iWarId,{data = mData, camp_id = mInfo.camp_id,owner_id = oPlayer:GetPid()})
    end

    return {errcode = gamedefines.ERRCODE.ok}
end

--好友助战单人进入流程
function CWarMgr:FFEnterWar(oPlayer, iWarId, mInfo, bForce)
    local oNewWar = self:GetWar(iWarId)
    assert(oNewWar, string.format("EnterWar error %d", iWarId))
    local mCode = self:CheckLeaveWar(oPlayer,bForce)
    if mCode then
        return mCode
    end

    oNewWar:FFEnterPlayer(oPlayer, mInfo)

    local oCurrentPartner = mInfo.CurrentPartner
    local mFightPartner = mInfo.FightPartner or {}
    if  oCurrentPartner then
        mFightPartner = mFightPartner or {}
        local oFrdPtnWarInfo = mInfo.FrdPtnWarInfo
        if oFrdPtnWarInfo then
            oFrdPtnWarInfo.friend = true
            if #mFightPartner >= 3 then
                table.insert(mFightPartner,3,oFrdPtnWarInfo)
            else
                table.insert(mFightPartner,oFrdPtnWarInfo)
            end
        end
    end

    local mData = {}
    for iPos=2,4 do
        local oPartner = mFightPartner[iPos]
        if oPartner then
            local partnerdata
            if oPartner.friend then
                partnerdata = oPartner
            else
                partnerdata = oNewWar:SelectPartnerPackWarInfo(oPartner)
            end
            local mPartnerData = {
                partnerdata = partnerdata,
            }
            table.insert(mData,mPartnerData)
        end
    end
    if #mData > 0 then
        self:PreparePartner(iWarId,{data = mData, camp_id = mInfo.camp_id,owner_id = oPlayer:GetPid()})
    end
    return {errcode = gamedefines.ERRCODE.ok}
end


function CWarMgr:OnLeaveWar(oPlayer,mData)
end

function CWarMgr:SolveKaji(oPlayer)
    local oCbMgr = global.oCbMgr
    local oSceneMgr = global.oSceneMgr
    local oNotifyMgr = global.oNotifyMgr
    local oNowWar = oPlayer:GetNowWar()
    if not oNowWar then
        return
    end
    if oPlayer.m_oActiveCtrl:InSolveKaji() then
        local oNotifyMgr = global.oNotifyMgr
        oNotifyMgr:Notify(oPlayer:GetPid(),"正在解决")
        return
    end
    oPlayer.m_oActiveCtrl:SetNowWarInfo({solvekaji=1})

    local iCost = oPlayer:Coin() > 5000 and 5000 or oPlayer:Coin()
    if iCost > 0 then
        oPlayer:ResumeCoin(iCost,"一键解决卡机")
    end

    local iPid = oPlayer:GetPid()
    local iWarId = oNowWar:GetWarId()
    local func = function()
        local oWorldMgr = global.oWorldMgr
        local oP = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if not oP then
            return
        end
        local oWar = self:GetWar(iWarId)
        local iLeaveType = oWar.m_iLeaveType or 1
        local oTeam = oP:HasTeam()
        if oTeam and oTeam:MemberSize() >= 2 then
            oTeam:ShortLeave(iPid)
        end
        if iLeaveType == 1 then
            oSceneMgr:ChangeMap(oP,101000)
        end
        oNotifyMgr:Notify(oP:GetPid(),"已帮你恢复战斗中的卡机情况")
    end
    oNowWar.m_fSolveKaji = func
    oNowWar:Forward("C2GSWarEscape", oPlayer:GetPid(), {})
end

--[[
function CWarMgr:EnterKFWar(oPlayer,mInfo,mAgrgs,bForce)
    local iPid = oPlayer:GetPid()
    assert(global.oKFMgr:GetProxy(iPid),string.format("EnterKFWar null proxy %d",iPid))
    assert(not oPlayer:GetNowWar(),string.format("EnterKFWar %d ",iPid))
    local id = self:DispatchSceneId()
    local oWar = self:NewWar(id, mInfo)
     self:SetWar(id,oWar)
    oWar:EnterPlayer(oPlayer,mInfo)
end

function CWarMgr:NewKFWar(id,mInfo)
    return NewKFWar(id,mInfo)
end
]]


CWar = {}
CWar.__index = CWar
inherit(CWar, warbaseobj.CWar)

function CWar:RemoteLeavePlayer(oPlayer)
    local iPid = oPlayer:GetPid()
    oPlayer:ClearNowWarInfo()
    oPlayer:SetLogoutJudgeTime()
    if self.m_mPlayers[iPid] then
        self.m_mPlayers[iPid] = nil
        self.m_mCampPlayers[iPid] = nil
        local oSceneMgr = global.oSceneMgr
        oSceneMgr:OnLeaveWar(oPlayer)
        oSceneMgr:ReEnterScene(oPlayer)
    end
    return true
end

function CWar:OnEnterPlayer(oPlayer,mInfo,sFlag)
    local oSceneMgr = global.oSceneMgr
    oSceneMgr:OnEnterWar(oPlayer)
    oPlayer:SetLogoutJudgeTime(-1)
    oPlayer:OnEnterWar(false)
end

function CWar:OnLeavePlayer(oPlayer)
    oPlayer:ClearNowWarInfo()
    oPlayer:SetLogoutJudgeTime()
    local oSceneMgr = global.oSceneMgr
    oSceneMgr:OnLeaveWar(oPlayer)
    oSceneMgr:ReEnterScene(oPlayer)
end

function CWar:PackCurrentPartner(oPlayer,mInfo)
    local oCurrentPartner = mInfo.CurrentPartner
    if not oCurrentPartner then
        oCurrentPartner = self:GetData("Helper_MainPartner") or oPlayer.m_oPartnerCtrl:GetMainPartner()
    end
    if oCurrentPartner and type(oCurrentPartner) == "table" then
        local mWarData =  {}
        if self.m_iWarType == gamedefines.WAR_TYPE.TERRAWARS_TYPE and oCurrentPartner.PackTerraWarInfo then
            mWarData = oCurrentPartner:PackTerraWarInfo()
        elseif oCurrentPartner.PackWarInfo then
            mWarData = oCurrentPartner:PackWarInfo()
        elseif oCurrentPartner then
            mWarData = oCurrentPartner
        end
        mWarData.expertskill = {}
        return mWarData
    end
end

function CWar:PackPartnerFightData(oPlayer,mInfo)
    local mFightPartner = mInfo.FightPartner
    local mData = {}
    if not mFightPartner then
        mFightPartner = self:GetData("fight_partner") or oPlayer:GetFightPartner()
    end
    for i = 2,4  do
        local oPartner = mFightPartner[i]
        if oPartner then
            local mPartnerData = {partnerdata = self:SelectPartnerPackWarInfo(oPartner)}
            table.insert(mData,mPartnerData)
            self:AddFightCnt(oPlayer:GetPid())
        end
    end
    return mData
end

function CWar:SelectPartnerPackWarInfo(oPartner)
    if self.m_iWarType == gamedefines.WAR_TYPE.TERRAWARS_TYPE and oPartner.PackTerraWarInfo then
        return oPartner:PackTerraWarInfo()
    elseif self.m_iWarType == gamedefines.WAR_TYPE.PATA_TYPE and oPartner.PackPataWarInfo then
        return oPartner:PackPataWarInfo()
    elseif oPartner.PackWarInfo then
        return oPartner:PackWarInfo()
    else
        return oPartner
    end
end


--好友助战单人进入战斗
function CWar:FFEnterPlayer(oPlayer, mInfo)
    oPlayer:SetNowWarInfo({
        now_war = self.m_iWarId,
    })
    local mData = oPlayer:PackWarInfo()
    local oCurrentPartner = mInfo.CurrentPartner
    if oCurrentPartner or  mInfo.FrdPtnWarInfo then
        local mWarData
        if oCurrentPartner then
            mWarData = self:SelectPartnerPackWarInfo(oCurrentPartner)
        elseif mInfo.FrdPtnWarInfo then
            mWarData = mInfo.FrdPtnWarInfo
            mWarData.friend = true
        end
        mWarData.expertskill = {}
        local mPartnerData = {
            partnerdata = mWarData,
        }
        mData.partner = mPartnerData
        self.m_mEnterPartner[oPlayer:GetPid()] = mWarData.parid
        self:AddFightCnt(oPlayer:GetPid())
    end
    if self:GetData("close_auto_skill") then
        mData["auto_skill_switch"] = nil
    end
    local iCamp = mInfo.camp_id
    self.m_mPlayers[oPlayer:GetPid()] = true
    self.m_mCampPlayers[oPlayer:GetPid()] = iCamp
    local iEnemyCamp = self:EnemyCamp(iCamp)
    local mWarInfo = {
        war_id = self.m_iWarId,
        war_type = self.m_iWarType,
        extra_info = mInfo.extra_info
    }
    self:OnEnterPlayer(oPlayer,mInfo,"friend")
    interactive.Send(self.m_iRemoteAddr, "war", "EnterPlayer", {war_id = self.m_iWarId, wid = iWid, pid = oPlayer:GetPid(), data = mData, camp_id = mInfo.camp_id})
    self:GS2CShowWar(oPlayer,mWarInfo)
    self:AddFightCnt(oPlayer:GetPid())
    return true
end

function CWar:OnReEnterPlayer(oPlayer)
    oPlayer:SetLogoutJudgeTime(-1)
end

function CWar:OnEnterObserver(oPlayer)
    local oSceneMgr = global.oSceneMgr
    if not self.m_IsWarFilm then
        oSceneMgr:OnEnterWar(oPlayer)
    end
    oPlayer:SetLogoutJudgeTime(-1)
end

function CWar:InitAttr()
    local iTeamAveGrade = 0
    local iTeamMaxGrade = 0
    local iTeamMinGrade = 0
    local iTeamLeaderGrade = 0
    local iTeamPlayerAVG = 0
    for pid,iWid in pairs(self.m_mPlayers) do
        local oPlayer = self:GetPlayerObject(pid)
        if oPlayer then
            local oTeam = oPlayer:HasTeam()
            if oTeam then
                iTeamLeaderGrade = oTeam:GetLeaderGrade()
                iTeamAveGrade = oTeam:GetTeamAVG()
                iTeamMaxGrade = oTeam:GetTeamMaxGrade()
                iTeamMinGrade = oTeam:GetTeamMinGrade()
                iTeamPlayerAVG = math.floor(oTeam:GetTeamAveGrade()/5) * 5
            else
                local iGrade = oPlayer:GetGrade()
                iTeamLeaderGrade = iGrade
                iTeamAveGrade = oPlayer:GetAveGrade()
                iTeamMaxGrade = iGrade
                iTeamMinGrade = iGrade
                iTeamPlayerAVG = iGrade
            end
            break
        end
    end
    self:SetData("TeamAveGrade",iTeamAveGrade)
    self:SetData("TeamMaxGrade",iTeamMaxGrade)
    self:SetData("TeamMinGrade",iTeamMinGrade)
    self:SetData("TeamLeaderGrade",iTeamLeaderGrade)
    self:SetData("TeamPlayerAVG",iTeamPlayerAVG)
    self:SetData("TeamWLV",self:CalTeamWLV())
end

function CWar:RemoteLeaveObserver(oPlayer)
    local iPid = oPlayer:GetPid()
    oPlayer:ClearNowWarInfo()
    oPlayer:SetLogoutJudgeTime()
    if self.m_mObservers[iPid] then
        self.m_mObservers[iPid] = nil
        local oSceneMgr = global.oSceneMgr
        oSceneMgr:OnLeaveWar(oPlayer)
        oSceneMgr:ReEnterScene(oPlayer)
    end
end

function CWar:AddFriendDegree(mArg)
    if self.m_NoFriendDegree then
        return
    end
    self:AddFriendDegree2(mArg["win_list"] or {})
end

function CWar:AddFriendDegree2(plist)
    local oWorldMgr = global.oWorldMgr
    local oFriendMgr = global.oFriendMgr
    local friendlist = {}
    for _,pid in ipairs(plist) do
        local oPlayer = self:GetPlayerObject(pid)
        if oPlayer then
            local oFriend = oPlayer:GetFriend()
            for _,iTarget in ipairs(plist) do
                if oFriend:IsBothFriend(iTarget) and not friendlist[iTarget] then
                    if not friendlist[pid] then
                        friendlist[pid] = {}
                    end
                    table.insert(friendlist[pid],iTarget)
                end
            end
        end
    end
    for pid,m in pairs(friendlist) do
        for _,iTarget in ipairs(m) do
            oFriendMgr:AddFriendDegree(pid,iTarget,1)
        end
    end
end

