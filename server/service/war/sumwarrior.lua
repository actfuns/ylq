
--召唤单位
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local net = require "base.net"

local gamedefines = import(lualib_path("public.gamedefines"))
local CWarrior = import(service_path("warrior")).CWarrior

function NewSummonWarrior(...)
    return CSummonWarrior:New(...)
end

StatusHelperFunc = {}
StatusHelperDef = {}

StatusHelperDef.hp = 2
function StatusHelperFunc.hp(o)
    return o:GetHp()
end

StatusHelperDef.mp = 3
function StatusHelperFunc.mp(o)
    return o:GetMp()
end

StatusHelperDef.max_hp = 4
function StatusHelperFunc.max_hp(o)
    return o:GetMaxHp()
end

StatusHelperDef.max_mp = 5
function StatusHelperFunc.max_mp(o)
    return o:GetMaxMp()
end

StatusHelperDef.model_info = 6
function StatusHelperFunc.model_info(o)
    return o:GetModelInfo()
end

StatusHelperDef.name = 7
function StatusHelperFunc.name(o)
    return o:GetName()
end

StatusHelperDef.status = 9
function StatusHelperFunc.status(o)
    return o.m_oStatus:Get()
end




CSummonWarrior = {}
CSummonWarrior.__index = CSummonWarrior
inherit(CSummonWarrior, CWarrior)

function CSummonWarrior:New(iWid)
    local o = super(CSummonWarrior).New(self, iWid)
    o.m_iType = gamedefines.WAR_WARRIOR_TYPE.SUMMON_TYPE
    return o
end

function CSummonWarrior:GetSimpleWarriorInfo()
    return {
        wid = self:GetWid(),
        pos = self:GetPos(),
        pflist = self:GetPerformList(),
        owner = self:GetData("owner"),
        sum_id = self:GetData("sum_id"),
        status = self:GetSimpleStatus(),
    }
end

function CSummonWarrior:GetSimpleStatus(m)
    local mRet = {}
    if not m then
        m = StatusHelperDef
    end
    local iMask = 0
    for k, _ in pairs(m) do
        local i = assert(StatusHelperDef[k], string.format("GetSimpleStatus fail i get %s", k))
        local f = assert(StatusHelperFunc[k], string.format("GetSimpleStatus fail f get %s", k))
        mRet[k] = f(self)
        iMask = iMask | (2^(i-1))
    end
    mRet.mask = iMask
    return mRet
end

function CSummonWarrior:StatusChange(...)
    local l = table.pack(...)
    local m = {}
    for _, v in ipairs(l) do
        m[v] = true
    end
    local mStatus = self:GetSimpleStatus(m)
    self:SendAll("GS2CWarWarriorStatus", {
        war_id = self:GetWarId(),
        wid = self:GetWid(),
        type = self:Type(),
        status = mStatus,
    })
end