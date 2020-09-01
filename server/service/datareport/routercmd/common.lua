local global = require "global"

function PushIOSData(mRecord, mData)
    global.oReportMgr:PushIOSData(mData.key,mData.data)
end

function PushADData(mRecord, mData)
    global.oReportMgr:PushADData(mData.key,mData.data)
end

function PushIOSLData(mRecord, mData)
    global.oReportMgr:PushIOSLData(mData.key,mData.ldata)
end

function PushADLData(mRecord, mData)
    global.oReportMgr:PushADLData(mData.key,mData.ldata)
end