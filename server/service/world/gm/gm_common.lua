local global = require "global"

Commands = {}

function Commands.SendBrocast(sMsg)
    if not sMsg or sMsg=="" then
        return
    end
    local oNotifyMgr = global.oNotifyMgr
    oNotifyMgr:SendSysChat(sMsg, 0, 1)
end