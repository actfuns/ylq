local global = require "global"
local extend = require "base.extend"
local router = require "base.router"
local interactive = require "base.interactive"
local record = require "public.record"

local gamedefines = import(lualib_path("public.gamedefines"))
local datactrl = import(lualib_path("public.datactrl"))

function NewInsideFuliMgr()
    return CInsideFuliMgr:New()
end

mPlayers = {
    [11574] = "13247395343",          --刘威
    [11573] = "kb1181",                     --林强
    [11564] = "tlo889",                       --张闯
    [17221] = "804030008",              --张闯
    [11563] = "07883928",                --hc
    [11588] = "chinawa",
    [11570 ] = "jw29723905",
    [11598] = "wdych1",
    [11596] = "912088012",
    [19379] = "wdych4",                  
}


CInsideFuliMgr = {}
CInsideFuliMgr.__index = CInsideFuliMgr
inherit(CInsideFuliMgr, datactrl.CDataCtrl)

function CInsideFuliMgr:New()
    local o = super(CInsideFuliMgr).New(self)
    return o
end

function CInsideFuliMgr:ValidReward(oPlayer)
    if oPlayer.m_oThisWeek:Query("inside_reward",0) > 0 then
        return false
    end
    local iPid = oPlayer:GetPid()
    local sAccount = oPlayer:GetAccount()
    if not mPlayers[iPid] or mPlayers[iPid] ~= sAccount then
        return false
    end
    return true
end

function CInsideFuliMgr:OnLogin(oPlayer)
    if not self:ValidReward(oPlayer) then
        return
    end
    self:InsideReward(oPlayer)
end

function CInsideFuliMgr:InsideReward(oPlayer)
    oPlayer.m_oThisWeek:Add("inside_reward",1)
    local oHuodongMgr = global.oHuodongMgr
    local oWorldMgr = global.oWorldMgr
    local oHuoDong = oHuodongMgr:GetHuodong("charge")
    if oHuoDong then
        oHuoDong:TestOP(oPlayer,401,1007)
        local iPid = oPlayer:GetPid()
        local sAccount = oPlayer:GetAccount()
        record.info(string.format("inside_reward,pid:%s,account:%s",iPid,sAccount))
    end
end

