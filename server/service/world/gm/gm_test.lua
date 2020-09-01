local global = require "global"
local interactive = require "base.interactive"

Commands = {}

function Commands.historycharge(oMaster, iDegree, ...)
    local mList = {...}
    oMaster:Send("GS2CHistoryCharge",{
        degree = iDegree,
        getlist = mList,
    })
end