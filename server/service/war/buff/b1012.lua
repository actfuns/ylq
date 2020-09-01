--import module

local global = require "global"
local skynet = require "skynet"

local buffbase = import(service_path("buff/buffbase"))

function NewBuff(...)
    local o = CBuff:New(...)
    return o
end

CBuff = {}
CBuff.__index = CBuff
inherit(CBuff, buffbase.CBuff)

function CBuff:CalWarrior(oAction,oPerformMgr)
end

function CBuff:Overlying(oAction,oNewBuff)
    local iLevel = self:BuffLevel()
    if iLevel >= 3 then
        return
    end
    super(CBuff).Overlying(self,oAction,oNewBuff)
end

function CBuff:Bout()
    return 255
end