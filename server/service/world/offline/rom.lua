--
local skynet = require "skynet"
local global = require "global"
local interactive = require "base.interactive"
local extend = require "base/extend"
local record = require "public.record"


local defines = import(service_path("offline.defines"))
local CBaseOfflineCtrl = import(service_path("offline.baseofflinectrl")).CBaseOfflineCtrl
local gamedefines = import(lualib_path("public.gamedefines"))


CRomCtrl = {}
CRomCtrl.__index = CRomCtrl
inherit(CRomCtrl, CBaseOfflineCtrl)

function CRomCtrl:New(iPid)
    local o = super(CRomCtrl).New(self, iPid)
    o.m_sDbFlag = "Rom"
    o.m_PlayerWarInfo = nil
    o.m_ClubArenaPartner = {}
    o.m_RecordList = {}
    return o
end

function CRomCtrl:Save()
    local mData = {}
    mData["player"] = self.m_PlayerWarInfo
    mData["cpar"] = self.m_ClubArenaPartner
    mData["record"] = self.m_RecordList
    return mData
end

function CRomCtrl:Load(mData)
    self.m_PlayerWarInfo = mData["player"]
    self.m_ClubArenaPartner = mData["cpar"] or {}
    self.m_RecordList = mData["record"] or {}
end

function CRomCtrl:IsActive()
    local iNowTime = get_time()
    if iNowTime - self:GetLastTime() <= 5 * 60 then
        return true
    end
    return false
end

function CBaseOfflineCtrl:OnLogout(oPlayer)
end


function CRomCtrl:UpdateWar(m)
    self.m_PlayerWarInfo = m
    self:Dirty()
end

function CRomCtrl:ClubArenaData()
    if not self.m_PlayerWarInfo then
        return nil
    end
    return {
        player = self.m_PlayerWarInfo,
        partner = self.m_ClubArenaPartner,
        }
end


function CRomCtrl:SetClubArenaPartner(mPartner)
    assert(#mPartner <=4)
    local bSave = false
    if #self.m_ClubArenaPartner == 0 then
        bSave = true
    end
    self.m_ClubArenaPartner = mPartner
    self:Dirty()
    if bSave then
        self:SaveDb()
    end
end

function CRomCtrl:AddRecord(m,iLimit)
    if #self.m_RecordList > iLimit then
        table.remove(self.m_RecordList,1)
    end
    table.insert(self.m_RecordList,m)
    self:Dirty()
end

function CRomCtrl:Record()
    return self.m_RecordList
end

--[[
function CRomCtrl:SetClubArenaPartner(post,mPartner)
    if post <0 or post > 4 then
        return
    end
    local iParid = mPartner.parid
    local mPost = self.m_ClubArenaPartner["post"] or {}
    for iPos,id in pairs(mPost) do
        if id == iParid then
            mPost[iPos] = nil
            break
        end
    end
    local iOldParid = mPost[post]
    mPost[post] = iParid
    local mPartnerList = self.m_ClubArenaPartner["partner"] or {}
    if mPartnerList[iOldParid] then
        mPartnerList[iOldParid] = nil
    end
    mPartnerList[iParid] = mPartner
    self.m_ClubArenaPartner["partner"] = mPartnerList
    self.m_ClubArenaPartner["post"] = mPost
    self:Dirty()
end


]]

