--import module
local global = require "global"
local skynet = require "skynet"
local router = require "base.router"

local war = import(service_path("logiccmd.war"))

function Forward(mRecord, mData)
    war.Forward(mRecord,mData)
end

function TestCmd(mRecord, mData)
    war.TestCmd(mRecord,mData)
end

function LeavePlayer(mRecord, mData)
    war.LeavePlayer(mRecord,mData)
end