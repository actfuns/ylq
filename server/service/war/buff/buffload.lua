
local global = require "global"
local extend = require "base.extend"

local mLoadBuff = {101,102,103,104,105,106,107,108,109,110,111,112,113,114,1001,1002,1004,1009,1010,1011,1012,1014,1015,1017,1018,1019,1026,1027,1031,1035,1039,1040}

local mBuffList = {}

function GetPath(iBuffID)
    local sPath = "buff/buffbase"
    if global.oDerivedFileMgr:ExistFile("buff", "b"..iBuffID) then
        sPath = string.format("buff/b%d", iBuffID)
    end
    return sPath
end

function NewBuff(iBuffID)
    local sPath = GetPath(iBuffID)
    local oModule = import(service_path(sPath))
    local oBuff = oModule.NewBuff(iBuffID)
    return oBuff
end

function GetBuff(iBuffID)
    local oBuff = mBuffList[iBuffID]
    if oBuff then
        return oBuff
    end
    oBuff = NewBuff(iBuffID)
    local mArgs = {
        level = 1
    }
    oBuff:Init(iBuffID,mArgs)
    mBuffList[iBuffID] = oBuff
    return oBuff
end