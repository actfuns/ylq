--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))


function NewInterfaceMgr(...)
    return CInterfaceMgr:New(...)
end

CInterfaceMgr = {}
CInterfaceMgr.__index = CInterfaceMgr
inherit(CInterfaceMgr,logic_base_cls())

function CInterfaceMgr:New()
    local o = super(CInterfaceMgr).New(self)
    o.m_mInterface = {}
    o.m_mPlayers = {}
    return o
end

function CInterfaceMgr:OnLogin(oPlayer, bReEnter)
    local iOldType = self:Get(oPlayer)
    if iOldType then
        self:Close(oPlayer, iOldType)
    end
end

function CInterfaceMgr:OnLogout(oPlayer)
    local iOldType = self:Get(oPlayer)
    if iOldType then
        self:Close(oPlayer, iOldType)
    end
end

function CInterfaceMgr:OnDisconnected(oPlayer)
    local iOldType = self:Get(oPlayer)
    if iOldType then
        self:Close(oPlayer, iOldType)
    end
end

function CInterfaceMgr:Get(oPlayer)
    return self.m_mInterface[oPlayer:GetPid()]
end

function CInterfaceMgr:Open(oPlayer, iType)
    local iPid = oPlayer:GetPid()
    self.m_mInterface[iPid] = iType
    self:AddFacePlayers(oPlayer,iType)

    local mRole = {
        pid = iPid,
    }
    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = iPid,
        channel_list = {
            {gamedefines.BROADCAST_TYPE.INTERFACE_TYPE, iType, true},
        },
        info = mRole,
    })
    self:OnOpen(oPlayer,iType)
end

function CInterfaceMgr:Close(oPlayer, iType)
    local iPid = oPlayer:GetPid()
    local iOldType = self:Get(oPlayer)

    if iOldType == iType then
        self.m_mInterface[iPid] = nil
        self:RemoveFacePlayers(oPlayer,iType)

        local mRole = {
            pid = iPid,
        }
        interactive.Send(".broadcast", "channel", "SetupChannel", {
            pid = iPid,
            channel_list = {
                {gamedefines.BROADCAST_TYPE.INTERFACE_TYPE, iType, false},
            },
            info = mRole,
        })
        self:OnClose(oPlayer,iType)
    end
end

function CInterfaceMgr:ClientOpen(oPlayer, iType)
    local iOldType = self:Get(oPlayer)
    if iOldType then
        self:Close(oPlayer, iOldType)
    end
    self:Open(oPlayer, iType)
end

function CInterfaceMgr:ClientClose(oPlayer, iType)
    self:Close(oPlayer, iType)
end

function CInterfaceMgr:OnOpen(oPlayer,iType)
    if iType == gamedefines.INTERFACE_TYPE.BARRAGE_TYPE then
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("upcard")
        if oHuodong then
            oHuodong:EnterInterface(oPlayer,iType)
        end
    end
end

function CInterfaceMgr:OnClose(oPlayer,iType)
    if iType == gamedefines.INTERFACE_TYPE.BARRAGE_TYPE then
        local oHuodongMgr = global.oHuodongMgr
        local oHuodong = oHuodongMgr:GetHuodong("upcard")
        if oHuodong then
            oHuodong:CloseInterface(oPlayer,iType)
        end
    end
    local oWorldMgr = global.oWorldMgr
    if iType == gamedefines.INTERFACE_TYPE.WAR_RESULT then
        if oPlayer:IsTeamLeader() then
            local mMem = oPlayer:GetTeamMember()
            for _,iPid in pairs(mMem) do
                local oTeamPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
                if oTeamPlayer then
                    self:Close(oTeamPlayer,iType)
                    oTeamPlayer:Send("GS2CCloseWarResultUI",{})
                end
            end
        end
    end
end

function CInterfaceMgr:AddFacePlayers(oPlayer,iType)
    local mPlayers = self.m_mPlayers[iType] or {}
    local iPid = oPlayer.m_iPid
    mPlayers[iPid] = 1
    self.m_mPlayers[iType] = mPlayers
end

function CInterfaceMgr:RemoveFacePlayers(oPlayer,iType)
    local mPlayers = self.m_mPlayers[iType] or {}
    local iPid = oPlayer.m_iPid
    mPlayers[iPid] = nil
    self.m_mPlayers[iType] = mPlayers
end

function CInterfaceMgr:GetFacePlayers(iType)
    return self.m_mPlayers[iType] or {}
end

function CInterfaceMgr:SendBarrage(mNet)
    local mData = {
        message = "GS2CBarrage",
        type = gamedefines.BROADCAST_TYPE.INTERFACE_TYPE,
        id = gamedefines.INTERFACE_TYPE.BARRAGE_TYPE,
        data = mNet,
    }
    interactive.Send(".broadcast","channel","SendChannel",mData)
end

function CInterfaceMgr:WorldBossNotify(sHead,mNet)
    local mData = {
        message = sHead,
        type = gamedefines.BROADCAST_TYPE.INTERFACE_TYPE,
        id = gamedefines.INTERFACE_TYPE.WORLD_BOSS,
        data = mNet,
    }
    interactive.Send(".broadcast","channel","SendChannel",mData)
end

function CInterfaceMgr:MSBossNotify(sHead,mNet)
    local mData = {
        message = sHead,
        type = gamedefines.BROADCAST_TYPE.INTERFACE_TYPE,
        id = gamedefines.INTERFACE_TYPE.MS_BOSS,
        data = mNet,
    }
    interactive.Send(".broadcast","channel","SendChannel",mData)
end
