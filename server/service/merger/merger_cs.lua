--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local mongoop = require "base.mongoop"
local record = require "public.record"

local serverinfo = import(lualib_path("public.serverinfo"))
local defines = import(service_path("defines"))


function NewMerger(...)
    local o = CMerger:New(...)
    return o
end


CMerger = {}
CMerger.__index = CMerger
inherit(CMerger, logic_base_cls())

function CMerger:New()
    local o = super(CMerger).New(self)
    o.m_iMergerTimes = 0
    o.m_sFromServer = nil
    o.m_sToServer = nil
    o.m_oLocalDb = nil
    return o
end

function CMerger:GetLocalDb()
    local mLocal = serverinfo.get_local_dbs()

    local oLocalClient = mongoop.NewMongoClient({
        host = mLocal.game.host,
        port = mLocal.game.port,
        username = mLocal.game.username,
        password = mLocal.game.password
    })
    local oLocalGameDb = mongoop.NewMongoObj()
    oLocalGameDb:Init(oLocalClient, "game")
    self.m_oLocalDb = oLocalGameDb
    return oLocalGameDb
end

function CMerger:StartMerger(iMergerTimes)
    local lInfo = defines.MERGER_INFO[iMergerTimes]
    if not lInfo then
        record.error("error merger times %s", iMergerTimes)
        return
    end
    self.m_sFromServer = lInfo[1]
    self.m_sToServer = lInfo[2]
    local oLocalGameDb = self:GetLocalDb()
    
    print(string.format("----merger start: %s times----", iMergerTimes))
    print("start handle roleinfo----")
    self:HandleRoleInfo(oLocalGameDb)
    print("----handle roleinfo finish")
    print(string.format("----merger end: %s times----", iMergerTimes))
end

function CMerger:HandleRoleInfo(oLocalGameDb)
    oLocalGameDb:Update("roleinfo", {now_server = self.m_sFromServer}, {["$set"] = {now_server = self.m_sToServer}}, false, true)
end
