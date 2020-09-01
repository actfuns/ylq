local global = require "global"
local skynet = require "skynet"
local net = require "base.net"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedb = import(lualib_path("public.gamedb"))
local datactrl = import(lualib_path("public.datactrl"))
local playerobj = import(service_path("playerobj"))

local sTableName = "image"

function NewImageMgr(...)
    local o = CImageMgr:New(...)
    return o
end

CImageMgr = {}
CImageMgr.__index = CImageMgr
inherit(CImageMgr, datactrl.CDataCtrl)

function CImageMgr:New()
    local o = super(CImageMgr).New(self)
    o.m_mPlayers = {}
    return o
end

function CImageMgr:CloseGS()
    save_all()
    local lPids = table_key_list(self.m_mPlayers)
    for _, iPid in ipairs(lPids) do
        self:OnLogout(iPid)
    end
end

function CImageMgr:Disconnected(iPid)
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        oPlayer:Disconnected()
    end
end

function CImageMgr:OnLogout(iPid)
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        oPlayer:OnLogout()
        self.m_mPlayers[iPid] = nil
        baseobj_delay_release(oPlayer)
    end
end

function CImageMgr:OnLogin(iPid, mInfo)
    local o = self:GetPlayer(iPid)
    if o then
        o:OnLogin(true)
    else
        self.m_mPlayers[iPid] = playerobj.NewPlayer(iPid, mInfo)
        local mData = {
            pid = iPid
        }
        local mArgs = {
            module = "imagedb",
            cmd = "LoadImage",
            data = mData
        }
        gamedb.LoadDb("image","common", "LoadDb", mArgs, function (mRecord, mData)
            if not is_release(self) then
                self:_LoadImage(mRecord, mData)
            end
        end)
    end
end

function CImageMgr:_LoadImage(mRecord, mData)
    local iPid = mData.pid
    local m = mData.data
    local o = self:GetPlayer(iPid)
    if o then
        o:LoadFinish(m)
    end
end

function CImageMgr:GetPlayer(iPid)
    return self.m_mPlayers[iPid]
end

function CImageMgr:Notify(iPid, sMsg)
    local oPlayer = self:GetPlayer(iPid)
    if oPlayer then
        oPlayer:Send("GS2CNotify", {cmd = sMsg})
    end
end

function CImageMgr:GetNoPassImages(fCallback)
    gamedb.LoadDb("image","common", "LoadDb", {module= "imagedb",cmd="FindNoPassImage"}, function (mRecord, mData)
        if not is_release(self) then
            if fCallback then
                fCallback(mData.data or {})
            end
            self:SendNoPassImages(mRecord, mData)
        end
    end)
end

function CImageMgr:SendNoPassImages(mRecord, mData)
    local mTmp = {}
    local mImages = mData.data or {}
    for _,mUnit in pairs(mImages) do
        mTmp[mUnit.key] = mUnit.pid
    end
    self.m_Key2Pid = mTmp
end

function CImageMgr:CheckImagePass(keylist)
    local mUpdate = {}
    keylist = keylist or {}
    for _, key in ipairs(keylist) do
        local iPid = self.m_Key2Pid[key]
        if iPid then
            local oPlayer = self:GetPlayer(iPid)
            if oPlayer then
                oPlayer.m_oImageCtrl:CheckPass(key)
            end
            mUpdate[key] = true
        end
    end
    if table_count(mUpdate) > 0 then
        local mData = {
            keylist = mUpdate
        }
        gamedb.SaveDb("image","common", "SaveDb", {
            module = "imagedb",
            cmd = "CheckImagePass",
            data = mData,
        })
    end
end

function CImageMgr:TestCmd(sCmd, iPid, ...)
    local mArgs = {...}
    if sCmd == "addimage" then
        local oPlayer = self:GetPlayer(iPid)
        if oPlayer then
            local lKey = table.unpack(mArgs)
            for _, key in ipairs(lKey) do
                if type(key) == "string" then
                    oPlayer.m_oImageCtrl:AddImage(key)
                end
            end
        end
    end
end