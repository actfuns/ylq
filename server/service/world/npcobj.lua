--import module

local global = require "global"
local loadnpc = import(service_path("npc/loadnpc"))

function NewNpcMgr()
    local oMgr = CNpcMgr:New()
    return oMgr
end


CNpcMgr = {}
CNpcMgr.__index = CNpcMgr
inherit(CNpcMgr,logic_base_cls())

function CNpcMgr:New()
    local o = super(CNpcMgr).New(self)
    o.m_mObject = {}
    o.m_mGlobalList = {}
    o.m_mTempList = {}
    o.m_iDispatchId = 0
    return o
end

function CNpcMgr:DispatchId()
    self.m_iDispatchId = self.m_iDispatchId + 1
    return self.m_iDispatchId
end

function CNpcMgr:NewGlobalNpc(iNpcType)
    local oNpc = loadnpc.NewNpc(iNpcType)
    self.m_mObject[oNpc.m_ID] = oNpc
    self.m_mGlobalList[iNpcType] = oNpc
    return oNpc
end

function CNpcMgr:AddObject(oNpc)
    self.m_mObject[oNpc.m_ID] = oNpc
end

function CNpcMgr:RemoveObject(iNpcId)
    self.m_mObject[iNpcId] = nil
end

function CNpcMgr:GetObject(iNpcId)
    return self.m_mObject[iNpcId]
end

function CNpcMgr:GetGlobalNpc(iNpcType)
    return self.m_mGlobalList[iNpcType]
end

function CNpcMgr:GetTempGlobalNpc(iNpcType)
    local oNpc = self.m_mTempList[iNpcType]
    if not oNpc then
        oNpc = loadnpc.NewNpc(iNpcType)
    end
    self.m_mTempList[iNpcType] = oNpc
    return oNpc
end

function CNpcMgr:RemoveSceneNpc(npcid)
    local oNpc = self.m_mObject[npcid]
    local iScene = oNpc:GetScene()
    local oSceneMgr = global.oSceneMgr
    local oScene = oSceneMgr:GetScene(iScene)
    if oScene then
        oScene:RemoveSceneNpc(npcid)
        self:RemoveObject(npcid)
        if oNpc then
            baseobj_delay_release(oNpc)
        end
    end
end

--初始化
function CNpcMgr:LoadInit()
    local extend = require "base.extend"
    local res = require "base.res"
    local mGlobalData = res["daobiao"]["global_npc"] or {}
    for iNpcType,mData in pairs(mGlobalData) do
        local oTempNpc = self:GetTempGlobalNpc(iNpcType)
        local iMapid = oTempNpc.m_iMapid
        local oSceneMgr = global.oSceneMgr
        local mScene = oSceneMgr:GetSceneListByMap(iMapid)
        for _,oScene in pairs(mScene) do
            local oNpc = self:NewGlobalNpc(iNpcType)
            oNpc:SetScene(oScene:GetSceneId())
            oScene:EnterNpc(oNpc)
        end
    end
end