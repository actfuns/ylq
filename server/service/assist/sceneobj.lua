--import module

local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"
local res = require "base.res"
local geometry = require "base.geometry"
local extend = require "base.extend"

local gamedefines = import(lualib_path("public.gamedefines"))


function NewSceneMgr(...)
    local o = CSceneMgr:New(...)
    return o
end

CSceneMgr = {}
CSceneMgr.__index = CSceneMgr
inherit(CSceneMgr, logic_base_cls())

function CSceneMgr:New(lSceneRemote)
    local o = super(CSceneMgr).New(self)
    return o
end

function CSceneMgr:RandomPos(iMapId)
    local iMapRes = res["daobiao"]["map"][iMapId]["resource_id"]
    assert(iMapRes, string.format("RandomPos err %d", iMapId))
    local mPosList = res["map"]["npc_area"][iMapRes]
    local mPos = extend.Random.random_choice(mPosList)
    return table.unpack(mPos)
end

function CSceneMgr:RandomMonsterPos(iMapId,iCount)
    local iAmount = iCount or 1
    local iMapRes = res["daobiao"]["map"][iMapId]["resource_id"]
    assert(iMapRes, string.format("RandomMonsterPos err %d", iMapId))
    local mPosList = table_deep_copy(res["map"]["monster"][iMapRes])
    local mReturn = {}
    local mTemp = {}
    for i = 1,iAmount do
        local mPos,iIndex = extend.Random.random_choice(mPosList)
        table.insert(mReturn,mPos)
        table.remove(mPosList,iIndex)
    end
    return mReturn
end