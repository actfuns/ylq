--import module
local global = require "global"
local interactive = require "base.interactive"

local gamedefines = import(lualib_path("public.gamedefines"))
local huodong = import(service_path("huodong"))

STATE_READY = 1
STATE_START = 2
START_END = 3

HUODONGLIST = {
    ["equalarena"] = "kfequalarena",
    ["arenagame"] = "kfarenagame",
}

function NewHuodongMgr(...)
    return CHuodongMgr:New(...)
end

CHuodongMgr = {}
CHuodongMgr.__index = CHuodongMgr
inherit(CHuodongMgr,huodong.CHuodongMgr)

function CHuodongMgr:New()
    local o = super(CHuodongMgr).New(self)
    return o
end

function CHuodongMgr:Path(sDir)
    return string.format("kuafu.huodong.%s",sDir)
end

function CHuodongMgr:GetHuodongList()
    return HUODONGLIST
end

function CHuodongMgr:InitData(iNo)
    self.m_WarNo = iNo
    super(CHuodongMgr).InitData(self)
end
