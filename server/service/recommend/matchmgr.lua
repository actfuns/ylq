
local skynet = require "skynet"
local defines = import(service_path("defines"))


CMatchMgr = {}
CMatchMgr.__index = CMatchMgr
inherit(CMatchMgr, logic_base_cls())


function NewMatchMgr()
    local o = CMatchMgr:New()

    return o
end

function CMatchMgr:New()
    local o = super(CMatchMgr).New(self)
    o.m_List = {}
    for _,sName in pairs(defines.REGISTER_MATCH) do
        o:NewMatch(sName)
    end
    return o
end

function CMatchMgr:NewMatch(sName)
    local sPath = string.format("match/%s",sName)
    local oModule = import(service_path(sPath))
    local oMatch = oModule.NewMatch()
    oMatch.m_Name = sName
    self.m_List[sName] = oMatch
    return oMatch
end


function CMatchMgr:GetMatch(sName)
    return self.m_List[sName]
end





