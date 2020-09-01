--import module
local skynet = require "skynet"
local global = require "global"
local record = require "public.record"
local playersend = require "base.playersend"

local datactrl = import(lualib_path("public.datactrl"))

function NewKuafuObject(...)
    return CKuafuObject:New(...)
end

CKuafuObject = {}
CKuafuObject.__index = CKuafuObject
inherit(CKuafuObject, datactrl.CDataCtrl)

function CKuafuObject:New(pid,sPlay,data,mail)
    local o = super(CKuafuObject).New(self)
    o.m_iPid = pid
    o.m_sPlay = sPlay
    o.m_mData = data["basedata"]
    o.m_ExtraData = data["extra"] or {}
    o.m_Mail = mail
    return o
end

function CKuafuObject:Release()
    super(CKuafuObject).Release(self)
end

function CKuafuObject:GetServerKey()
    return self.m_Where
end

function CKuafuObject:ExtraData()
    return self.m_ExtraData
end

function CKuafuObject:GetPlayMgr()
    return global.oKFMgr:GetPlayManager(self.m_sPlay)
end

function CKuafuObject:GetPid()
    return self.m_iPid
end

function CKuafuObject:GetName()
    return self:GetData("name")
end

function CKuafuObject:GetGrade()
    return self:GetData("grade")
end

function CKuafuObject:GetSchool()
    return self:GetData("school")
end

function CKuafuObject:GetSchoolBranch()
    return self:GetData("school_branch")
end

function CKuafuObject:GetModelInfo()
    return self:GetData("mode_info")
end

function CKuafuObject:GetServerGrade()
    return self:GetData("server_grade")
end

function CKuafuObject:Send(sMessage, mData)
    playersend.KFSend(self.m_Where,self:GetPid(),sMessage,mData)
end

function CKuafuObject:SendRaw(sData)
    playersend.KFSendRaw(self.m_Where,self:GetPid(),sData)
end

function CKuafuObject:Notify(msg)
    self:Send("GS2CNotify", {
            cmd = msg,
        })
end

function CKuafuObject:Send2Huodong(cmd,mData,fRespond)
    local oKFMgr = global.oKFMgr
    local add = self.m_Where
    oKFMgr:Send2GSHuoDong(self.m_Where,cmd,self.m_sPlay,mData,fRespond)
end


function CKuafuObject:SetNowWarInfo(mInfo)
    local m = self.m_mNowWarInfo
    if not m then
        self.m_mNowWarInfo = {}
        m = self.m_mNowWarInfo
    end
    if mInfo.now_war then
        m.now_war = mInfo.now_war
    end
end


function CKuafuObject:ClearNowWarInfo()
    self.m_mNowWarInfo = {}
end


function CKuafuObject:GetNowWar()
    local m = self.m_mNowWarInfo
    if not m then
        return
    end
    local oWarMgr = global.oWarMgr
    return oWarMgr:GetWar(m.now_war)
end

function CKuafuObject:PackWarInfo(oPlayer)
    return self:ExtraData()["warinfo"]["playerwarinfo"]
end

function CKuafuObject:GetPartnerInfo()
    return self:ExtraData()["warinfo"]["partnerinfo"]
end

function CKuafuObject:SendEvent(cmd,mData)
    local m = {data=mData,play = self.m_sPlay}
    local oKFMgr = global.oKFMgr
    local add = self.m_Where
    oKFMgr:Send2GSProxyEvent(self.m_Where,self:GetPid(),cmd,m)
end

function CKuafuObject:HasTeam()
end

function CKuafuObject:GetAveGrade()
    return self:GetData("avegrade")
end