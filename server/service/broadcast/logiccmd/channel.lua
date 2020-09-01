--import module
local global = require "global"
local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))
local teamchannel = import(service_path("teamchannel"))
local worldchannel = import(service_path("worldchannel"))
local interfacechannel = import(service_path("interfacechannel"))
local friendfocuschannel = import(service_path("friendfocuschannel"))
local orgchannel = import(service_path("orgchannel"))
local orgfubenchannel = import(service_path("orgfubenchannel"))
local fieldbosschannel = import(service_path("fieldbosschannel"))
local teampvpchannel = import(service_path("teampvpchannel"))

function SetupChannel(mRecord, mData)
    local iPid = mData.pid
    local mInfo = mData.info
    local lChannelList = mData.channel_list or {}

    local mChannelInfo = {}
    for _, v in ipairs(lChannelList) do
        local iType, iId, bFlag = table.unpack(v)
        if not mChannelInfo[iType] then
            mChannelInfo[iType] = {}
        end
        mChannelInfo[iType][iId] = bFlag
    end
    
    for k, v in pairs(mChannelInfo) do
        local o1 = global.mChannels[k]
        local lDel = {}
        if o1 then
            for k2, v2 in pairs(v) do
                local o2 = o1[k2]
                if not o2 then
                    if k == gamedefines.BROADCAST_TYPE.WORLD_TYPE then
                        o2 =  worldchannel.NewWorldChannel()
                    elseif k == gamedefines.BROADCAST_TYPE.TEAM_TYPE then
                        o2 = teamchannel.NewTeamChannel()
                    elseif k == gamedefines.BROADCAST_TYPE.INTERFACE_TYPE then
                        o2 = interfacechannel.NewInterfaceChannel()
                    elseif k == gamedefines.BROADCAST_TYPE.FRIEND_FOCUS_TYPE then
                        o2 = friendfocuschannel.NewFriendFocusChannel()
                    elseif k == gamedefines.BROADCAST_TYPE.ORG_TYPE then
                        o2 = orgchannel.NewOrgChannel()
                    elseif k == gamedefines.BROADCAST_TYPE.ORG_FUBEN then
                        o2 = orgfubenchannel.NewOrgFuBenChannel()
                    elseif k == gamedefines.BROADCAST_TYPE.FIELD_BOSS then
                        o2 = fieldbosschannel.NewFieldBossChannel()
                    elseif k == gamedefines.BROADCAST_TYPE.TEAMPVP_TYPE then
                        o2 = teampvpchannel.NewTeamPVPChannel()
                    end
                    o1[k2] = o2
                end
                if o2 then
                    if v2 then
                        o2:Add(iPid, mInfo)
                    else
                        o2:Del(iPid)
                    end
                    if o2:GetAmount() <= 0 then
                        table.insert(lDel, k2)
                    end
                end
            end
            for _, id in ipairs(lDel) do
                o1[id] = nil
            end
        end
    end
end

function SendChannel(mRecord, mData)
    local iType = mData.type
    local iId = mData.id
    local o = global.mChannels[iType][iId]
    if o then
        o:Send(mData.message, mData.data, mData.exclude)
    end
end

function ClearOfflinePlayer(mRecord,mData)

    local mOnlinePlayer = mData.online_player
    local f = function (iType)
        local mDel = {}
        local mChannels = global.mChannels[iType]
        for k,oChannel in pairs(mChannels) do
            local mChannelPlayer = oChannel:GetAll()
            for pid,info in pairs(mChannelPlayer) do
                if not mOnlinePlayer[pid] or (info.mail ~= mOnlinePlayer[pid]["mail"]) then
                    oChannel:Del(pid)
                    table.insert(mDel,pid)
                end
            end
        end
        print("delchannel",iType,#mDel)
    end

    --f(gamedefines.BROADCAST_TYPE.FRIEND_FOCUS_TYPE)
    --f(gamedefines.BROADCAST_TYPE.ORG_FUBEN)
    f(gamedefines.BROADCAST_TYPE.TEAM_TYPE)

    local mNotClear = {}
    local mPlayerInfo = {}
    for iChannelType,mC in pairs(global.mChannels) do
        for iChannelId,oC in pairs(mC) do
            local mPlayer = oC:GetAll()
            for pid,info in pairs(mPlayer) do
                if not mOnlinePlayer[pid] or (info.mail ~= mOnlinePlayer[pid]["mail"]) then
                    if not mNotClear[iChannelType] then
                        mNotClear[iChannelType] = 0
                    end
                    mNotClear[iChannelType] = mNotClear[iChannelType]  + 1
                    if not mPlayerInfo[iChannelType] then
                        mPlayerInfo[iChannelType] = {}
                    end
                    if not mPlayerInfo[iChannelType][iChannelId] then
                        mPlayerInfo[iChannelType][iChannelId] = {}
                    end
                    table.insert(mPlayerInfo[iChannelType][iChannelId],{pid,info.mail})
                end
            end
        end
    end
    print("mNotClear",mNotClear)
    print("ChannelINfo",mPlayerInfo)
end