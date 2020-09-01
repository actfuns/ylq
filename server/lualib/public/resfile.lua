
local eio = require("base.extend").Io
local lfs = require "lfs"

local M = {}

local sDaobiaoPath = "daobiao/gamedata/server/data.lua"
local sMapRoot = "cs_common/data/map/"
local sWarFloatTime = "cs_common/data/warfloattime.lua"
local sClientTrapmine = "cs_common/data/client_trapmine.lua"
local sClientGuidance = "cs_common/data/client_guideconfigdata.lua"

local function HandleNpcAreaPath(sPath)
    local lRet = {}

    local iCnt = 0
    for s in io.lines(sPath) do
        iCnt = iCnt + 1
    end

    local y = 0.16 + (iCnt - 1)*0.32
    for s in io.lines(sPath) do
        local x = 0.16
        for j = 1, #s do
            if string.sub(s, j, j) == "1" then
                table.insert(lRet, {x, y, 0})
            end
            x = x + 0.32
        end
        y = y - 0.32
    end
    return lRet
end

local function HandleLeiTaiPath(sPath)
    local mRet = {}
    local i = 0
    for s in io.lines(sPath) do
        i = i + 1
        local lX = {}
        for j = 1, #s do
            if string.sub(s, j, j) == "1" then
                lX[j] = 1
            end
        end
        if next(lX) then
            mRet[i] = lX
        end
    end
    local mData = {}
    mData["leitaidata"] = mRet
    mData["len"] = i

    return mData
end

local function Require(sPath)
    local f = loadfile_ex(sPath, "bt")
    return f()
end

local function RequireMap(sRoot)
    local mNpcArea = {}
    local mLeiTai = {}
    local mMonster = {}
    local mTarpmine = {}
    local mHeroBox = {}
    for n in lfs.dir(sRoot) do
        local sPath = sRoot..n
        if lfs.attributes(sPath, "mode") == "file" then
            if string.sub(n, 1, 8) == "npc_area" then
                local id = tonumber(string.match(n, "%d+"))
                assert(id, string.format("read %s err", sPath))
                local l = HandleNpcAreaPath(sPath)
                mNpcArea[id] = l
            elseif string.sub(n, 1, 6) == "leitai" then
                local id = tonumber(string.match(n, "%d+"))
                assert(id, string.format("read %s err", sPath))
                local m = HandleLeiTaiPath(sPath)
                mLeiTai[id] = m
            elseif string.sub(n,1,7) == "monster" then
                local id = tonumber(string.match(n, "%d+"))
                assert(id, string.format("read %s err", sPath))
                local m = HandleNpcAreaPath(sPath)
                mMonster[id] = m
            elseif string.sub(n, 1, 8) == "trapmine" then
                local id = tonumber(string.match(n, "%d+"))
                assert(id, string.format("read %s err", sPath))
                local m = HandleNpcAreaPath(sPath)
                mTarpmine[id] = m
            elseif string.sub(n,1,3) == "box" then
                local id = tonumber(string.match(n, "%d+"))
                assert(id, string.format("read %s err", sPath))
                local m = HandleNpcAreaPath(sPath)
                mHeroBox[id] = m
            end
        end
    end
    local ret = {}
    ret.npc_area = mNpcArea
    ret.leitai = mLeiTai
    ret.monster = mMonster
    ret.trapmine = mTarpmine
    ret.herobox = mHeroBox
    return ret
end


M.daobiao = Require(sDaobiaoPath)
M.map = RequireMap(sMapRoot)
M.warfloattime = Require(sWarFloatTime)
M.client_trapmine = Require(sClientTrapmine)
M.client_guidance = Require(sClientGuidance)
return M

