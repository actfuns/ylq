--import module

local global = require "global"
local skynet = require "skynet"
local playersend = require "base.playersend"
local geometry = require "base.geometry"
local interactive = require "base.interactive"
local res = require "base.res"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local aoi = import(service_path("aoi.wrapper"))
local playerobj = import(service_path("playerobj"))
local npcobj = import(service_path("npcobj"))
local teamobj = import(service_path("teamobj"))

function NewScene(...)
    local o = CScene:New(...)
    return o
end

CScene = {}
CScene.__index = CScene
inherit(CScene, logic_base_cls())

function CScene:New(id,iMapid)
    local o = super(CScene).New(self)
    o.m_iScene = id
    o.m_iMapId = iMapid

    local mMapInfo = res["daobiao"]["map"][iMapid]
    local iMaxX, iMaxY
    if mMapInfo then
        local lServerScope = mMapInfo["server_scope"]
        iMaxX, iMaxY = lServerScope[1], lServerScope[2]
        if not iMaxX or not iMaxY then
            iMaxX, iMaxY = iMaxX or 10, iMaxY or 10
            record.warning("CScene New failed1 map, mapid:%s", iMapid)
        end
    else
        iMaxX, iMaxY = 10, 10
        record.warning("CScene New failed2 map, mapid:%s", iMapid)
    end

    o.m_oAoi = aoi.NewAoiMgr({
        max_x = iMaxX,
        max_y = iMaxY,
        grid_x = gamedefines.SCENE_GRID_DIS_X,
        grid_y = gamedefines.SCENE_GRID_DIS_Y,
        map_id = iMapid,
    })

    o.m_mEntitys = {}
    o.m_mTeamEntitys = {}
    o.m_mPlayers = {}

    --team
    o.m_mTeams = {}
    o.m_mPid2Team = {}

    return o
end

function CScene:Release()
    for _, v in pairs(self.m_mEntitys) do
        baseobj_safe_release(v)
    end
    self.m_mEntitys = {}
    for _, v in pairs(self.m_mTeamEntitys) do
        baseobj_safe_release(v)
    end
    self.m_mTeamEntitys = {}
    super(CScene).Release(self)
end

function CScene:Init(mInit)
end

function CScene:AoiGetView(iEid, iType)
    local m = self.m_oAoi:GetView(iEid, iType)
    if m.errcode == 0 then
        return m.result
    end
    return {}
end

function CScene:AoiAction(sFunc, iEid, ...)
    local oView = self:GetEntity(iEid)
    if not oView then
        return
    end

    local mRet = self.m_oAoi[sFunc](self.m_oAoi, iEid, ...)
    if mRet.errcode == 0 then
        for _, k in ipairs(mRet.events.enter) do
            if k == 0 then
                oView = nil
            elseif not oView then
               oView = self:GetEntity(k)
            else
                local o = self:GetEntity(k)
                if o then
                    oView:EnterAoi(o)
                    o:EnterAoi(oView)
                end
            end
        end
        for _, k in ipairs(mRet.events.leave) do
            if k == 0 then
                oView = nil
            elseif not oView then
               oView = self:GetEntity(k)
            else
                local o = self:GetEntity(k)
                if o then
                    oView:LeaveAoi(o)
                    o:LeaveAoi(oView)
                end
            end
        end
    end
end

function CScene:GetSceneId()
    return self.m_iScene
end

function CScene:GetMapId()
    return self.m_iMapId
end

function CScene:GetEntity(id)
    return self.m_mEntitys[id] or self.m_mTeamEntitys[id]
end

function CScene:SetTeamEntity(id,obj)
    if self.m_mTeamEntitys[id] then
        self:ClearTeamEntity(id)
    end
    self.m_mTeamEntitys[id] = obj
end

function CScene:ClearTeamEntity(id)
    local obj = self.m_mTeamEntitys[id]
    if obj then
        baseobj_delay_release(obj)
    end
    self.m_mTeamEntitys[id] = nil
end

function CScene:GetPlayerEntity(iPid)
    local id = self.m_mPlayers[iPid]
    if id then
        return self.m_mEntitys[id]
    end
end

function CScene:GetAllPlayers()
    return table_key_list(self.m_mPlayers)
end

function CScene:Enter(obj)
    local iEid = obj:GetEid()

    self.m_mEntitys[iEid] = obj

    local iWeight
    local iType
    local iAcType
    local iLimit

    if obj:IsPlayer() then
        iWeight = 1
        iType = 1
        iLimit = gamedefines.SCENE_PLAYER_SEE_LIMIT
    elseif obj:IsNpc() then
        if obj:MonsterFlag() then
            iWeight = 1
            iType = 3
            iLimit = 0
        else
            iWeight = 0
            iType = 2
            iLimit = 0
        end
    else
        assert(false)
    end
    iAcType = obj:Type()

    local mPos = obj:GetPos()
    self:AoiAction("CreateObject", iEid, {
        x = mPos.x,
        y = mPos.y,
        type = iType,
        ac_type = iAcType,
        weight = iWeight,
        limit = iLimit,
    })

    return obj
end

function CScene:Leave(obj)
    local iEid = obj:GetEid()

    self:AoiAction("RemoveObject", iEid)
    self.m_mEntitys[iEid] = nil

    baseobj_delay_release(obj)
end

function CScene:EnterPlayer(iPid, iEid, mPos, mInfo)
    assert(not self.m_mPlayers[iPid], string.format("EnterPlayer error %d %d", iPid, iEid))
    local obj = playerobj.NewPlayerEntity(iEid, iPid)
    self.m_mPlayers[iPid] = iEid
    obj:Init({
        scene_id = self:GetSceneId(),
        pos = mPos,
        speed = 0,
        data = mInfo,
    })

    obj:Send("GS2CEnterScene", {
        scene_id = self:GetSceneId(),
        eid = obj:GetEid(),
        pos_info = {
            x = geometry.Cover(mPos.x),
            y = geometry.Cover(mPos.y),
            face_x = geometry.Cover(mPos.face_x or 0),
            face_y = geometry.Cover(mPos.face_y or 0),
        }
    })
    obj:UpdateShareData(mPos)
    interactive.Send(".world", "scene", "RemoteEvent", {event = "player_enter_scene", data = {
        pid = iPid,
        scene_id = self:GetSceneId(),
        scene_player_share = obj:GetScenePlayerReaderCopy(),
    }})

    return self:Enter(obj)
end

function CScene:LeavePlayer(iPid)
    local eid = self.m_mPlayers[iPid]
    local obj = self:GetEntity(eid)
    if obj then
        self:Leave(obj)
        self.m_mPlayers[iPid] = nil
    end
    interactive.Send(".world", "scene", "RemoteEvent", {event = "player_leave_scene", data = {
        pid = iPid,
        scene_id = self:GetSceneId(),
        eid = eid,
    }})
end

function CScene:ReEnterPlayer(iPid)
    local oEntity = self:GetPlayerEntity(iPid)
    assert(oEntity, string.format("ReEnterPlayer error %d", iPid))
    oEntity:ReEnter()
end

function CScene:EnterNpc(iEid,mPos,mInfo)
    local obj = npcobj.NewNpcEntity(iEid)
    obj:Init({
        scene_id = self:GetSceneId(),
        pos = mPos,
        speed = 0,
        data = mInfo,
    })
    return self:Enter(obj)
end

function CScene:RemoveSceneNpc(iEid)
    local oNpcEntity = self:GetEntity(iEid)
    if oNpcEntity then
        assert(oNpcEntity:IsNpc(), string.format("RemoveSceneNpc err :%d",iEid))
        self:Leave(oNpcEntity)
    	interactive.Send(".world", "scene", "RemoteEvent", {event = "npc_leave_scene", data = {
        	scene_id = self:GetSceneId(),
        	eid = iEid,
    	}})
    end
end

function CScene:CreateSceneTeam(iEid, iTeam,iTeamType, mMem, mShort)
    --assert(not self.m_mTeams[iTeam], string.format("CreateSceneTeam failed eid:%s teamid:%s",
    --    iEid, iTeam))
    if self.m_mTeams[iTeam] then
        return
    end

    local obj = teamobj.NewTeamEntity(iEid, iTeam, iTeamType, mMem, mShort)

    local iLeaderPid
    for k, v in pairs(mMem) do
        if v == 1 then
            iLeaderPid = k
            break
        end
    end
    local oLeader = self:GetPlayerEntity(iLeaderPid)
    local mLeaderPos = oLeader:GetPos()
    local fLeaderSpeed = oLeader:GetSpeed()

    obj:Init({
        scene_id = self:GetSceneId(),
        pos = mLeaderPos,
        speed = fLeaderSpeed,
    })

    self.m_mTeams[iTeam] = iEid
    self:SetTeamEntity(iEid,obj)
    for k, _ in pairs(mMem) do
        self.m_mPid2Team[k] = iTeam
    end

    for k, _ in pairs(obj:GetTeamMember()) do
        local oMem = self:GetPlayerEntity(k)
        if oMem then
            oMem:SetPos({
                x = mLeaderPos.x,
                y = mLeaderPos.y,
                face_x = mLeaderPos.face_x,
                face_y = mLeaderPos.face_y,
            })
            oMem:SetSpeed(fLeaderSpeed)
        end
    end

    oLeader:SendAoi("GS2CSceneCreateTeam", {
        scene_id = obj:GetSceneId(),
        team_id = obj:GetTeamId(),
        team_type = obj:GetTeamType(),
        pid_list = obj:GetTeamSortMember(),
    },true)

    local mMemEid = {}
    local mShortEid = {}
    for k, iPos in pairs(mMem) do
        local oMem = self:GetPlayerEntity(k)
        if oMem then
            mMemEid[oMem:GetEid()] = iPos
        end
    end

    for k, iPos in pairs(mShort) do
        local oMem = self:GetPlayerEntity(k)
        if oMem then
            mShortEid[oMem:GetEid()] = iPos
        end
    end

    self:AoiAction("CreateSceneTeam", iEid, {
        mem = mMemEid,
        short = mShortEid,
    })

end

function CScene:RemoveSceneTeam(iTeam)
    --assert(self.m_mTeams[iTeam], string.format("RemoveSceneTeam failed teamid:%s", iTeam))
    if not self.m_mTeams[iTeam] then
        return
    end

    local iEid = self.m_mTeams[iTeam]
    local obj = self:GetEntity(iEid)
    if obj then
        local oLeader = obj:GetTeamLeader()
        if oLeader then
            oLeader:SendAoi("GS2CSceneRemoveTeam", {
                scene_id = obj:GetSceneId(),
                team_id = obj:GetTeamId(),
            },true)
        end
        self:AoiAction("RemoveSceneTeam", iEid, {})
        self:ClearTeamEntity(iEid)
        for k, _ in pairs(obj:GetTeamMember()) do
            self.m_mPid2Team[k] = nil
        end
        self.m_mTeams[iTeam] = nil
        interactive.Send(".world", "scene", "RemoteEvent", {event = "team_leave_scene", data = {
            scene_id = self:GetSceneId(),
            eid = iEid,
        }})
    end
end

function CScene:UpdateSceneTeam(iTeam, iTeamType,mMem,mShort)
    --assert(self.m_mTeams[iTeam], string.format("UpdateSceneTeam failed teamid:%s", iTeam))
    if not self.m_mTeams[iTeam] then
        return
    end

    local iEid = self.m_mTeams[iTeam]
    local oTeamEntity = self:GetEntity(iEid)
    if oTeamEntity then
        local mOldData = oTeamEntity:GetTeamMember()
        --add
        local mAdd = {}
        for k, _ in pairs(mMem) do
            if not mOldData[k] then
                mAdd[k] = 1
                self.m_mPid2Team[k] = iTeam
            end
        end
        --del
        for k, _ in pairs(mOldData) do
            if not mMem[k] then
                self.m_mPid2Team[k] = nil
            end
        end

        oTeamEntity:SetTeamMember(mMem)
        oTeamEntity:SetTeamShort(mShort)

        local iLeaderPid = oTeamEntity:GetLeaderPid()
        local oLeader = self:GetPlayerEntity(iLeaderPid)
        local mLeaderPos = oLeader:GetPos()
        local fLeaderSpeed = oLeader:GetSpeed()

        for k, _ in pairs(mAdd) do
            local oMe = self:GetPlayerEntity(k)
            if oMe then
                oMe:SetPos({
                    x = mLeaderPos.x,
                    y = mLeaderPos.y,
                    face_x = mLeaderPos.face_x,
                    face_y = mLeaderPos.face_y,
                })
                oMe:SetSpeed(fLeaderSpeed)
            end
        end

        oLeader:SendAoi("GS2CSceneUpdateTeam", {
            scene_id = self:GetSceneId(),
            team_id = oTeamEntity:GetTeamId(),
            pid_list = oTeamEntity:GetTeamSortMember(),
            team_type = oTeamEntity:GetTeamType(),
        }, true)

        local mMemEid = {}
        local mShortEid = {}
        for k, iPos in pairs(mMem) do
            local oMem = self:GetPlayerEntity(k)
            if oMem then
                mMemEid[oMem:GetEid()] = iPos
            end
        end

        for k, iPos in pairs(mShort) do
            local oMem = self:GetPlayerEntity(k)
            if oMem then
                mShortEid[oMem:GetEid()] = iPos
            end
        end

        self:AoiAction("UpdateSceneTeam", iEid, {
            mem = mMemEid,
            short = mShortEid,
        })
    end
end

function CScene:GetTeamByPid(iPid)
    local iTeam = self.m_mPid2Team[iPid]
    if iTeam then
        local iEid = self.m_mTeams[iTeam]
        if iEid then
            return self:GetEntity(iEid)
        end
    end
end

function CScene:GetTeamByTeamId(iTeam)
    local iEid = self.m_mTeams[iTeam]
    if iEid then
        return self:GetEntity(iEid)
    end
end

function CScene:BroadCast(sMessage, mData)
    local sData = playersend.PackData(sMessage, mData)
    for iPid, _ in pairs(self.m_mPlayers) do
        local oPlayerEntity = self:GetPlayerEntity(iPid)
        if oPlayerEntity then
            oPlayerEntity:SendRaw(sData)
        end
    end
end
