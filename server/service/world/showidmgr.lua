local global = require "global"
local interactive = require "base.interactive"
local router = require "base.router"

function NewShowIdMgr(...)
    return CShowIdMgr:New(...)
end

CShowIdMgr = {}
CShowIdMgr.__index = CShowIdMgr
inherit(CShowIdMgr, logic_base_cls())

function CShowIdMgr:SetShowId(iPid, iShowId)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadProfile(iPid, function(oProfile)
        self:SetShowIdAfterLoad(oProfile, iShowId)
    end)
end

function CShowIdMgr:SetShowIdAfterLoad(oProfile, iShowId)
    local oWorldMgr = global.oWorldMgr
    local iPid = oProfile:GetPid()
    local iOldShowId = oProfile:GetShowId()
    
    oProfile:SetShowId(iShowId or iPid)
   
    local iCurrShowId = oProfile:GetShowId() 
    if iOldShowId == iCurrShowId then return end

    if iOldShowId ~= iPid then
        local mData = {pid = iPid, show_id = iOldShowId}
        router.Send("cs", ".idsupply", "common", "RemoveShowIdByPid", mData)
    end
    if iCurrShowId ~= iPid then
        local mData = {pid = iPid, show_id = iCurrShowId}
        router.Send("cs", ".idsupply", "common", "SetShowIdByPid", mData)
    end
    oWorldMgr:SetPlayerByShowId(iOldShowId, nil) 
    self:OnChangeShowId(oProfile)
end

function CShowIdMgr:RemoveShowId(iPid, iShowId)
    local oWorldMgr = global.oWorldMgr
    oWorldMgr:LoadProfile(iPid, function(oProfile)
        self:RemoveShowIdAfterLoad(oProfile, iShowId)
    end)
end

function CShowIdMgr:RemoveShowIdAfterLoad(oProfile, iShowId)
    local iCurrShowId = oProfile:GetShowId()
    if iCurrShowId ~= iShowId then return false end

    self:SetShowIdAfterLoad(oProfile)
    return true
end

function CShowIdMgr:OnChangeShowId(oProfile)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(oProfile:GetPid())
    if oPlayer then
        local iCurrShowId = oProfile:GetShowId()
        oPlayer:PropChange("show_id")
        oPlayer:SyncSceneInfo({show_id = iCurrShowId})
        oWorldMgr:SetPlayerByShowId(iCurrShowId, oPlayer) 
    end
end

