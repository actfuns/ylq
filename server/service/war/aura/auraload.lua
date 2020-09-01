
local global = require "global"
local extend = require "base.extend"

mAuraList = {}

function NewAura(iAura)
    local sPath = string.format("aura/entity/a%s",iAura)
    local oModule = import(service_path(sPath))
    local oAura = oModule.NewCAura(iAura)
    return oAura
end

function GetBuff(iAura)
    local oAura = mAuraList[iAura]
    if oAura then
        return oAura
    end
    oAura = NewAura(iAura)
    
    return oAura
end