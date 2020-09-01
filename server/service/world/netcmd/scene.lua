--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"


function C2GSSyncPosQueue(oPlayer, mData)
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local oHuodongMgr = global.oHuodongMgr
    local oHuodong = oHuodongMgr:GetHuodong("trapmine")
    local iPid = oPlayer:GetPid()
    if oHuodong:IsClientAutoStart(oPlayer) then
        return
    end
    if oScene and oScene:GetSceneId() == mData.scene_id then
        local poslist = mData["poslist"]
        if #poslist < 1 then
            return
        end
        local mPos = poslist[1]["pos"]
        if oPlayer:IsSocialDisplay() then
            oPlayer:CancelSocailDisplay()
        end
        oScene:OnSyncPos(oPlayer, mPos)
        oScene:Forward("C2GSSyncPosQueue", oPlayer:GetPid(), mData)
    end
end

function C2GSTransfer(oPlayer, mData)
    local oSceneMgr = global.oSceneMgr
    local oNotifyMgr = global.oNotifyMgr
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local oTeam = oPlayer:HasTeam()
    local pid = oPlayer.m_iPid
    if oTeam and not oTeam:IsLeader(pid) and oTeam:IsTeamMember(pid) then
        oNotifyMgr:Notify(pid,"您在队伍中，不能操作")
        return
    end
    if oPlayer:GetNowWar() then
        return
    end
    if oScene:QueryLimitRule("transfer") then
        oNotifyMgr:Notify(pid,"场景禁止传送")
        return
    end
    if oScene:GetSceneId() == mData.scene_id then
        if oPlayer:IsSocialDisplay() then
            oPlayer:CancelSocailDisplay()
        end
        oSceneMgr:TransferScene(oPlayer, mData.transfer_id)
    end
end

function C2GSClickWorldMap(oPlayer, mData)
    local oSceneMgr = global.oSceneMgr
    local oNotifyMgr = global.oNotifyMgr
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local oTeam = oPlayer:HasTeam()
    local pid = oPlayer.m_iPid
    if oTeam and not oTeam:IsLeader(pid) and oTeam:IsTeamMember(pid) then
        oNotifyMgr:Notify(pid,"您在队伍中，不能操作")
        return
    end
    if oScene:GetSceneId() == mData.scene_id then
        if oPlayer:IsSocialDisplay() then
            oPlayer:CancelSocailDisplay()
        end
        oSceneMgr:ChangeMap(oPlayer,mData.map_id)
    end
end

function C2GSClickTrapMineMap(oPlayer, mData)
    local oNotifyMgr = global.oNotifyMgr
    local oSceneMgr = global.oSceneMgr
    local oNotifyMgr = global.oNotifyMgr
    local oScene = oPlayer.m_oActiveCtrl:GetNowScene()
    local oTeam = oPlayer:HasTeam()
    local pid = oPlayer.m_iPid
    if oTeam and not oTeam:IsLeader(pid) and oTeam:IsTeamMember(pid) then
        oNotifyMgr:Notify(pid,"您在队伍中，不能操作")
        return
    end
    if oScene:GetSceneId() == mData.scene_id then
        if oPlayer:IsSocialDisplay() then
            oPlayer:CancelSocailDisplay()
        end
        oSceneMgr:ClickTrapMineMap(oPlayer, mData.map_id)
    end
end

function C2GSChangeSceneModel(oPlayer,mData)
    local iSceneModel = mData["scene_model"] or 1
    oPlayer:SetSceneModel(iSceneModel)
end

function C2GSFlyToPos(oPlayer,mData)
    if not oPlayer:IsSingle() then return end
    local iMap = mData.map_id
    local mPos = mData.pos_info
    local oScene = global.oSceneMgr:SelectDurableScene(tonumber(iMap))
    if not oScene then
        return
    end

    local iSceneId = oScene:GetSceneId()
    global.oSceneMgr:EnterScene(oPlayer,iSceneId,{pos=mPos},true)
end