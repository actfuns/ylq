--import module
local global = require "global"
local skynet = require "skynet"

local gamedefines = import(lualib_path("public.gamedefines"))
local colorstring = require "public.colorstring"

function SendPrioritySysChat(mRecord,mData)
    local sType = mData.priority_type
    local mNet = mData.data
    local oGonggaoMgr = global.oGonggaoMgr
    oGonggaoMgr:AddMessage(sType,mNet)
end