--import module

local global = require "global"
local skynet = require "skynet"

local titleobj = import(service_path("title.titleobj"))
local titledefines = import(service_path("title.titledefines"))

function NewTitle(...)
    return CTitle:New(...)
end

CTitle = {}
CTitle.__index = CTitle
inherit(CTitle, titleobj.CTitle)

function CTitle:New(iPid, iTid, create_time, matename)
    local o = super(CTitle).New(self, iPid, iTid, create_time)
    o:SetMateName(matename)
    return o
end

function CTitle:GetName()
    return self:GetData("matename","") .."的".. self:GetData("postfix","恋人")
end

function CTitle:Save()
    local mData = super(CTitle).Save(self)
    mData.matename = self:GetData("matename")
    mData.postfix = self:GetData("postfix")
    return mData
end

function CTitle:Load(mData)
    self:SetData("postfix", mData.postfix)
    self:SetData("matename", mData.matename)
end

function CTitle:GetPostfix()
    return self:GetData("postfix")
end

function CTitle:SetPostfix(sPostfix)
    self:SetData("postfix", sPostfix)
    self:Sync2Client()
end

function CTitle:GetMateName()
    return self:GetData("matename","")
end

function CTitle:SetMateName(sName)
    self:SetData("matename", sName)
    self:Sync2Client()
end

function CTitle:Sync2Client()
    local iPid = self:GetPid()
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CUpdateTitleInfo", {info=self:PackTitleInfo()})
        oPlayer:PropChange("title_info")
        oPlayer:SyncSceneInfo({title_info=oPlayer:PackTitleInfo()})
    end
end

function CTitle:CheckAdjust(sNewName)
    self:SetMateName(sNewName)
end