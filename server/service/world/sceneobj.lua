--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local res = require "base.res"
local geometry = require "base.geometry"
local extend = require "base.extend"
local record = require "public.record"

local idpool = import(lualib_path("base.idpool"))
local gamedefines = import(lualib_path("public.gamedefines"))


function NewSceneMgr(...)
    local o = CSceneMgr:New(...)
    return o
end

function NewScene(...)
    local o = CScene:New(...)
    return o
end

function NewAnLeiCtrl(...)
    local o = CAnLeiCtrl:New(...)
    return o
end


CSceneMgr = {}
CSceneMgr.__index = CSceneMgr
inherit(CSceneMgr, logic_base_cls())

function CSceneMgr:New(lSceneRemote)
    local o = super(CSceneMgr).New(self)
    o.m_iDispatchId = 0
    o.m_iSelectHash = 1
    o.m_lSceneRemote = lSceneRemote
    o.m_mScenes = {}
    o.m_mDurableScenes = {}

    return o
end

function CSceneMgr:Release()
    for _, v in pairs(self.m_mScenes) do
        baseobj_safe_release(v)
    end
    self.m_mScenes = {}
    super(CSceneMgr).Release(self)
end

function CSceneMgr:DispatchSceneId()
    self.m_iDispatchId = self.m_iDispatchId + 1
    return self.m_iDispatchId
end

function CSceneMgr:RandomPos(iMapId,mExcule)
    local iMapRes = res["daobiao"]["map"][iMapId]["resource_id"]
    assert(iMapRes, string.format("RandomPos err %d", iMapId))
    local mPosList = res["map"]["npc_area"][iMapRes]
    local mPos = extend.Random.random_choice(mPosList)
    local x,y = table.unpack(mPos)
    local iCount = 0
    while (iCount < 100 and mExcule and mExcule[x] and mExcule[x][y]) do
        mPos = extend.Random.random_choice(mPosList)
        x,y = table.unpack(mPos)
        iCount = iCount + 1
    end
    return x,y
end

function CSceneMgr:RandomMonsterPos(iMapId,iCount)
    local iAmount = iCount or 1
    local iMapRes = res["daobiao"]["map"][iMapId]["resource_id"]
    assert(iMapRes, string.format("RandomMonsterPos err %d", iMapId))
    assert(res["map"]["monster"][iMapRes],string.format("RandomMonsterPos res_err:%d",iMapId,iMapRes))
    local mPosList = table_deep_copy(res["map"]["monster"][iMapRes])
    local mReturn = {}
    local mTemp = {}
    for i = 1,iAmount do
        local mPos,iIndex = extend.Random.random_choice(mPosList)
        table.insert(mReturn,mPos)
        table.remove(mPosList,iIndex)
    end
    return mReturn
end

function CSceneMgr:GetAllMonsterPos(iMapId)
    local iMapRes = res["daobiao"]["map"][iMapId]["resource_id"]
    assert(iMapRes, string.format("GetAllMonSterPos err %d", iMapId))
    local mPosList = table_deep_copy(res["map"]["monster"][iMapRes])
    return table_deep_copy(mPosList)
end

function CSceneMgr:RandomHeroBoxPos(iMapId,iCount)
    local iAmount = iCount or 1
    local iMapRes = res["daobiao"]["map"][iMapId]["resource_id"]
    assert(iMapRes, string.format("RandomHeroBoxPos err %d", iMapId))
    assert(res["map"]["herobox"][iMapRes],string.format("RandomHeroBoxPos res_err:%d",iMapId,iMapRes))
    local mPosList = table_deep_copy(res["map"]["herobox"][iMapRes])
    local mReturn = {}
    local mTemp = {}
    for i = 1,iAmount do
        local mPos,iIndex = extend.Random.random_choice(mPosList)
        table.insert(mReturn,mPos)
        table.remove(mPosList,iIndex)
    end
    return mReturn
end

function CSceneMgr:SelectRemoteScene()
    local iSel = self.m_iSelectHash
    if iSel >= #self.m_lSceneRemote then
        self.m_iSelectHash = 1
    else
        self.m_iSelectHash = iSel + 1
    end
    return self.m_lSceneRemote[iSel]
end

function CSceneMgr:GetRemoteAddr()
    return self.m_lSceneRemote
end

function CSceneMgr:GetSceneLineSchedule(iMapId)
    local mData = res["daobiao"]["map"][iMapId]
    return mData["line_schedule"]
end

function CSceneMgr:GetLineTargetSceneId(iMapId,iSchedule)
    local iTargetId
    local m = self.m_mDurableScenes[iMapId]
    if m then
        if iSchedule == 0 then
            iTargetId = m[1]
        elseif iSchedule == 1 then
            for _,iScene in ipairs(m) do
                local oScene = self:GetScene(iScene)
                if oScene:GetPlayersCnt() < 5000 then
                    return iScene
                end
            end
            iTargetId = m[1]
        end
    end
    return iTargetId
end

function CSceneMgr:SelectDurableScene(iMapId)
    local iSchedule = self:GetSceneLineSchedule(iMapId)
    local iTargetId = self:GetLineTargetSceneId(iMapId,iSchedule)
    if iTargetId then
        return self:GetScene(iTargetId)
    end
end

function CSceneMgr:CreateScene(mInfo)
    local id = self:DispatchSceneId()
    local oScene = NewScene(id, mInfo)
    oScene:ConfirmRemote()
    self.m_mScenes[id] = oScene

    if oScene:IsDurable() then
        local iMapId = oScene:MapId()
        local m = self.m_mDurableScenes[iMapId]
        if not m then
            self.m_mDurableScenes[iMapId] = {}
            m = self.m_mDurableScenes[iMapId]
        end
        table.insert(m, oScene:GetSceneId())
    end

    return oScene
end

function CSceneMgr:CreateVirtualScene(mInfo)
    assert (not mInfo.is_durable, "virtual scene cann't be durable")

    local id = self:DispatchSceneId()
    local oScene = NewScene(id, mInfo)
    oScene.m_sType = "virtual"
    oScene:ConfirmRemote()
    self.m_mScenes[id] = oScene
    return oScene
end

function CSceneMgr:GetScene(id)
    return self.m_mScenes[id]
end

function CSceneMgr:RemoveScene(id)
    local oScene = self.m_mScenes[id]
    if oScene then
        self.m_mScenes[id] = nil
        baseobj_delay_release(oScene)
    end
end

function CSceneMgr:GetSceneListByMap(iMapId)
    local mScene = self.m_mDurableScenes[iMapId] or {}
    local mSceneObj = {}
    for _,iScene in ipairs(mScene) do
        local oScene = self:GetScene(iScene)
        table.insert(mSceneObj,oScene)
    end
    return mSceneObj
end

function CSceneMgr:GetSceneName(iMapId)
    local mScene = self.m_mDurableScenes[tonumber(iMapId)] or {}
    for _,iScene in pairs(mScene) do
        local oScene = self:GetScene(iScene)
        return oScene:GetName()
    end
end

function CSceneMgr:OnEnterWar(oPlayer)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oNowScene then
        oNowScene:NotifyEnterWar(oPlayer)
    end
end

function CSceneMgr:OnLeaveWar(oPlayer)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oNowScene then
        oNowScene:NotifyLeaveWar(oPlayer)
    end
end

function CSceneMgr:NpcEnterWar(oNpc)
    if not oNpc.m_Scene then
        return
    end
    local oScene = self:GetScene(oNpc.m_Scene)
    if oScene then
        oScene:NpcEnterWar(oNpc)
    end
end

function CSceneMgr:NpcLeaveWar(oNpc)
    if not oNpc.m_Scene then
        return
    end
    local oScene = self:GetScene(oNpc.m_Scene)
    if oScene then
        oScene:NpcLeaveWar(oNpc)
    end
end

function CSceneMgr:OnDisconnected(oPlayer)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oNowScene then
        oNowScene:NotifyDisconnected(oPlayer)
    end
end

function CSceneMgr:OnLogout(oPlayer)
    self:LeaveScene(oPlayer, true)
end

function CSceneMgr:OnLogin(oPlayer, bReEnter)
    if bReEnter then
        self:ReEnterScene(oPlayer)
    else
        --lxldebug test
        self:EnterDurableScene(oPlayer)
    end
end

function CSceneMgr:EnterDurableScene(oPlayer)
    local mDurableInfo = oPlayer.m_oActiveCtrl:GetDurableSceneInfo()
    local iMapId = mDurableInfo.map_id
    local mPos = mDurableInfo.pos
    local oScene = self:SelectDurableScene(iMapId)
    self:EnterScene(oPlayer, oScene:GetSceneId(), {pos = mPos}, true)
end

function CSceneMgr:TeamEnterDurableScene(oPlayer)
    local mDurableInfo = oPlayer.m_oActiveCtrl:GetDurableSceneInfo()
    local iMapId = mDurableInfo.map_id
    local mPos = mDurableInfo.pos
    local oScene = self:SelectDurableScene(iMapId)
    self:TeamEnterScene(oPlayer, oScene:GetSceneId(), {pos = mPos}, true)
end

function CSceneMgr:ReEnterScene(oPlayer)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    oNowScene:ReEnterPlayer(oPlayer)
    return {errcode = gamedefines.ERRCODE.ok}
end

function CSceneMgr:LeaveScene(oPlayer, bForce)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if not oNowScene then
        return {errcode = gamedefines.ERRCODE.ok}
    end
    if not bForce then
        if not oNowScene:VaildLeave(oPlayer) then
            return {errcode = gamedefines.ERRCODE.common}
        end
    end
    oNowScene:LeavePlayer(oPlayer)
    return {errcode = gamedefines.ERRCODE.ok}
end

function CSceneMgr:TeamEnterScene(oPlayer,iScene,mInfo,bForce)
    local oWorldMgr = global.oWorldMgr
    local oNewScene = self:GetScene(iScene)
    assert(oNewScene, string.format("EnterScene error %d", iScene))
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()

    local mMem = oPlayer:GetTeamMember()
    local mPlayer = {}
    for _,pid in ipairs(mMem) do
        local oMemPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
        table.insert(mPlayer,oMemPlayer)
    end

    if not bForce then
        for _,oMemPlayer in pairs(mPlayer) do
            if oNowScene and not oNowScene:VaildLeave(oMemPlayer) then
                return {errcode = gamedefines.ERRCODE.common}
            end
            if not oNewScene:VaildEnter(oMemPlayer) then
                return {errcode = gamedefines.ERRCODE.common}
            end
        end
    end

    self:RemoveSceneTeam(oPlayer, oPlayer:TeamID())

    for _,oMemPlayer in pairs(mPlayer) do
        local oMemScene = oMemPlayer.m_oActiveCtrl:GetNowScene()
        if oMemScene then
            oMemScene:LeavePlayer(oMemPlayer)
        end
        oNewScene:EnterPlayer(oMemPlayer,mInfo.pos)
    end

    self:CreateSceneTeam(oPlayer)

    return {errcode = gamedefines.ERRCODE.ok}
end

function CSceneMgr:EnterScene(oPlayer, iScene, mInfo, bForce)
    local oNewScene = self:GetScene(iScene)
    assert(oNewScene, string.format("EnterScene error %d", iScene))
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local oTeam = oPlayer:HasTeam()
    local iPid = oPlayer:GetPid()
    if oPlayer:IsTeamLeader() then
        print("hcdebug:EnterScene err-----",debug.traceback())
        self:TeamEnterScene(oPlayer, iScene,mInfo,bForce)
        return
    end
    if oTeam and oTeam:IsTeamMember(iPid) then
        print("hcdebug:EnterScene err-----",debug.traceback())
    end
    if not bForce then
        if oNowScene and not oNowScene:VaildLeave(oPlayer) then
            return {errcode = gamedefines.ERRCODE.common}
        end
        if not oNewScene:VaildEnter(oPlayer) then
            return {errcode = gamedefines.ERRCODE.common}
        end
    end

    if oNowScene then
        oNowScene:LeavePlayer(oPlayer)
    end
    oNewScene:EnterPlayer(oPlayer, mInfo.pos)

    return {errcode = gamedefines.ERRCODE.ok}
end

function CSceneMgr:ChangeMap(oPlayer, iMapId)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oNowScene:MapId() == iMapId then
        return
    end
    if iMapId == 0 then
        return
    end
    local iNewX,iNewY = self:GetFlyData(iMapId)
    local oScene = self:SelectDurableScene(iMapId)
    if oScene then
        local mNowPos = oPlayer.m_oActiveCtrl:GetNowPos()
        if oPlayer:IsTeamLeader() then
            self:TeamEnterScene(oPlayer,oScene:GetSceneId(),{pos = {x = iNewX,y = iNewY, face_x = mNowPos.face_x, face_y = mNowPos.face_y, }},true)
        else
            self:EnterScene(oPlayer, oScene:GetSceneId(), {pos = {x=iNewX, y = iNewY, face_x = mNowPos.face_x, face_y = mNowPos.face_y,}}, true)
        end
    end
end

function CSceneMgr:ClickTrapMineMap(oPlayer, iMapId)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oNowScene:MapId() == iMapId then
        return
    end
    local iNewX,iNewY = self:GetFlyData(iMapId)
    local oScene = self:SelectDurableScene(iMapId)
    if not oScene:HasAnLei() then
        return
    end
    if oScene then
        local mNowPos = oPlayer.m_oActiveCtrl:GetNowPos()
            if oPlayer:IsTeamLeader() then
                self:TeamEnterScene(oPlayer,oScene:GetSceneId(),{pos = {x = iNewX,y = iNewY, face_x = mNowPos.face_x, face_y = mNowPos.face_y}},true)
            else
                self:EnterScene(oPlayer, oScene:GetSceneId(), {pos = {x=iNewX, y = iNewY, face_x = mNowPos.face_x, face_y = mNowPos.face_y,}}, true)
            end
    end
end

function CSceneMgr:ClickOfflineTrapMineMap(oPlayer, iMapId)
    local res = require "base.res"
    local lPos = res["daobiao"]["patrol"][iMapId]
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local mPos = lPos[math.random(#lPos)]
    local iNewX = mPos.x
    local iNewY = mPos.y
    local oScene = self:SelectDurableScene(iMapId)
    if not oScene:HasAnLei() then
        return
    end
    local mNowPos = oPlayer.m_oActiveCtrl:GetNowPos()
    local mPos = {x=iNewX, y = iNewY, face_x = mNowPos.face_x, face_y = mNowPos.face_y,}
    if oPlayer:IsTeamLeader() then
        self:TeamEnterScene(oPlayer, oScene:GetSceneId(), {pos=mPos}, true)
    else
        if not oPlayer:IsSingle() then return end
        self:EnterScene(oPlayer, oScene:GetSceneId(), {pos=mPos}, true)
    end
    -- self:EnterScene(oPlayer, oScene:GetSceneId(), {pos = }, true)
end

function CSceneMgr:TransferPlayerBySceneID(iPid, iScene, iX, iY,func)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end

    local oScene = self:GetScene(iScene)
    if not oScene then return end

    if iX == 0 or iY == 0 then
        iX, iY = self:RandomPos(oScene:MapId())
    end

    local mNowPos = oPlayer.m_oActiveCtrl:GetNowPos()
    local mPos = {x=iX, y=iY, z=mNowPos.z, face_x = mNowPos.face_x, face_y = mNowPos.face_y, face_z = mNowPos.face_z}

    if oPlayer:IsTeamLeader() then
        self:TeamEnterScene(oPlayer, oScene:GetSceneId(), {pos=mPos}, true)
    else
        if not oPlayer:IsSingle() then return end
        self:EnterScene(oPlayer, oScene:GetSceneId(), {pos=mPos}, true, func)
    end
end

function CSceneMgr:TransferPlayerByMapID(iPid, iMapId, iX, iY,func)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then return end

    local oScene = self:SelectDurableScene(iMapId)
    if not oScene then return end

    if iX == 0 or iY == 0 then
        iX, iY = self:RandomPos(oScene:MapId())
    end

    local mNowPos = oPlayer.m_oActiveCtrl:GetNowPos()
    local mPos = {x=iX, y=iY, z=mNowPos.z, face_x = mNowPos.face_x, face_y = mNowPos.face_y, face_z = mNowPos.face_z}

    if oPlayer:IsTeamLeader() then
        self:TeamEnterScene(oPlayer, oScene:GetSceneId(), {pos=mPos}, true)
    else
        if not oPlayer:IsSingle() then return end
        self:EnterScene(oPlayer, oScene:GetSceneId(), {pos=mPos}, true, func)
    end
end

function CSceneMgr:TransferScene(oPlayer, iTransferId)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if oNowScene then
        local lTransfers = oNowScene:GetTransfers()
        if not lTransfers then
            return
        end
        local m = lTransfers[iTransferId]
        if not m or not next(m) then
            return
        end
        local iX, iY, iTargetMapIndex, iTargetX, iTargetY = m.x, m.y, m.target_scene, m.target_x, m.target_y
        oNowScene:QueryRemote("player_pos", {pid = oPlayer:GetPid()}, function (mRecord, mData)
            local m = mData.data
            if not m then
                return
            end
            local mMapInfo = res["daobiao"]["scene"][iTargetMapIndex]
            if not mMapInfo then
                return
            end

            local iRemoteScene = m.scene_id
            local iRemotePid = m.pid
            local mRemotePos = m.pos_info
            local oWorldMgr = global.oWorldMgr
            local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iRemotePid)
            local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
            if not oNowScene or oNowScene:GetSceneId() ~= iRemoteScene or oNowScene:MapId() == mMapInfo.map_id then
                return
            end
            if ((mRemotePos.x - iX) ^ 2 + (mRemotePos.y - iY) ^ 2) > 12 ^ 2 then
                return
            end
            local oScene = self:SelectDurableScene(mMapInfo.map_id)
            if oScene then
                if not is_release(self) then
                    local mNowPos = oPlayer.m_oActiveCtrl:GetNowPos()
                    if oPlayer:IsTeamLeader() then
                        self:TeamEnterScene(oPlayer,oScene:GetSceneId(),{pos = {x = iTargetX,y = iTargetY, face_x = mNowPos.face_x, face_y = mNowPos.face_y,}},true)
                    else
                        self:EnterScene(oPlayer, oScene:GetSceneId(), {pos = {x = iTargetX, y = iTargetY, face_x = mNowPos.face_x, face_y = mNowPos.face_y,}}, true)
                    end
                end
            end
        end)
    end
end

function CSceneMgr:TransToLeader(oPlayer,iLeader)
    local oWorldMgr = global.oWorldMgr
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(iLeader)
    if not oLeader then
        return
    end
     local oLeaderNowScene = oLeader.m_oActiveCtrl:GetNowScene()
    if not oLeaderNowScene or not oLeaderNowScene:VaildEnter(oPlayer,oLeader) then
        return
    end
    local iPid = oPlayer:GetPid()
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local mLeaderNowPos = oLeader:GetNowPos()
    if oNowScene:GetSceneId() == oLeaderNowScene:GetSceneId() then
        local mData = {
            x = mLeaderNowPos.x,
            y = mLeaderNowPos.y,
            face_x = mLeaderNowPos.face_x,
            face_y = mLeaderNowPos.face_y
        }
        oLeaderNowScene:SetPlayerPos(iPid,mData)
    else
        local iScene = oLeaderNowScene:GetSceneId()
        self:EnterScene(oPlayer,iScene, {pos = mLeaderNowPos})
    end
end

function CSceneMgr:QueryPos(pid,func)
    local oWorldMgr = global.oWorldMgr
    local oLeader = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oLeader then
        return
    end
    local oNowScene = oLeader.m_oActiveCtrl:GetNowScene()
    if  not oNowScene then
        return
    end
    oNowScene:QueryRemote("player_pos",{pid=pid},function (mRecord,mData)
        local m = mData.data
        if not m then
            return
        end
        func(m)
    end)
end

function CSceneMgr:SceneAutoFindPath(pid,iMapId,iX,iY,npcid,iAutoType,iCallBackSessionIdx,iSystem)
    iAutoType = iAutoType or 1
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(pid)
    if not oPlayer then
        return
    end

    if oPlayer:HasTeam() and (not oPlayer:IsTeamLeader() and not oPlayer:IsTeamShortLeave())then
        return
    end

    local mNowPos = oPlayer.m_oActiveCtrl:GetNowPos()
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local iNowMapId = oScene:MapId()
    local mNet = {}
    mNet["map_id"] = iMapId
    mNet["pos_x"] = math.floor(geometry.Cover(iX))
    mNet["pos_y"] =math.floor(geometry.Cover(iY))
    mNet["npcid"] = npcid
    mNet["autotype"] = iAutoType
    mNet["callback_sessionidx"] = iCallBackSessionIdx
    mNet["system"] = iSystem
    if iAutoType == 1 and iNowMapId ~= iMapId then
        local oScene = self:SelectDurableScene(iMapId)
        local iNewX,iNewY = self:GetFlyData(iMapId)
        if oPlayer:IsTeamLeader() then
            self:TeamEnterScene(oPlayer, oScene:GetSceneId(), {pos = {x = iNewX, y = iNewY , z = mNowPos.z, face_x = mNowPos.face_x, face_y = mNowPos.face_y, face_z = mNowPos.face_z}},true)
        else
            self:EnterScene(oPlayer, oScene:GetSceneId(), {pos = {x = iNewX, y = iNewY , z = mNowPos.z, face_x = mNowPos.face_x, face_y = mNowPos.face_y, face_z = mNowPos.face_z}},true)
        end
        oPlayer:Send("GS2CAutoFindPath",mNet)
    else
        oPlayer:Send("GS2CAutoFindPath",mNet)
    end
end

function CSceneMgr:GetFlyData(iMapId)
    local res = require "base.res"
    local mData = assert(res["daobiao"]["scenefly"][iMapId], string.format("GetFlyData fail %d", iMapId))
    local iX,iY = table.unpack(mData["pos"])
    iX = iX or 10
    iY = iY or 10
    return iX,iY
end

function CSceneMgr:RemoteEvent(sEvent, mData)
    local oWorldMgr = global.oWorldMgr
    if sEvent == "player_enter_scene" then
        local iPid = mData.pid
        local iSceneId = mData.scene_id
        local oScenePlayerShareObj = mData.scene_player_share
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            oPlayer.m_oActiveCtrl:SetSceneShareObj(oScenePlayerShareObj)
            local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
            if iSceneId == oScene:GetSceneId() then
                local lFunc = oScene.m_OnRemoteEvent or {}
                for id, func in ipairs(lFunc) do
                    func(oScene, oPlayer)
                end
            end
        end
    elseif sEvent == "player_leave_scene" then
        local iPid = mData.pid
        local iSceneId = mData.scene_id
        local iEid = mData.eid
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
            if iSceneId == oScene:GetSceneId() then
                oPlayer.m_oActiveCtrl:ClearSceneShareObj()
            end
        end
        local oScene = self:GetScene(iSceneId)
        if oScene and iEid then
            oScene.m_oIDPool:Free(iEid)
        end
    elseif sEvent == "team_leave_scene" then
        local iSceneId = mData.scene_id
        local iEid = mData.eid
        local oScene = self:GetScene(iSceneId)
        if oScene and iEid then
            oScene.m_oIDPool:Free(iEid)
        end
    elseif sEvent == "npc_leave_scene" then
        local iSceneId = mData.scene_id
        local iEid = mData.eid
        local oScene = self:GetScene(iSceneId)
        if oScene and iEid then
            oScene.m_oIDPool:Free(iEid)
        end
    end
    return true
end

function CSceneMgr:CreateSceneTeam(oPlayer)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if not oNowScene then
        return
    end
    oNowScene:CreateSceneTeam(oPlayer)
end

function CSceneMgr:RemoveSceneTeam(oPlayer, iTeamId)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if not oNowScene then
        return
    end
    oNowScene:RemoveSceneTeam(oPlayer, iTeamId)
end

function CSceneMgr:SyncSceneTeam(oPlayer)
    local oNowScene = oPlayer.m_oActiveCtrl:GetNowScene()
    if not oNowScene then
        return
    end
    oNowScene:SyncSceneTeam(oPlayer,iTeamID)
end

function CSceneMgr:IsInLeiTai(iScene, iX, iY)
    local oScene = self:GetScene(iScene)
    assert(oScene, string.format("IsInLeiTai err: %s %s %s", iScene, iX, iY))
    local iMapId = oScene:MapId()

    local iMapRes = res["daobiao"]["map"][iMapId]["resource_id"]
    assert(iMapRes, string.format("RandomPos err %d", iMapId))
    local mLeiTai = res["map"]["leitai"][iMapRes]
    if not mLeiTai then
        return false
    end

    local iYIdx = math.floor(iY / 0.32)
    iYIdx = mLeiTai["len"] - iYIdx
    local iXIdx = math.floor(iX / 0.32)
    if not mLeiTai["leitaidata"][iYIdx] or not mLeiTai["leitaidata"][iYIdx][iXIdx] then
        return false
    else
        return true
    end
end

CScene = {}
CScene.__index = CScene
inherit(CScene, logic_base_cls())

function CScene:New(id, mInfo)
    local o = super(CScene).New(self)
    o.m_iSceneId = id
    o.m_iRemoteAddr = nil
    o.m_iMapId = mInfo.map_id
    o.m_bIsDurable = mInfo.is_durable
    o.m_bHasAnLei = mInfo.has_anlei
    o.m_iSceneType = mInfo.scene_type
    o.m_sSceneName = mInfo.scene_name
    o.m_iNewMan = mInfo.new_man
    o.m_oIDPool =  idpool.CIDPool:New(2)

    o.m_mPlayers = {}
    o.m_mNpc = {}

    if o.m_bHasAnLei then
        o.m_oAnLeiCtrl = NewAnLeiCtrl(id)
    end
    o:Init()
    return o
end

function CScene:Init()
    local iTime = 30*1000
    local oSceneMgr = global.oSceneMgr
    local iSceneId = self:GetSceneId()
    local fCallBack
    fCallBack = function ()
        self:DelTimeCb("_IDPoolProduce")
        local oScene = oSceneMgr:GetScene(iSceneId)
        if oScene then
            oScene.m_oIDPool:Produce()
        end
        self:AddTimeCb("_IDPoolProduce",iTime,fCallBack)
    end
    fCallBack()
    self.m_OnRemoteEvent = {}
end

function CScene:Release()
    local oWorldMgr = global.oWorldMgr
    local oSceneMgr = global.oSceneMgr
    local oWarMgr = global.oWarMgr
    self.m_OnLeave = nil
    self.m_OnRemoteEvent = nil
    self.m_OnEnter = nil
    for iPid,_ in pairs(self.m_mPlayers) do
        local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local oWar = oPlayer.m_oActiveCtrl:GetNowWar()
            if oWar then
                oWar:ForceRemoveWar()
            end
            local oTeam = oPlayer:HasTeam()
            if oTeam then
                if oTeam:IsLeader(iPid) then
                    oSceneMgr:TeamEnterDurableScene(oPlayer)
                end
            else
                oSceneMgr:EnterDurableScene(oPlayer)
            end
        end
    end
    interactive.Send(self.m_iRemoteAddr, "scene", "RemoveRemote", {scene_id = self.m_iSceneId})
    super(CScene).Release(self)
end

function CScene:HasAnLei()
    return self.m_bHasAnLei
end

function CScene:GetSceneId()
    return self.m_iSceneId
end

function CScene:GetResData()
    return table_get_depth(res["daobiao"]["scene"],{self.m_iSceneType,})
end

function CScene:GetName()
    if self.m_sSceneName then
        return self.m_sSceneName
    end
    local mResData = self:GetResData()
    return mResData["scene_name"]
end

function CScene:GetTransfers()
    if not self:IsDurable() then
        return
    end
    local mResData = self:GetResData()
    return mResData["transfers"]
end

function CScene:QueryLimitRule(sKey,dafualt)
    local mRule = self.m_LimitRule or {}
    return mRule[sKey] or dafualt
end

function CScene:SetLimitRule(sKey,val)
    self.m_LimitRule = self.m_LimitRule or {}
    self.m_LimitRule[sKey] = val
end

function CScene:DispatchEntityId()
    local iEid = self.m_oIDPool:Gain()
    return iEid
end

function CScene:MapId()
    return self.m_iMapId
end

function CScene:IsDurable()
    return self.m_bIsDurable
end

function CScene:ConfirmRemote()
    local oSceneMgr = global.oSceneMgr
    local iRemoteAddr = oSceneMgr:SelectRemoteScene()
    self.m_iRemoteAddr = iRemoteAddr
    interactive.Send(iRemoteAddr, "scene", "ConfirmRemote", {scene_id = self.m_iSceneId, map_id = self.m_iMapId})
end

function CScene:GetRemoteAddr()
    return self.m_iRemoteAddr
end

function CScene:VaildLeave(oPlayer)
    if self.m_fVaildLeave then
        return self.m_fVaildLeave(self,oPlayer)
    end
    return true
end

function CScene:VaildEnter(oPlayer,oLeader)
    if self.m_fVaildEnter then
        return self.m_fVaildEnter(self,oPlayer,oLeader)
    end
    return true
end

function CScene:LeavePlayer(oPlayer)
    if self:IsDurable() then
        local mPos = oPlayer.m_oActiveCtrl:GetNowPos()
        oPlayer.m_oActiveCtrl:SetDurableSceneInfo(self.m_iMapId, mPos)
    end
    oPlayer:OnLeaveScene()
    oPlayer.m_oActiveCtrl:ClearNowSceneInfo()
    local iEid = self.m_mPlayers[oPlayer:GetPid()]
    self.m_mPlayers[oPlayer:GetPid()] = nil

    interactive.Send(self.m_iRemoteAddr, "scene", "LeavePlayer", {scene_id = self.m_iSceneId, pid = oPlayer:GetPid()})

    if self:HasAnLei() then
        self.m_oAnLeiCtrl:Del(oPlayer:GetPid())
    end
    if self.m_OnLeave then
        self.m_OnLeave(self,oPlayer)
    end
    oPlayer:SyncTeamSceneInfo()

    return true
end

function CScene:OnSyncPos(oPlayer, mPosInfo)
    local mPos = gamedefines.RecoverPos(mPosInfo)
    oPlayer.m_oActiveCtrl:SetNowSceneInfo({
        now_scene = self.m_iSceneId,
        now_pos = mPos,
    })
    if self:IsDurable() then
        oPlayer.m_oActiveCtrl:SetDurableSceneInfo(self.m_iMapId, mPos)
    end
end

function CScene:SyncPlayerInfo(oPlayer, mArgs)
    local iEid = self.m_mPlayers[oPlayer:GetPid()]
    if iEid then
        interactive.Send(self.m_iRemoteAddr, "scene", "SyncPlayerInfo", {scene_id = self.m_iSceneId, eid = iEid, args = mArgs})
    end
end

function CScene:EnterPlayer(oPlayer, mPos)
    assert(not self.m_mPlayers[oPlayer:GetPid()],"EnterPlayer repetead")
    oPlayer.m_oActiveCtrl:SetNowSceneInfo({
        now_scene = self.m_iSceneId,
        now_pos = mPos,
    })
    if self:IsDurable() then
        oPlayer.m_oActiveCtrl:SetDurableSceneInfo(self.m_iMapId, mPos)
    end
    if self.m_PreOnEnter then
        self.m_PreOnEnter(self,oPlayer)
    end
    local iEid = self:DispatchEntityId()
    self.m_mPlayers[oPlayer:GetPid()] = iEid
    local iSceneType = self:IsDurable() and 0 or 1
    oPlayer:Send("GS2CShowScene", {scene_id = self.m_iSceneId, scene_name = self:GetName(), map_id = self:MapId(), new_man = self.m_iNewMan,type = iSceneType})
    local mData = {scene_id = self.m_iSceneId, eid = iEid, data = oPlayer:PackSceneInfo(), pid = oPlayer:GetPid(), pos = mPos,ignore = oPlayer.m_oToday:Query("gm_ignorewalk")}
    interactive.Send(self.m_iRemoteAddr, "scene", "EnterPlayer",mData)
    if self:HasAnLei() then
        self.m_oAnLeiCtrl:Add(oPlayer:GetPid(), {x = mPos.x, y = mPos.y})
    end
    if self.m_OnEnter then
        self.m_OnEnter(self,oPlayer)
    end
    oPlayer:SyncTeamSceneInfo()
    return true
end

function CScene:GetPlayersCnt()
    return table_count(self.m_mPlayers)
end

function CScene:GetPlayers()
    local lPlayers = {}
    for iPid,_ in pairs(self.m_mPlayers) do
        table.insert(lPlayers,iPid)
    end
    return lPlayers
end

function CScene:ReEnterPlayer(oPlayer)
    if self:HasAnLei() then
        local mPos = oPlayer.m_oActiveCtrl:GetNowPos()
        self.m_oAnLeiCtrl:Add(oPlayer:GetPid(), {x = mPos.x, y = mPos.y})
    end
    local iSceneType = self:IsDurable() and 0 or 1
    oPlayer:Send("GS2CShowScene", {scene_id = self.m_iSceneId, scene_name = self:GetName(), map_id = self:MapId(), new_man = self.m_iNewMan,type = iSceneType})
    interactive.Send(self.m_iRemoteAddr, "scene", "ReEnterPlayer", {scene_id = self.m_iSceneId, pid = oPlayer:GetPid()})
    return true
end

function CScene:GetEidByPid(iPid)
    return self.m_mPlayers[iPid]
end

function CScene:NotifyDisconnected(oPlayer)
    interactive.Send(self.m_iRemoteAddr, "scene", "NotifyDisconnected", {scene_id = self.m_iSceneId, pid = oPlayer:GetPid()})
    return true
end

--当前频道使用
function CScene:SendCurrentChat(oPlayer, mData)
    interactive.Send(self.m_iRemoteAddr, "scene", "SceneAoiChat", {scene_id = self.m_iSceneId, pid = oPlayer:GetPid(), net = mData})
    return true
end

--特殊场景使用
function CScene:BroadCast(sMessage,mData)
    interactive.Send(self.m_iRemoteAddr,"scene","SceneBroadCast",{scene_id = self.m_iSceneId,message = sMessage,net = mData})
    return true
end

function CScene:NotifyEnterWar(oPlayer)
    interactive.Send(self.m_iRemoteAddr, "scene", "NotifyEnterWar", {scene_id = self.m_iSceneId, pid = oPlayer:GetPid()})
    return true
end

function CScene:NotifyLeaveWar(oPlayer)
    interactive.Send(self.m_iRemoteAddr, "scene", "NotifyLeaveWar", {scene_id = self.m_iSceneId, pid = oPlayer:GetPid()})
    return true
end

function CScene:Forward(sCmd, iPid, mData)
    interactive.Send(self.m_iRemoteAddr, "scene", "Forward", {pid = iPid, scene_id = self.m_iSceneId, cmd = sCmd, data = mData})
    return true
end

function CScene:QueryRemote(sType, mData, func)
    interactive.Request(self.m_iRemoteAddr, "scene", "Query", {scene_id = self.m_iSceneId, type = sType, data = mData}, func)
end

function CScene:SetPlayerPos(iPid,mData)
    interactive.Send(self.m_iRemoteAddr, "scene", "SetPlayerPos", {pid = iPid, scene_id = self.m_iSceneId, data = mData})
end

function CScene:SyncPlayersPos(lPid, mData, func)
    interactive.Request(self.m_iRemoteAddr, "scene", "SyncPlayersPos", {pids = lPid, scene_id = self.m_iSceneId, data = mData}, func)
end

function CScene:EnterNpc(oNpc)
    local iEid = self:DispatchEntityId()
    self.m_mNpc[oNpc.m_ID] = iEid
    local mData = oNpc:PackSceneInfo()
    local mPos = oNpc:PosInfo()
    interactive.Send(self.m_iRemoteAddr, "scene", "EnterNpc", {scene_id = self.m_iSceneId, eid = iEid,pos=mPos,data=mData})
end

function CScene:NpcList()
    return self.m_mNpc
end

function CScene:SyncNpcInfo(oNpc,mArgs)
    local iEid = self.m_mNpc[oNpc.m_ID]
    if iEid then
        interactive.Send(self.m_iRemoteAddr, "scene", "SyncNpcInfo", {scene_id = self.m_iSceneId, eid = iEid, args = mArgs})
    end
end

function CScene:NpcEnterWar(oNpc)
    local iEid = self.m_mNpc[oNpc.m_ID]
    if iEid then
        interactive.Send(self.m_iRemoteAddr, "scene", "NpcEnterWar", {scene_id = self.m_iSceneId, eid = iEid})
    end
end

function CScene:NpcLeaveWar(oNpc)
    local iEid = self.m_mNpc[oNpc.m_ID]
    if iEid then
        interactive.Send(self.m_iRemoteAddr, "scene", "NpcLeaveWar", {scene_id = self.m_iSceneId, eid = iEid})
    end
end

function CScene:RemoveSceneNpc(npcid)
    local iEid = self.m_mNpc[npcid]
    assert(iEid,string.format("RemoveSceneNpc npcid err:%d",npcid))
    self.m_mNpc[npcid] = nil
    interactive.Send(self.m_iRemoteAddr,"scene","RemoveSceneNpc",{scene_id = self.m_iSceneId,eid=iEid})
end

function CScene:CreateSceneTeam(oPlayer)
    local iEid = self:DispatchEntityId()
    local iTeamID = oPlayer:TeamID()
    local iTeamType = oPlayer:TeamType()
    local mMem = oPlayer:SceneTeamMember()
    local mShort = oPlayer:SceneTeamShort()
    interactive.Send(self.m_iRemoteAddr,"scene","CreateSceneTeam",{
        scene_id = self.m_iSceneId, team_id = iTeamID, eid = iEid, team_type = iTeamType,
        mem = mMem, short = mShort
    })
end

function CScene:RemoveSceneTeam(oPlayer, iTeamId)
    interactive.Send(self.m_iRemoteAddr,"scene","RemoveSceneTeam",{scene_id = self.m_iSceneId,team_id = iTeamId})
end

function CScene:SyncSceneTeam(oPlayer)
    local iTeamID = oPlayer:TeamID()
    if not iTeamID then
        return
    end
    local mMem = oPlayer:SceneTeamMember()
    local mShort = oPlayer:SceneTeamShort()
    local iTeamType = oPlayer:TeamType()

    interactive.Send(self.m_iRemoteAddr,"scene","UpdateSceneTeam",{
        scene_id = self.m_iSceneId,team_id = iTeamID,team_type = iTeamType,
        mem = mMem, short = mShort
    })
end

function CScene:IsVirtual()
    if self:IsDurable() then
        return false
    end
    return true
end

function CScene:SetLeaveCallBack(fFunc)
    self.m_fLeaveCallBack = fFunc
end

function CScene:SetClickTaskFunc(fFunc)
    self.m_fClickTaskFunc = fFunc
end

function CScene:IsTrapmine(oPlayer)
    if self.m_oAnLeiCtrl then
        self.m_oAnLeiCtrl:IsTrapmine(oPlayer)
    end
    return false
end

CAnLeiCtrl = {}
CAnLeiCtrl.__index = CAnLeiCtrl
inherit(CAnLeiCtrl, logic_base_cls())

function CAnLeiCtrl:New(iScene)
    local o = super(CAnLeiCtrl).New(self)
    o.m_iSceneId = iScene
    o.m_mPlayerInfo = {}
    return o
end

function CAnLeiCtrl:Update(iPid, mPosInfo, mExtra)
    -- mExtra = mExtra or {}
    -- local iTime = get_time()
    -- local m = self.m_mPlayerInfo[iPid]
    -- if m then
    --     if m.x ~= mPosInfo.x or m.y ~= mPosInfo.y then
    --         m.x = mPosInfo.x
    --         m.y = mPosInfo.y
    --         m.time = iTime
    --     end
    -- end
end

function CAnLeiCtrl:UpdateTriggerTime(iPid, iTriggerTime)
    local m = self.m_mPlayerInfo[iPid]
    if m and iTriggerTime  then
        m.trigger_time = iTriggerTime
    end
end

function CAnLeiCtrl:Add(iPid, mPosInfo)
    local iTime = get_time()
    self.m_mPlayerInfo[iPid] = {x = mPosInfo.x, y = mPosInfo.y, time = iTime, trigger_time = 0}
    local oHuodongMgr = global.oHuodongMgr
    local oTrapMine = oHuodongMgr:GetHuodong("trapmine")
    local oSceneMgr = global.oSceneMgr
    local oScene = oSceneMgr:GetScene(self.m_iSceneId)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oTrapMine and oScene and oPlayer then
        oTrapMine:EnterScene(oPlayer, oScene:MapId())
    end
end

function CAnLeiCtrl:Start(iPid)
    local iTime = get_time()
    local m = self.m_mPlayerInfo[iPid]
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer and (oPlayer:IsSingle() or oPlayer:IsTeamLeader()) then
        if m and m.trigger_time > iTime then
            local sFlag = string.format("CheckTriggerAnLei%d", iPid)
            self:DelTimeCb(sFlag)
            self:AddTimeCb(sFlag, (m.trigger_time - iTime) * 1000, function()
                self:TriggerAnLei(oPlayer)
            end)
        end
    end
end

function CAnLeiCtrl:Stop(iPid)
    local m = self.m_mPlayerInfo[iPid]
    if m then
        m.trapmine = false
        local sFlag = string.format("CheckTriggerAnLei%d", iPid)
        self:DelTimeCb(sFlag)
    end
end

function CAnLeiCtrl:Del(iPid)
    self.m_mPlayerInfo[iPid] = nil
    local sFlag = string.format("CheckTriggerAnLei%d", iPid)
    self:DelTimeCb(sFlag)
    local oTrapMine = global.oHuodongMgr:GetHuodong("trapmine")
    local oScene = global.oSceneMgr:GetScene(self.m_iSceneId)
    local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oTrapMine and oScene and oPlayer then
        oTrapMine:LeaveScene(oPlayer, oScene:MapId())
    end
end

function CAnLeiCtrl:CheckTriggerAnLei(iPid)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    local iTime = get_time()
    if oPlayer and (oPlayer:IsSingle() or oPlayer:IsTeamLeader()) then
        local m = self.m_mPlayerInfo[iPid]
        if m and (iTime - m.time <= 8) then
            local iRan = 50
            if m.no_trigger_cnt >=1 then
                iRan = 100
            end
            if math.random(1, 100) <= iRan then
                m.no_trigger_cnt = 0
                self:TriggerAnLei(oPlayer)
            else
                m.no_trigger_cnt = m.no_trigger_cnt + 1
            end
        end
    end
end

function CAnLeiCtrl:TriggerAnLei(oPlayer)
    local oHuodongMgr = global.oHuodongMgr
    local oTrapMine = oHuodongMgr:GetHuodong("trapmine")
    local oSceneMgr = global.oSceneMgr
    local oScene = oSceneMgr:GetScene(self.m_iSceneId)
    if oTrapMine and oScene then
        oTrapMine:Trigger(oPlayer, oScene:MapId())
    end
end
