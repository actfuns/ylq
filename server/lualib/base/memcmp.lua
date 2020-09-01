
local skynet = require "skynet"
local snapshot = require "snapshot"

local M = {}
local lmem = {}
local mtrack = setmetatable({}, {__mode="kv"})

function M.current()
    local s = snapshot()
    local m = {}
    for k, v in pairs(s) do
        m[tostring(k)] = tostring(v)
    end
    return m
end

function M.shot()
    local iLen = #lmem
    if iLen == 0 then
        lmem[1] = snapshot()
    elseif iLen == 1 then
        lmem[2] = snapshot()
    else
        lmem[1] = lmem[2]
        lmem[2] = snapshot()
    end
end

function M.diff()
    local iLen = #lmem
    if iLen < 2 then
        return
    end

    local m = {}

    local s1 = lmem[1]
    local s2 = lmem[2]

    for k, v in pairs(s2) do
        if s1[k] == nil then
            m[tostring(k)] = tostring(v)
        end
    end

    return m
end

function M.track(obj)
    if is_auto_track_baseobject() then
        local key = debug.traceback()
        mtrack[obj] = key
    end
end

function M.showtrack()
    collectgarbage("collect")
    local m = {}
    for k, v in pairs(mtrack) do
        if not m[v] then
            m[v] = 0
        end
        m[v] = m[v] + 1
    end

    local l = {}
    for k, v in pairs(m) do
        table.insert(l, {k, v})
    end
    table.sort(l, function (a, b)
        return a[2] > b[2]
    end)

    return l
end

function M.printjemalloc()
    local memory = require "memory"
    memory.dumpinfo()
end

return M
