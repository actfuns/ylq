--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"
local playersend = require "base.playersend"
local extend = require "base/extend"
local record = require "public.record"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))
local imagectrl = import(service_path("imagectrl"))

function NewPlayer(...)
    local o = CPlayer:New(...)
    return o
end

local function SaveDbFunc(self)
    if self.m_oImageCtrl:IsDirty() then
        local Image = self.m_oImageCtrl:Save()
        local mData = {
            pid = self:GetPid(),
            Image = self.m_oImageCtrl:Save()
        }
        gamedb.SaveDb("image","common", "SaveDb", {module="imagedb",cmd="SaveImage",data = mData})
    end
end

CPlayer = {}
CPlayer.__index = CPlayer
inherit(CPlayer, datactrl.CDataCtrl)

function CPlayer:New(iPid,mInfo)
    local o = super(CPlayer).New(self)
    o.m_iPid = iPid
    o.m_oImageCtrl = imagectrl.NewImageCtrl()
    return o
end

function CPlayer:Release()
    baseobj_delay_release(self.m_oImageCtrl)
    super(CPlayer).Release(self)
end

function CPlayer:GetPid()
    return self.m_iPid
end

function CPlayer:OnLogin(bReEnter)
end

function CPlayer:OnLogout()
    self:DoSave()
end

function CPlayer:Disconnected()
end

function CPlayer:Send(sMessage, mData)
    playersend.Send(self.m_iPid,sMessage,mData)
end

function CPlayer:SendRaw(sData)
    playersend.SendRaw(self.m_iPid,sData)
end

function CPlayer:LoadFinish(mData)
    local iPid = self:GetPid()
    self:ApplySave(function ()
        local oImageMgr = global.oImageMgr
        local obj = oImageMgr:GetPlayer(iPid)
        if not obj then
            record.warning(string.format("Image service , not have player　id: %d",iPid))
            return
        end
        SaveDbFunc(obj)
    end)
    self.m_oImageCtrl:Load(mData)
    self:OnLogin(false)
end

function CPlayer:OpenImages()
    local mImages = self.m_oImageCtrl:GetList()
    self:Send("GS2CImages",{keys=table_key_list(mImages)})
end

function CPlayer:AddImage(sKey)
    self.m_oImageCtrl:AddImage(sKey)
    self:OpenImages()
end