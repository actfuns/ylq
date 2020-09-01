
local skynet = require "skynet"

local recycle_wait = {}
local recycle_fail = {}

local M = {}

function M.now_release(obj)
    assert(obj.Release, "baserecycle now_release fail")
    local br, rr = safe_call(obj.Release, obj)
    if not br then
        recycle_fail[obj] = rr
    end
end

function M.wait_release(obj)
    assert(obj.Release, "baserecycle wait_release fail")
    recycle_wait[obj] = true
end

function M.recycle()
    local limit = 0
    local repeated = {}

    local m = M.getwait()
    while table_count(m) > 0 do
        limit = limit + 1
        recycle_wait = {}

        for v, _ in pairs(m) do
            if not repeated[v] then
                repeated[v] = true
                local br, rr = safe_call(v.Release, v)
                if not br then
                    recycle_fail[v] = rr
                end
            end
        end

        if limit >= 10 then
            print(string.format("warning: recycle deep limit:%d", limit))
            break
        end
        m = M.getwait()
    end
end

function M.getwait()
    local m = {}
    for k, v in pairs(recycle_wait) do
        m[k] = v
    end
    return m
end

function M.getfail()
    local m = {}
    for k, v in pairs(recycle_fail) do
        m[k] = v
    end
    return m
end

function M.cleanfail(force)
    local m = M.getfail()
    for v, _ in pairs(m) do
        local br, rr = safe_call(v.Release, v)
        if not br then
            recycle_fail[v] = rr
        else
            recycle_fail[v] = nil
        end
    end

    if force then
        recycle_fail = {}
    end
end

return M
