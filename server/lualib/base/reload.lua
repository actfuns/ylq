
local Ms = {}

function import(sModule)
    local sKey = string.gsub(sModule, "/", ".")
    if not Ms[sKey] then
        local sPath = string.gsub(sModule, "%.", "/") .. ".lua"
        local m = setmetatable({}, {__index = _G})
        local f, s = loadfile_ex(sPath, "bt", m)
        if not f then
            print("import error", s)
            return
        end
        f()
        Ms[sKey] = m
    end
    return Ms[sKey]
end

function reload(sModule)
    local sKey = string.gsub(sModule, "/", ".")

    local om = Ms[sKey]
    if not om then
        return
    end
    local sPath = string.gsub(sModule, "%.", "/") .. ".lua"

    local cm = table_copy(om)
    local f, s = loadfile_ex(sPath, "bt", om)
    if not f then
        print("reload error", s)
        return
    end
    f()

    local bStatus, sErr = pcall(function ()
        local visited = {}
        local recu
        recu = function (new, old)
            if visited[old] then
                return
            end
            visited[old] = true
            for k, v in pairs(new) do
                local o = old[k]
                if type(v) ~= type(o) then
                    old[k] = v
                else
                    if type(v) == "table" then
                        recu(v, o)
                    else
                        old[k] = v
                    end
                end
            end
        end

        for k, v in pairs(om) do
            local o = cm[k]
            if type(o) == type(v) and type(v) == "table" then
                recu(v, o)
                om[k] = o
            end
        end
    end)
    
    if not bStatus then
        print("reload failed", sErr)
        local l = {}
        for k, v in pairs(om) do
            if not cm[k] then
                table.insert(l, k)
            else
                om[k] = cm[k]
            end
        end
        for _, k in ipairs(l) do
            om[k] = nil
        end
    end
end
