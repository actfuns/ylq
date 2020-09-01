local global = require "global"

local extend = require "base.extend"

local mNpcDir = {
    ["func"] = {5001,5200},
    ["idle"] = {5201,5400},
    ["wizard"] = {0,100},
}

function GetDir(npcid)
    for sDir,mNpc in pairs(mNpcDir) do
        local iStart,iEnd = table.unpack(mNpc)
        if iStart <= npcid and npcid <= iEnd then
            return sDir
        end
    end
end

function GetPath(iNpcType)
    local sDir = GetDir(iNpcType)
    if global.oDerivedFileMgr:ExistFile("npc", sDir, "n"..iNpcType) then
        return string.format("npc/%s/n%d",sDir,iNpcType)
    end
    return string.format("npc/npcobj")
end

function NewNpc(iNpcType)
    local sPath = GetPath(iNpcType)
    local oModule = import(service_path(sPath))
    assert(oModule,string.format("Load Npc Module:%d",iNpcType))
    return oModule.NewNpc(iNpcType)
end