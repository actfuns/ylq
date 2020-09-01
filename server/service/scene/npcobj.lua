local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local geometry = require "base.geometry"
local playersend = require "base.playersend"

local gamedefines = import(lualib_path("public.gamedefines"))
local CEntity = import(service_path("entityobj")).CEntity

function NewNpcEntity(...)
    return CNpcEntity:New(...)
end


BlockHelperFunc = {}

function BlockHelperFunc.name(oEntity)
    return oEntity:GetName()
end

function BlockHelperFunc.model_info(oEntity)
    return oEntity:GetModelInfo()
end

function BlockHelperFunc.war_tag(oEntity)
    return oEntity:GetWarTag()
end

function BlockHelperFunc.orgid(oEntity)
    return oEntity:GetOrgId()
end

function BlockHelperFunc.orgflag(oEntity)
    return oEntity:GetOrgFlag()
end

function BlockHelperFunc.owner(oEntity)
    return oEntity:GetOwner()
end

function BlockHelperFunc.ownerid(oEntity)
    return oEntity:GetOwnerId()
end

function BlockHelperFunc.trapmine(oEntity)
    return oEntity:GetTrapmine()
end

CNpcEntity = {}
CNpcEntity.__index = CNpcEntity
inherit(CNpcEntity, CEntity)

function CNpcEntity:New(iEid)
    local o = super(CNpcEntity).New(self, iEid)
    o.m_iType = gamedefines.SCENE_ENTITY_TYPE.NPC_TYPE
    return o
end

function CNpcEntity:MonsterFlag()
    if self:GetData("monster_flag") then
        return true
    end
    return false
end

function CNpcEntity:EnterWar()
    self:SetData("war_tag",1)
    self:BlockChange("war_tag")
end

function CNpcEntity:LeaveWar()
    self:SetData("war_tag",0)
    self:BlockChange("war_tag")
end

function CNpcEntity:GetTrapmine()
    return self:GetData("trapmine", {})
end

function CNpcEntity:GetAoiInfo()
    local mPos = self:GetPos()
    local m = {
        npctype = self:GetData("npctype"),
        npcid = self:GetData("npcid"),
        mode = self:GetData("mode"),
        titlename = self:GetData("title"),
        pos_info = {
            x = geometry.Cover(mPos.x),
            y = geometry.Cover(mPos.y),
            face_x = geometry.Cover(mPos.face_x),
            face_y = geometry.Cover(mPos.face_y),
        },
        block = self:BlockInfo(),
        orgid = self:GetOrgId(),
        orgflag = self:GetOrgFlag(),
        owner = self:GetOwner(),
        ownerid = self:GetOwnerId(),
    }
    return m
end

function CNpcEntity:BlockInfo(m)
    local mRet = {}
    if not m then
        m = BlockHelperFunc
    end
    for k, _ in pairs(m) do
        local f = assert(BlockHelperFunc[k], string.format("BlockInfo fail f get %s", k))
        mRet[k] = f(self)
    end
    return net.Mask("base.NpcAoiBlock", mRet)
end

function CNpcEntity:BlockChange(...)
    local l = table.pack(...)
    self:SetAoiChange(l)
end

function CNpcEntity:ClientBlockChange(m)
    local mBlock = self:BlockInfo(m)
    self:SendAoi("GS2CSyncAoi", {
        scene_id = self:GetSceneId(),
        eid = self:GetEid(),
        type = self:Type(),
        aoi_npc_block = mBlock,
    })
end

function CNpcEntity:SyncInfo(mArgs)
    if mArgs.name then
        self:SetData("name", mArgs.name)
        self:BlockChange("name")
    end
    if mArgs.model_info then
        self:SetData("model_info", mArgs.model_info)
        self:BlockChange("model_info")
    end
    if mArgs.owner then
        self:SetData("owner",mArgs.owner)
        self:BlockChange("owner")
    end
    if mArgs.orgid then
        self:SetData("orgid",mArgs.orgid)
        self:BlockChange("orgid")
    end
    if mArgs.orgflag then
        self:SetData("orgflag",mArgs.orgflag)
        self:BlockChange("orgflag")
    end
    if mArgs.ownerid then
        self:SetData("ownerid",mArgs.ownerid)
        self:BlockChange("ownerid")
    end
end

function CNpcEntity:GetBlockInfo()
    local mPos = self:GetPos()
    local m = {
        npctype = self:GetData("npctype"),
        npcid = self:GetData("npcid"),
        mode = self:GetData("mode"),
        titlename = self:GetData("title"),
        block = self:BlockInfo(),
        orgid = self:GetOrgId(),
        orgflag = self:GetOrgFlag(),
        owner = self:GetOwner(),
        ownerid = self:GetOwnerId(),
    }
    return m
end

function CNpcEntity:PackAoiBlock()
    return playersend.PackData("GS2CEnterAoiBlock",{
            scene_id = self:GetSceneId(),
            eid = self:GetEid(),
            type = self:Type(),
            aoi_npc = self:GetBlockInfo(),
        })
end