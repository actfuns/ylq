--import module
local global = require "global"
local skynet = require "skynet"
local eio = require("base.extend").Io
local sharedata = require "sharedata"

function ReloadRes(mRecord, mData)
    local sResFile = eio.readfile(skynet.getenv("res_file"))
    sharedata.update("res", sResFile)
end
