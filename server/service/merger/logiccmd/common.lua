--import module
local global = require "global"
local skynet = require "skynet"
local interactive = require "base.interactive"

function StartGSMerger(mRecord, mData)
    local iMergerTimes = mData.merger_times
    local oGSMerger = global.oGSMerger
    oGSMerger:StartMerger(iMergerTimes)
end

function StartCSMerger(mRecord, mData)
    local iMergerTimes = mData.merger_times
    local oCSMerger = global.oCSMerger
    oCSMerger:StartMerger(iMergerTimes)
end