local global = require "global"
local extend = require "base/extend"

local PerformList = {}

local PerformDir = {
    ["school"]  = {3001,3999},
    ["partner"] = {10001,599990},
    ["se"] = {0,3000},
    ["npc"]  = {5000,6000},
    ["equip"] = {6001,7000},
}

local ShowPerformType = {
    partner = 1,
    school = 2,
    partneres = 3,
    equip = 4,
    --buff = 5,
    se = 6,
    npc = 7,
}


local PartnerESkill = {210,255}
local EquipSkill = {6001,6299}

function IsPartnerESkill(iSkill)
    return iSkill >= PartnerESkill[1] and iSkill <= PartnerESkill[2]
end

function IsEquipSkill(iSkill)
    return iSkill >= EquipSkill[1] and iSkill <= EquipSkill[2]
end

function GetShowPerfromType(iSkill)
    if IsPartnerESkill(iSkill) then
        return ShowPerformType["partneres"]
    end
    for k,v in pairs(PerformDir) do
        if iSkill >= v[1] and iSkill <= v[2] then
            if ShowPerformType[k] then
                return ShowPerformType[k]
            end
        end
    end
    return 1
end


function GetPerformDir(sid)
    for sDir,mPos in pairs(PerformDir) do
        local iStart,iEnd = table.unpack(mPos)
        if iStart <= sid and sid <= iEnd then
            return sDir
        end
    end
end

function NewPerform(iPerform)
    iPerform = tonumber(iPerform)
    local sDir = GetPerformDir(iPerform)
    local sPath = string.format("perform/%s/p%d",sDir,iPerform)
    local oModule = import(service_path(sPath))
    assert(oModule,string.format("GetPerform err:%d,%s",iPerform,sPath))
    local oPerform = oModule.NewCPerform(iPerform)
    return oPerform
end

function GetPerform(iPerform,...)
    iPerform = tonumber(iPerform)
    local oPerform = PerformList[iPerform]
    if oPerform then
        return oPerform
    end
    assert(iPerform,string.format("GetPerform err:%s",iPerform))
    local oPerform = NewPerform(iPerform)
    PerformList[iPerform] = oPerform
    return oPerform
end