--import module

local global = require "global"
local skynet = require "skynet"

function Invoke(iFd, iType, sData)
    local oProxy = global.oProxy
    if oProxy then
        oProxy:DoAddRecv(iFd, iType, sData)
    end
end
