--import module
local global = require "global"
local geometry = require "base.geometry"

local datactrl = import(lualib_path("public.datactrl"))

function NewClientNpc(mArgs)
    local o = CClientNpc:New(mArgs)
    return o
end



CClientNpc = {}
CClientNpc.__index = CClientNpc
inherit(CClientNpc,datactrl.CDataCtrl)

function CClientNpc:New(mArgs)
    local o = super(CClientNpc).New(self)
    o.m_iType = mArgs.type
    o:Init(mArgs)
    return o
end

function CClientNpc:Init(mArgs)
    mArgs = mArgs or {}
    self.m_iOwner = mArgs["owner"]
    self.m_iMapid = mArgs["map_id"]
    self.m_mPosInfo = mArgs["pos_info"] or {}
    self.m_iCreateTime = mArgs["createtime"] or get_time()
    self.m_iEndTime = mArgs["endtime"] or (get_time() + (30 * 60))
    self.m_iBossType = mArgs["boss_type"]
    self.m_iTrapMine = 1

    local mNpcData =self:GetData()
    local mModel = {
        shape = mNpcData["modelId"],
        scale = mNpcData["scale"],
        adorn = mNpcData["ornamentId"],
        weapon = mNpcData["wpmodel"],
        color = mNpcData["mutateColor"],
        mutate_texture = mNpcData["mutateTexture"],
    }
    self.m_mModel = mModel
    self:StartTimer()
end

function CClientNpc:InitObject()
    local oNpcMgr = global.oNpcMgr
    local iDispatchId = oNpcMgr:DispatchId()
    self.m_ID = iDispatchId
end

function CClientNpc:Release()
    self:DelTimeCb("TimeOut")
    super(CClientNpc).Release(self)
end

function CClientNpc:StartTimer()
    if self.m_iEndTime <= get_time() then
        self:TimeOut()
        return
    end
    local iNPC = self:ID()
    local iPid = self.m_iOwner
    self:DelTimeCb("TimeOut")
    self:AddTimeCb("TimeOut", (self.m_iEndTime - get_time()) * 1000, function()
        local oPlayer = global.oWorldMgr:GetOnlinePlayerByPid(iPid)
        if oPlayer then
            local oNPC = oPlayer.m_oHuodongCtrl:GetNpcByID("trapmine", iNPC)
            if oNPC then
                oNPC:TimeOut()
            end
        end
    end)
end

function CClientNpc:TimeOut()
    self:DelTimeCb("TimeOut")
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(self.m_iOwner)
    if oPlayer then
        oPlayer.m_oHuodongCtrl:RemoveClientNpc("trapmine",self.m_ID)
    end
end

function CClientNpc:CheckTimeOut()
    if self.m_iEndTime <= get_time() then
        return true
    end
    return false
end

function CClientNpc:Save()
    local data = {}
    data["type"] = self:Type()
    data["map_id"] = self.m_iMapid
    data["pos_info"] = self.m_mPosInfo
    data["createtime"] = self.m_iCreateTime
    data["endtime"] = self.m_iEndTime
    data["boss_type"] = self.m_iBossType
    data["owner"] = self.m_iOwner
    return data
end

function CClientNpc:CountDown()
end

function CClientNpc:GetData()
    local res = require "base.res"
    local mData = res["daobiao"]["huodong"]["trapmine"]["npc"][self:Type()]
    assert(mData, string.format("trapmine npc:%s not exist!", self:Type()))
    return mData

end

function CClientNpc:ID()
    return self.m_ID
end

function CClientNpc:Type()
    return self.m_iType
end

function CClientNpc:GetTollgate()
    local mNpcData = self:GetData()
    return mNpcData.tollgateId
end

function CClientNpc:GetBossType()
    return self.m_iBossType
end

function CClientNpc:Title()
    return self:GetData()["title"]
end

function CClientNpc:Name()
    return self:GetData()["name"]
end

function CClientNpc:PackInfo()
    local mData = {
            npctype = self:Type(),
            npcid      = self:ID(),
            name = self:Name(),
            title = self:Title(),
            map_id = self.m_iMapid,
            pos_info = self.m_mPosInfo,
            model_info = self.m_mModel,
            createtime = self.m_iCreateTime,
            flag = self.m_iTrapMine,
    }
    return mData
end

function CClientNpc:GetPos()
    local mPos = self.m_mPosInfo
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