--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function HandleConfictNameOrg(mRecord, mData)
    local oOrgMgr = global.oOrgMgr
    local fCallback = function ()
        oOrgMgr:HandleConfictNameOrg(mRecord,mData)
    end
    oOrgMgr:Execute(fCallback)
end