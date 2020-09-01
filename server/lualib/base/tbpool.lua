
local skynet = require "skynet"

local mmin = math.min
local mmax = math.max

local M = {}

local iPre = 50
local iMaxCache = 5000000
local iMaxCollect = 500000
local iCollectTime = 50*60*100
local iCollectNo = 0

local lPool = {}
local iApplyPop = 0

local function ResetCollect()
    iCollectNo = iCollectNo + 1
    local iStartNo = iCollectNo
    local f
    f = function ()
        if iCollectNo == iStartNo then
            M.Collect()
            skynet.timeout(iCollectTime, f)
        end
    end
    f()
end

function M.Pop()
    local i = #lPool
    local t = lPool[i]

    if t then
        lPool[i] = nil
    else
        t = {}
        local j = mmin(iPre, iMaxCache)
        for ii = 1, j do
            lPool[ii] = {}
        end
    end

    setmetatable(t, nil)
    for k, _ in pairs(t) do
        t[k] = nil
    end
    iApplyPop = iApplyPop + 1

    return t
end

function M.Push(t)
    local i = #lPool
    if i < iMaxCache then
        lPool[i+1] = t
    end
end

function M.Collect()
    local i = 2*iApplyPop
    local j = #lPool
    if i < j then
        for ii = j, i+1, -1 do
            lPool[ii] = nil
        end
    end
    iApplyPop = 0
end

function M.Clear()
    local i = #lPool
    for ii = i, 1, -1 do
        lPool[ii] = nil
    end
end

function M.Init()
    ResetCollect()
end

function M.SetPre(i)
    iPre = mmax(i, 0)
end

function M.SetMaxCache(i)
    iMaxCache = mmax(i, 0)
end

function M.SetMaxCollect(i)
    iMaxCollect = mmax(i, 0)
end

function M.SetCollectTime(i)
    iCollectTime = mmax(i, 1)
    ResetCollect()
end

return M
