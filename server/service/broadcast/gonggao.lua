--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"

local gamedefines = import(lualib_path("public.gamedefines"))
local datactrl = import(lualib_path("public.datactrl"))


function NewGonggaoMgr(...)
    local o = CGonggaoMgr:New(...)
    return o
end


CGonggaoMgr = {}
CGonggaoMgr.__index = CGonggaoMgr
inherit(CGonggaoMgr, datactrl.CDataCtrl)

function CGonggaoMgr:New()
    local o = super(CGonggaoMgr).New(self)
    o.m_mBrocastMessage = {}
    return o
end

function CGonggaoMgr:GetPriority(sType)
    local res = require "base.res"
    return res["daobiao"]["gonggao_priority"][sType]["priority"]
end

function CGonggaoMgr:GetChannel(sType)
    local res = require "base.res"
    return res["daobiao"]["gonggao_priority"][sType]["channel"]
end

function CGonggaoMgr:AddMessage(sType,mNet)
    if table_count(self.m_mBrocastMessage) <= 0 then
        self:PrepareBroadcast()
    end
    local iPriority = self:GetPriority(sType)
    local iChannel = self:GetChannel(sType)
    mNet["tag_type"] = iChannel
    if not self.m_mBrocastMessage[iPriority] then
        self.m_mBrocastMessage[iPriority] = {}
    end
    table.insert(self.m_mBrocastMessage[iPriority],mNet)
end

function CGonggaoMgr:PrepareBroadcast()
    local fCallback = function ()
        self:StartBroadcast()
    end
    self:AddTimeCb("StartBroadcast",100,fCallback)
end

function CGonggaoMgr:StartBroadcast()
    self:DelTimeCb("StartBroadcast")
    local sNetMessage = "GS2CSysChat"
    local iType = gamedefines.BROADCAST_TYPE.WORLD_TYPE
    local iWorldTypeID = 1
    local lPriority = table_key_list(self.m_mBrocastMessage)
    table.sort(lPriority)
    for _,iPriority in pairs(lPriority) do
        local lMessage = self.m_mBrocastMessage[iPriority]
        for _,mNet in pairs(lMessage) do
            local o = global.mChannels[iType][iWorldTypeID]
            if o then
                o:Send(sNetMessage,mNet,{})
            end
        end
    end
    self.m_mBrocastMessage = {}
end

