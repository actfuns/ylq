--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))

function NewOrgIdMgr(...)
    local o = COrgIdMgr:New(...)
    return o
end

COrgIdMgr = {}
COrgIdMgr.__index = COrgIdMgr
inherit(COrgIdMgr, datactrl.CDataCtrl)

function COrgIdMgr:New()
    local o = super(COrgIdMgr).New(self)
    return o
end

function COrgIdMgr:Load(m)
    m = m or {}
    self:SetData("nowid", m.now_id or 0)
end

function COrgIdMgr:Save()
    local m = {}
    m.now_id = self:GetData("nowid", 0)
    return m
end

function COrgIdMgr:LoadDb()
    local mInfo = {
        module = "idcounter",
        cmd = "LoadOrgIdCounter",
    }
    gamedb.LoadDb("orgidmgr","common", "LoadDb", mInfo,
    function (mRecord, mData)
        if not is_release(self) then
            self:Load(mData.data)
        end
    end)
end

function COrgIdMgr:SaveDb()
    if self:IsDirty() then
        local mData = {
            data = self:Save()
        }
        gamedb.SaveDb("orgidmgr","common", "SaveDb", {module = "idcounter",cmd = "SaveOrgIdCounter",data = mData})
        self:UnDirty()
    end
end

function COrgIdMgr:GenOrgId()
    local id = self:GetData("nowid", 0) + 1
    self:SetData("nowid", id)
    self:SaveDb()
    return id
end
