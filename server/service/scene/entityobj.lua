--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local playersend = require "base.playersend"
local geometry = require "base.geometry"

local gamedefines = import(lualib_path("public.gamedefines"))


CEntity = {}
CEntity.__index = CEntity
inherit(CEntity, logic_base_cls())

function CEntity:New(iEid)
    local o = super(CEntity).New(self)
    o.m_iType = gamedefines.SCENE_ENTITY_TYPE.ENTITY_TYPE
    o.m_iEid = iEid
    o.m_iScene = nil
    o.m_mPos = nil
    o.m_mData = nil
    o.m_fSpeed = 0
    o.m_iSceneMarkerModel = 0

    o.m_mAoiChange = {}
    o.m_bCollectAoiChange = false

    return o
end

function CEntity:Type()
    return self.m_iType
end

function CEntity:IsPlayer()
    return self:Type() == gamedefines.SCENE_ENTITY_TYPE.PLAYER_TYPE
end

function CEntity:IsNpc()
    return self:Type() == gamedefines.SCENE_ENTITY_TYPE.NPC_TYPE
end

function CEntity:IsTeam()
    return self:Type() == gamedefines.SCENE_ENTITY_TYPE.TEAM_TYPE
end

function CEntity:Init(mInit)
    self.m_iScene = mInit.scene_id

    local mPos = mInit.pos
    local m = {}
    m.x = mPos.x or 0
    m.y = mPos.y or 0
    m.face_x = mPos.face_x or 0
    m.face_y = mPos.face_y or 0
    self.m_mPos = m

    self.m_fSpeed = mInit.speed
    self.m_mData = mInit.data or {}
    self.m_iSceneMarkerModel = self.m_mData["scene_model"] or 1
end

function CEntity:SetData(k, v)
    self.m_mData[k] = v
end

function CEntity:GetData(k, rDefault)
    return self.m_mData[k] or rDefault
end

function CEntity:SetAoiChange(l)
    self:SetAoiBlockChange(true)
    for _, k in ipairs(l) do
        self.m_mAoiChange[k] = true
    end
    if not self.m_bCollectAoiChange then
        self.m_bCollectAoiChange = true
        local iSceneId = self:GetSceneId()
        local iEid = self:GetEid()
        self:AddTimeCb("PopAoiChange", 200, function ()
            local oSceneMgr = global.oSceneMgr
            local oScene = oSceneMgr:GetScene(iSceneId)
            if oScene then
                local oEntity = oScene:GetEntity(iEid)
                if oEntity then
                    safe_call(oEntity.ClientBlockChange, oEntity, oEntity.m_mAoiChange)
                    oEntity:ClrAoiChange()
                    oEntity.m_bCollectAoiChange = false
                end
            end
        end)
    end
end

function CEntity:ClrAoiChange()
    for k, _ in pairs(self.m_mAoiChange) do
        self.m_mAoiChange[k] = nil
    end
end

function CEntity:GetView(iType)
    local oScene = self:GetScene()
    return oScene:AoiGetView(self:GetEid(), iType)
end

function CEntity:GetEid()
    return self.m_iEid
end

function CEntity:GetSceneId()
    return self.m_iScene
end

function CEntity:SetSpeed(fSpeed)
    self.m_fSpeed = fSpeed
end

function CEntity:SetPos(mPos)
    local m = self.m_mPos
    m.x = mPos.x or 0
    m.y = mPos.y or 0
    m.face_x = mPos.face_x or 0
    m.face_y = mPos.face_y or 0
    self:OnSetPos(m.x, m.y)
    self:SetAoiPosChange(true)
end

function CEntity:OnSetPos(x, y)
    local bFlag = false
    if not self:IsPlayer() then
        bFlag = true
    elseif self:IsPlayer() and self:IsLeader() then
        bFlag = true
    elseif self:IsPlayer() and not self:GetTeam() then
        bFlag = true
    end

    if bFlag then
        local oScene = self:GetScene()
        oScene:AoiAction("UpdateObjectPos", self:GetEid(), {
            x = x,
            y = y,
        })
    end
end

function CEntity:GetName()
    return self:GetData("name")
end

function CEntity:GetModelInfo()
    return self:GetData("model_info")
end

function CEntity:GetScene()
    local oSceneMgr = global.oSceneMgr
    return oSceneMgr:GetScene(self:GetSceneId())
end

function CEntity:GetEntity(iEid)
    local oScene = self:GetScene()
    return oScene:GetEntity(iEid)
end

function CEntity:GetPos()
    return self.m_mPos
end

function CEntity:GetSpeed()
    return self.m_fSpeed
end

function CEntity:GetOrgId()
    return self:GetData("orgid")
end

function CEntity:GetOrgFlag()
    return self:GetData("orgflag")
end

function CEntity:GetOwner()
    return self:GetData("owner")
end

function CEntity:GetOwnerId()
    return self:GetData("ownerid")
end

function CEntity:EnterAoi(oMarker)
end

function CEntity:LeaveAoi(oMarker)
end

function CEntity:OnEnterAoi(oMarker)
end

function CEntity:OnLeaveAoi(oMarker)
end

function CEntity:OnClientEnter(iType, id)
end

function CEntity:OnClientLeave(iType, id)
end

function CEntity:SetSceneMarkerModel(iScenModel)
    self.m_iSceneMarkerModel = iScenModel
end

function CEntity:Send(sMessage, mData)
end

function CEntity:SendRaw(sData)
end

function CEntity:GetAoi(bInclude)
    local oScene = self:GetScene()
    local lSendObjects = {}

    for _, k in ipairs(self:GetView(gamedefines.SCENE_ENTITY_TYPE.PLAYER_TYPE)) do
        local o = oScene:GetEntity(k)
        if o then
            table.insert(lSendObjects, o)
        end
    end

    if bInclude then
        table.insert(lSendObjects, self)
    end
    return lSendObjects
end

function CEntity:SendAoi(sMessage, mData, bInclude)
    local sData = playersend.PackData(sMessage,mData)
    local lSendObjects = self:GetAoi(bInclude)
    for _, o in ipairs(lSendObjects) do
        o:SendRaw(sData)
    end
end

function CEntity:BlockInfo(m)
end

function CEntity:BlockChange(...)
end

function CEntity:ClientBlockChange(m)
end

function CEntity:GetWarTag()
    return self:GetData("war_tag",0)
end

function CEntity:InWar()
	return self:GetWarTag() ~= 0
end

function CEntity:PackAoiBlock()
end

function CEntity:GetLeaveAoiInfoPack()
    if self.m_sLeaveAoiPack then
        return self.m_sLeaveAoiPack
    end
    self.m_sLeaveAoiPack = playersend.PackData("GS2CLeaveAoi",{
            scene_id = self:GetSceneId(),
            eid = self:GetEid(),
    })
    return self.m_sLeaveAoiPack
end

function CEntity:GetEnterAoiBlockPack()
    if not self.m_sAoiBlockPack then
       self.m_sAoiBlockPack = self:PackAoiBlock()
    end
    if self:IsAoiBlockChange() then
        self.m_sAoiBlockPack = self:PackAoiBlock()
        self:SetAoiBlockChange(false)
    end
    return self.m_sAoiBlockPack
end

function CEntity:IsAoiBlockChange()
    return self.m_bAoiBlockChange
end

function CEntity:SetAoiBlockChange(bValue)
    self.m_bAoiBlockChange = bValue
end

function CEntity:PackAoiPos()
    local mPos = self:GetPos()
    return playersend.PackData("GS2CEnterAoiPos",{
            scene_id = self:GetSceneId(),
            eid = self:GetEid(),
            type = self:Type(),
            pos_info = {
                x = geometry.Cover(mPos.x),
                y = geometry.Cover(mPos.y),
                face_x = geometry.Cover(mPos.face_x),
                face_y = geometry.Cover(mPos.face_y),
            },
    })
end

function CEntity:GetEnterAoiPosPack()
    if not self.m_sAoiPosPack then
       self.m_sAoiPosPack = self:PackAoiPos()
    end
    if self:IsAoiPosChange() then
        self.m_sAoiPosPack = self:PackAoiPos()
        self:SetAoiPosChange(false)
    end
    return self.m_sAoiPosPack
end

function CEntity:IsAoiPosChange()
    return self.m_bAoiPosChange
end

function CEntity:SetAoiPosChange(bValue)
    self.m_bAoiPosChange = bValue
end