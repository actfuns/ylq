--import module
local global = require "global"

function FormatTimeToSec(iTime)
    local m = os.date("*t", iTime)
    return string.format("%04d-%02d-%02d %02d:%02d:%02d",m.year,m.month,m.day,m.hour,m.min,m.sec)
end