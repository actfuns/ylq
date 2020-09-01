--import module
local global = require "global"
local geometry = require "base.geometry"
local record = require "public.record"

local npcobj = import(service_path("npc/npcobj"))

CClientNpc = {}
CClientNpc.__index = CClientNpc
inherit(CClientNpc,npcobj.CNpc)

function CClientNpc:New(mArgs)
    local o = super(CClientNpc).New(self)
    o:Init(mArgs)
    return o
end

function CClientNpc:Init(mArgs)
    local mArgs = mArgs or {}
    self.m_sSysName = mArgs["sys_name"]
    self.m_iType = mArgs["type"]
    self.m_iMapid = mArgs["map_id"] or 0
    self.m_mModel = mArgs["model_info"] or {}
    self.m_mPosInfo = mArgs["pos_info"] or {}
    self.m_iEvent = mArgs["event"] or 0
    self.m_iReUse = mArgs["reuse"]
    self.m_iDialog = mArgs["dialogId"]
end

function CClientNpc:Save()
    local data = {}
    data["type"] = self.m_iType

    data["map_id"] = self.m_iMapid
    data["model_info"] = self.m_mModel
    data["pos_info"] = self.m_mPosInfo
    data["reuse"]  = self.m_iReUse
    data["event"] = self.m_iEvent
    data["dialogId"] = self.m_iDialog
    return data
end

function CClientNpc:PackInfo()
    local mData = {
            npctype = self.m_iType,
            npcid      = self.m_ID,
            name = self:GetName(),
            title = self:GetTitle(),
            map_id = self.m_iMapid,
            pos_info = self:GetPos(),
            model_info = self.m_mModel,
    }
    return mData
end

function CClientNpc:SetEvent(iEvent)
    self.m_iEvent = iEvent
end

function CClientNpc:GetPos()
    local mPos = self.m_mPosInfo
    if not mPos then
        record.warning(string.format("not self.m_mPosInfo:Type %d",self.m_iType))
    end
    local pos_info = {
            x = math.floor(geometry.Cover(mPos.x)),
            y = math.floor(geometry.Cover(mPos.y)),
            z = math.floor(geometry.Cover(mPos.z)),
            face_x = math.floor(geometry.Cover(mPos.face_x)),
            face_y = math.floor(geometry.Cover(mPos.face_y)),
            face_z = math.floor(geometry.Cover(mPos.face_z)),
        }
     return pos_info
end

function CClientNpc:GetText()
    local res = require "base.res"
    local iDialog = self.m_iDialog
    local mDialog = res["daobiao"]["task_npc"][iDialog]
    assert(mDialog,string.format("miss config of dialogId:%d  sys_name:%s",iDialog,self.m_sSysName))
    local iNo = math.random(3)
    local sKey = string.format("dialogContent%d",iNo)
    local sDialog = mDialog[sKey]
    return sDialog
end

function CClientNpc:GetNpcData()
    local res = require"base.res"
    if not self.m_sSysName then
        record.warning(string.format("not self.m_sSysName:Type %d",self.m_iType))
    end
    local mData = res["daobiao"]["task"][self.m_sSysName] or {}
    return mData["tasknpc"][self.m_iType]
end

function CClientNpc:Name()
    return self:GetName()
end

function CClientNpc:GetName()
    local mNpcInfo = self:GetNpcData()
    return mNpcInfo["name"]
end

function CClientNpc:GetTitle()
    local mNpcInfo=self:GetNpcData()
    return mNpcInfo["title"]
end

function NewClientNpc(mArgs)
    local o = CClientNpc:New(mArgs)
    return o
end