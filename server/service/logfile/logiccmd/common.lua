local global = require "global"
local interactive = require "base.interactive"
local extend = require "base.extend"

function WriteData(mRecord, mData)
    local oLogFileObj = global.oLogFileObj
    oLogFileObj:WriteData(mData.sName, mData.data)
end

function FixWriteData(mRecord, mData)
    local oLogFileObj = global.oLogFileObj
    oLogFileObj:FixWriteData(mData.sName, mData.data)
end