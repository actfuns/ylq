--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))

local CHANNEL_TYPE = gamedefines.CHANNEL_TYPE

function NewNotifyMgr(...)
    return CNotifyMgr:New(...)
end


CNotifyMgr = {}
CNotifyMgr.__index = CNotifyMgr
inherit(CNotifyMgr,logic_base_cls())

function CNotifyMgr:New()
    local o = super(CNotifyMgr).New(self)
    o.m_mDelayMsg = {}
    return o
end

function CNotifyMgr:OnLogin(oPlayer, bReEnter)
    local mRole = {
        pid = oPlayer:GetPid(),
    }

    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = oPlayer:GetPid(),
        channel_list = {
            {gamedefines.BROADCAST_TYPE.WORLD_TYPE, 1, true},
        },
        info = mRole,
    })


    local iTeamID = oPlayer:TeamID()
    if iTeamID then
        interactive.Send(".broadcast", "channel", "SetupChannel", {
            pid = oPlayer:GetPid(),
            channel_list = {
                {gamedefines.BROADCAST_TYPE.TEAM_TYPE, iTeamID, true},
            },
            info = mRole,
        })
    else
        interactive.Send(".broadcast", "channel", "SetupChannel", {
            pid = oPlayer:GetPid(),
            channel_list = {
                {gamedefines.BROADCAST_TYPE.TEAM_TYPE, 1, true},
            },
            info = mRole,
        })
    end
end

function CNotifyMgr:OnLogout(oPlayer)
    local mRole = {
        pid = oPlayer:GetPid(),
    }

    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = oPlayer:GetPid(),
        channel_list = {
            {gamedefines.BROADCAST_TYPE.WORLD_TYPE, 1, false},
        },
        info = mRole,
    })

    local iTeamID = oPlayer:TeamID()
    if iTeamID then
        interactive.Send(".broadcast", "channel", "SetupChannel", {
            pid = oPlayer:GetPid(),
            channel_list = {
                {gamedefines.BROADCAST_TYPE.TEAM_TYPE, iTeamID, false},
            },
            info = mRole,
        })
    end
    interactive.Send(".broadcast", "channel", "SetupChannel", {
            pid = oPlayer:GetPid(),
            channel_list = {
                {gamedefines.BROADCAST_TYPE.TEAM_TYPE, 1, false},
            },
            info = mRole,
        })
end

function CNotifyMgr:OnDisconnected(oPlayer)
    local mRole = {
        pid = oPlayer:GetPid(),
    }

    interactive.Send(".broadcast", "channel", "SetupChannel", {
        pid = oPlayer:GetPid(),
        channel_list = {
            {gamedefines.BROADCAST_TYPE.WORLD_TYPE, 1, false},
        },
        info = mRole,
    })

    local iTeamID = oPlayer:TeamID()
    if iTeamID then
        interactive.Send(".broadcast", "channel", "SetupChannel", {
            pid = oPlayer:GetPid(),
            channel_list = {
                {gamedefines.BROADCAST_TYPE.TEAM_TYPE, iTeamID, false},
            },
            info = mRole,
        })
    end
end

function CNotifyMgr:Notify(iPid, sMsg)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if oPlayer then
        oPlayer:Send("GS2CNotify", {
            cmd = sMsg,
        })
    end
end

function CNotifyMgr:BroadCastNotify(iPid,lMessage,sMsg,mArgs)
    lMessage = lMessage or {"GS2CNotify",}
    local mNet = {
        content = sMsg,
        args = mArgs,
    }
    local mData = {
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        pid = iPid,
        message = lMessage,
        data = mNet,
    }
    interactive.Send(".broadcast", "notify", "ChannelNotify", mData)
end

function CNotifyMgr:BroadCastTeamNotify(iID,lMessage,sMsg,mArgs,mRole, mExclude)
    local mNet = {
        content = sMsg,
        args = mArgs,
        type = gamedefines.CHANNEL_TYPE.TEAM_TYPE,
        role_info = mRole,
    }
    local mData = {
        message = lMessage,
        id = iID,
        type = gamedefines.BROADCAST_TYPE.TEAM_TYPE,
        data = mNet,
        exclude = mExclude,
    }
    interactive.Send(".broadcast", "notify", "ChannelNotify",mData)
end

function CNotifyMgr:NotifyMessage(iPid,sMsg)
    local oWorldMgr = global.oWorldMgr
    local oPlayer = oWorldMgr:GetOnlinePlayerByPid(iPid)
    if not oPlayer then
        return
    end

    local mNet = {
        type = gamedefines.CHANNEL_TYPE.CURRENT_TYPE,
        cmd = sMsg,
        role_info = {
        pid=0,
        grade = 0,
        name = "",
        shape = 0,
        },
    }
    oPlayer:Send("GS2CChat",mNet)
end


function CNotifyMgr:LogChat(pid,name,channel,text)
    local mLog = {
    pid = pid,
    name = name,
    channel = channel,
    text = text,
    svr = skynet.getenv("server_key"),
    }
    record.chat("chat","chat",mLog)
end

function CNotifyMgr:SendWorldChat(sMsg, mRoleInfo, mExclude)
    if mRoleInfo["pid"] ~= 0 then
        self:LogChat(mRoleInfo["pid"],mRoleInfo["name"],gamedefines.CHANNEL_TYPE.WORLD_TYPE,sMsg)
    end
    local mNet = {
        type = gamedefines.CHANNEL_TYPE.WORLD_TYPE,
        cmd = sMsg,
        role_info = mRoleInfo,
    }
    local mData = {
        message = "GS2CChat",
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        data = mNet,
        exclude = mExclude,
    }
    interactive.Send(".broadcast", "channel", "SendChannel", mData)
end

--iTag 0-公告 1-传闻 2-帮助
function CNotifyMgr:SendSysChat(sMsg, iTag, iHorse, mExclude)
    local mNet = {
        content = sMsg,
        tag_type = iTag,
        horse_race = iHorse,
    }
    local mData = {
        message = "GS2CSysChat",
        type = gamedefines.BROADCAST_TYPE.WORLD_TYPE,
        id = 1,
        data = mNet,
        exclude = mExclude,
    }
    interactive.Send(".broadcast", "channel", "SendChannel", mData)
end

function CNotifyMgr:DelaySendSysChat(sMsg,iTag,iHorse,mExclude,mArgs)
    local iDelay = mArgs["delay"] or 0
    if iDelay <= 0 then
        self:SendSysChat(sMsg,iTag,iHorse,mExclude)
        return
    end
    local iPid = mArgs["pid"]
    local sSysName = mArgs["sys_name"]
    if not iPid or not sSysName then
        return
    end
    self.m_mDelayMsg = self.m_mDelayMsg or {}
    self.m_mDelayMsg[sSysName] = self.m_mDelayMsg[sSysName] or {}
    self.m_mDelayMsg[sSysName][iPid] = {msg=sMsg,tag=iTag,horse=iHorse,exclude = mExclude,time=get_time()+iDelay}
    if not self:GetTimeCb("_CheckDelayMsg") then
        self:AddTimeCb("_CheckDelayMsg",2*1000,function()
                global.oNotifyMgr:_CheckDelayMsg()
            end)
    end
end

function CNotifyMgr:_CheckDelayMsg()
    self:DelTimeCb("_CheckDelayMsg")
    if table_count(self.m_mDelayMsg) <= 0 then
        return
    end
    for sSysName,mPlayer in pairs(self.m_mDelayMsg) do
        for iPid,info in pairs(mPlayer) do
            if get_time() >= info["time"] then
                self:SendSysChat(info["msg"],info["tag"],info["horse"],info["exclude"])
                mPlayer[iPid] = nil
            end
        end
        if table_count(self.m_mDelayMsg[sSysName]) <= 0 then
            self.m_mDelayMsg[sSysName] = nil
        end
    end
    if table_count(self.m_mDelayMsg) > 0 then
        self:AddTimeCb("_CheckDelayMsg",2*1000,function()
                global.oNotifyMgr:_CheckDelayMsg()
            end)
    end
end

function CNotifyMgr:SendDelaySysMsg(sSysName,iPid)
    if not self.m_mDelayMsg[sSysName] or not self.m_mDelayMsg[sSysName][iPid] then
        return
    end
    local mInfo = self.m_mDelayMsg[sSysName][iPid]
    self:SendSysChat(mInfo["msg"],mInfo["tag"],mInfo["horse"],mInfo["exclude"])
    self.m_mDelayMsg[sSysName][iPid] = nil
    if table_count(self.m_mDelayMsg[sSysName]) <= 0 then
        self.m_mDelayMsg[sSysName] = nil
    end
end

function CNotifyMgr:SendPrioritySysChat(sType,sMsg,iHorse,mExclude,mArgs)
    mArgs = mArgs or {}
    local res = require "base.res"
    local mConfig = assert(res["daobiao"]["gonggao_priority"][sType])
    local iShowGrade = mArgs["grade"] or mConfig["grade"]
    local mNet = {
        content = sMsg,
        horse_race = iHorse,
        grade = iShowGrade,
    }
    local mData = {
        priority_type = sType,
        data = mNet,
        exclude = mExclude,
    }
    interactive.Send(".broadcast", "gonggao", "SendPrioritySysChat", mData)
end

function CNotifyMgr:SendSelf(oPlayer,sMsg,iTag,iHorse)
    local mNet = {
        content = sMsg,
        tag_type = iTag,
        horse_race = iHorse,
    }
    oPlayer:Send("GS2CSysChat",mNet)
end

function CNotifyMgr:SendTeamChat(sMsg, iID, mRole, mExclude)
    if mRole["pid"] ~= 0 then
        self:LogChat(mRole["pid"],mRole["name"],gamedefines.CHANNEL_TYPE.TEAM_TYPE,sMsg)
    end
    local mNet = {
        cmd = sMsg,
        type = gamedefines.CHANNEL_TYPE.TEAM_TYPE,
        role_info = mRole,
    }
    interactive.Send(".broadcast", "channel", "SendChannel", {
        message = "GS2CChat",
        id = iID,
        type = gamedefines.BROADCAST_TYPE.TEAM_TYPE,
        data = mNet,
        exclude = mExclude,
    })
end

function CNotifyMgr:SendTeamPvpChat(sMsg,iID, mRole, mExclude)
if mRole["pid"] ~= 0 then
        self:LogChat(mRole["pid"],mRole["name"],gamedefines.CHANNEL_TYPE.TEAMPVP_TYPE,sMsg)
    end
    local mNet = {
        cmd = sMsg,
        type = gamedefines.CHANNEL_TYPE.TEAMPVP_TYPE,
        role_info = mRole,
    }
    interactive.Send(".broadcast", "channel", "SendChannel", {
        message = "GS2CChat",
        id = iID,
        type = gamedefines.BROADCAST_TYPE.TEAMPVP_TYPE,
        data = mNet,
        exclude = mExclude,
    })
end

function CNotifyMgr:SendOrgChat(sMsg, iOrgID, mRole, mExclude)
    if mRole["pid"] ~= 0 then
        self:LogChat(mRole["pid"],mRole["name"],gamedefines.CHANNEL_TYPE.ORG_TYPE,sMsg)
    end
    local mNet = {
        cmd = sMsg,
        type = gamedefines.CHANNEL_TYPE.ORG_TYPE,
        role_info = mRole,
    }

    interactive.Send(".broadcast", "channel", "SendChannel", {
        message = "GS2CChat",
        id = iOrgID,
        type = gamedefines.BROADCAST_TYPE.ORG_TYPE,
        data = mNet,
        exclude = mExclude,
    })
end
