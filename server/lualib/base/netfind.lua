
local M = {}

local mFind

function M.Init(f)
    local f, s = loadfile_ex(f, "bt")
    if not f then
        print("netfind init error", s)
        return
    end
    mFind = f()
end

function M.FindC2GSByType(iType)
    return mFind.C2GS[iType]
end

function M.FindGS2CByType(iType)
    return mFind.GS2C[iType]
end

function M.FindC2GSByName(sName)
    return mFind.C2GS_BY_NAME[sName]
end

function M.FindGS2CByName(sName)
    return mFind.GS2C_BY_NAME[sName]
end

return M
