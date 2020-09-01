--import module
local global = require "global"
local skynet = require "skynet"

local httpwrapper = import(service_path("httpwrapper"))

function HandleRequest(mRecord, mData)
    local id = mData.socket_id
    local addr = mData.socket_addr
    local obj = httpwrapper.NewHttpWrapper(id)
    obj:RecvRequest()
end
