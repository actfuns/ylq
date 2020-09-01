--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local gamedb = import(lualib_path("public.gamedb"))
local gamedefines = import(lualib_path("public.gamedefines"))
local datactrl = import(lualib_path("public.datactrl"))

function NewPlayerIdMgr(...)
    local o = CPlayerIdMgr:New(...)
    return o
end

CPlayerIdMgr = {}
CPlayerIdMgr.__index = CPlayerIdMgr
inherit(CPlayerIdMgr, datactrl.CDataCtrl)

function CPlayerIdMgr:New()
    local o = super(CPlayerIdMgr).New(self)
    o.m_iNowPlayerId = 10000
    o.m_bLoading = true
    return o
end

function CPlayerIdMgr:Load(m)
    m = m or {}
    self.m_iNowPlayerId = m.player_id or 10000
end

function CPlayerIdMgr:Save()
    local m = {}
    m.player_id = self.m_iNowPlayerId
    return m
end

function CPlayerIdMgr:LoadDb()
    local mInfo = {
        module = "idcounter",
        cmd = "LoadPlayerIdCounter",
    }
    gamedb.LoadDb("playerid","common", "LoadDb", mInfo,
    function (mRecord, mData)
        if self:IsLoading() and not is_release(self) then
            self:Load(mData.data)
        end
        self:LoadFinish()
    end)
end

function CPlayerIdMgr:SaveDb()
    if self:IsDirty() then
        local mData = {
            data  = self:Save()
        }
        gamedb.SaveDb("playerid","common", "SaveDb", {module="idcounter",cmd="SavePlayerIdCounter",data = mData})
        self:UnDirty()
    end
end

function CPlayerIdMgr:LoadFinish()
    self.m_bLoading = false
end

function CPlayerIdMgr:IsLoading()
    return self.m_bLoading
end

function CPlayerIdMgr:GenPlayerId()
    local id = self.m_iNowPlayerId + 1
    while self:IsShowId(id) do
        id = id + 1
    end
    self.m_iNowPlayerId = id
    self:Dirty()
    self:SaveDb()
    return self.m_iNowPlayerId
end

function CPlayerIdMgr:IsExcellentId(id)
    local oShowIdMgr = global.oShowIdMgr
    return oShowIdMgr:IsExcellentId(id)
end

function CPlayerIdMgr:IsCoupleId(id)
    local oShowIdMgr = global.oShowIdMgr
    oShowIdMgr:IsCoupleId(id)
end

function CPlayerIdMgr:IsShowId(id)
    local oShowIdMgr = global.oShowIdMgr
    return oShowIdMgr:IsShowId(id)
end
