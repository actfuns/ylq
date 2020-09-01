--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local sceneobj = import(service_path("sceneobj"))

function NewSceneMgr(...)
    local o = CSceneMgr:New(...)
    return o
end

CSceneMgr = {}
CSceneMgr.__index = CSceneMgr
inherit(CSceneMgr, logic_base_cls())

function CSceneMgr:New()
    local o = super(CSceneMgr).New(self)
    o.m_mScenes = {}
    return o
end

function CSceneMgr:Release()
    for _, v in pairs(self.m_mScenes) do
        baseobj_safe_release(v)
    end
    self.m_mScenes = {}
    super(CSceneMgr).Release(self)
end

function CSceneMgr:ConfirmRemote(iScene, iMap)
    assert(not self.m_mScenes[iScene], string.format("ConfirmRemote error %d", iScene))
    local oScene = sceneobj.NewScene(iScene, iMap)
    self.m_mScenes[iScene] = oScene
    oScene:Init()
end

function CSceneMgr:GetScene(iScene)
    return self.m_mScenes[iScene]
end

function CSceneMgr:RemoveScene(iScene)
    local oScene = self.m_mScenes[iScene]
    if oScene then
        self.m_mScenes[iScene] = nil
        baseobj_delay_release(oScene)
    end
end

function CSceneMgr:SceneDispatchFinishHook()
end

function CSceneMgr:GetEntity(iScene,iEntity)
    local oScene = self:GetScene(iScene)
    if not oScene then
        return
    end
    local oEntity = oScene:GetEntity(iEntity)
    return oEntity
end
