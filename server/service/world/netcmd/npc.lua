--import module
local global = require "global"
local extend = require "base.extend"
local res = require "base.res"

local handlenpc = import(service_path("npc/handlenpc"))

function C2GSClickNpc(oPlayer,mData)
    local npcid = mData["npcid"]
    local oNpcMgr = global.oNpcMgr
    local oNpc = oNpcMgr:GetObject(npcid)
    if not oNpc then
        return
    end
    --assert(oNpc,string.format("C2GSClickNpc err %d",npcid))
    if not oPlayer:IsSingle() and not oPlayer:IsTeamLeader() then
        return
    end
    assert(oNpc.do_look,string.format("Npc没有dolook函数,npcid:%d",oNpc:ID()))
    oNpc:do_look(oPlayer)
end

function C2GSClickConvoyNpc(oPlayer,mData)
    local npcid = mData["npcid"]
    local oNpcMgr = global.oNpcMgr
    local oNpc = oNpcMgr:GetObject(npcid)
    if not oNpc then
        return
    end
    --assert(oNpc,string.format("C2GSClickNpc err %d",npcid))
    if not oPlayer:IsSingle() and not oPlayer:IsTeamLeader() then
        return
    end
    local oHuodong = global.oHuodongMgr:GetHuodong("convoy")
    if oHuodong then
        oHuodong:ClickNpc(oPlayer)
    end
end

function C2GSNpcRespond(oPlayer,mData)
    local npcid = mData["npcid"]
    local iAnswer = mData["answer"]
    local oNpcMgr = global.oNpcMgr
    local oNpc = oNpcMgr:GetObject(npcid)
    assert(oNpc,string.format("C2GSNpcRespond err %d",npcid))
    if not oPlayer:IsSingle() and not oPlayer:IsTeamLeader() then
        return
    end
    handlenpc.Respond(oPlayer.m_iPid,npcid,iAnswer)
end
