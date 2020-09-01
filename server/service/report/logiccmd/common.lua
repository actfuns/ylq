local global = require "global"

function DoAddNew(mRecord, mData)
    local oReportProxy = global.oReportProxy
    oReportProxy:DoAddNew(mData.data)
end