
local skynet = require "skynet"
local servicetimer = require "base.servicetimer"

local floor = math.floor
local max = math.max
local min = math.min

function get_time(bFloat)
    local iTime = servicetimer.ServiceTime()
    if bFloat then
        return iTime/100
    else
        return floor(iTime/100)
    end
end

function get_current()
    return servicetimer.ServiceNow()
end

function get_second()
    return floor(get_current()/100)
end

function get_ssecond()
    return get_current()/100
end

function get_msecond()
    return get_current()*10
end

function get_starttime()
    return servicetimer.ServiceStartTime()
end

--2017/1/2
local iStandTime = 1483286400

function get_dayno(iSec)
    local iSec = iSec or get_time()
    local iTime = iSec - iStandTime
    local iDayNo = floor(iTime // (3600*24))
    return iDayNo
end

--5点算天
function get_morningdayno(iSec)
    local iSec = iSec or get_time()
    local iTime = iSec - iStandTime
    local iDayMorningNo = floor((iTime-5*3600) // (3600*24))
    return iDayMorningNo
end

function get_weekno(iSec)
    local iSec = iSec or get_time()
    local iTime = iSec - iStandTime
    local iWeekNo = floor(iTime//(7*3600*24))
    return iWeekNo
end

--5点算星期
function get_morningweekno(iSec)
    local iSec = iSec or get_time()
    local iTime = iSec - iStandTime
    local iWeekNo = floor((iTime-5*3600)//(7*3600*24))
    return iWeekNo
end

function get_hourno(iSec)
    local iSec = iSec or get_time()
    local iTime = iSec - iStandTime
    local iHourNo = floor(iTime//3600)
    return iHourNo
end

function get_weekno2time(ino)
    local iSec = ino*604800 + iStandTime
    return iSec
end

function get_morningweekno2time(ino)
    local iSec = ino*604800+18000 + iStandTime
    return iSec
end


function get_daytime(tab)
    local iFactor = tab.factor  or 1                                        --正负因子
    local iDay = tab.day or 1                                                  --距离天数
    local iAnchor = tab.anchor or 0                                     --锚点
    iDay = iDay * iFactor
    local iCurTime = get_time()
    local iTime = iCurTime + iDay * 3600 * 24
    local date = os.date("*t",iTime)
    iTime = os.time({year=date.year,month=date.month,day=date.day,hour=iAnchor,min=0,sec=0})
    local retbl = {}
    retbl.time = iTime
    retbl.date = os.date("*t",iTime)
    return retbl
end

function get_hourtime(tab)
    local iFactor = tab.factor or 1                                                --正负因子
    local iHour = tab.hour or 1                                                     --距离小时
    iHour = iHour * iFactor
    local iCurTime = get_time()
    local iTime = iCurTime + iHour * 3600
    local date = os.date("*t",iTime)
    iTime = os.time({year=date.year,month=date.month,day=date.day,hour=date.hour,min=0,sec=0})
    local retbl = {}
    retbl.time = iTime
    retbl.date = os.date("*t",iTime)
    return retbl
end

function get_weekday(iTime)
    local iTime = iTime or get_time()
    local wday = tonumber(os.date("%w",iTime))
    if wday == 0 then
        return 7
    else
        return wday
    end
end


function get_mondaytime(iTime)
    local iTime = iTime or get_time()
    local wday = get_weekday(iTime)
    return iTime - (wday - 1) * 24 * 3600
end

function get_monthno(iTime)
    local iTime = iTime or get_time()
    local ms = os.date("*t",iStandTime)
    local mn = os.date("*t",iTime)
    return (mn["year"] - ms["year"])*12 + (mn["month"]-ms["month"])
end


function get_format_time(iTime)
    iTime = iTime or get_time()
    return os.date("%c", iTime)
end

function get_time_format_str(iTime, sFormat)
    iTime = iTime or get_time()
    return os.date(sFormat, iTime)
end

function get_second2string(sec)
    local s = math.floor(sec % 60)
    local m = math.floor((sec / 60)  % 60)
    local h = math.floor(sec / 3600)
    local str = ""
    if h > 0 then
        str = string.format("%s%02d时",str,h)
    end
    if h > 0 or m > 0 then
        str = string.format("%s%02d分",str,m)
    end
    str = string.format("%s%02d秒",str,s)
    return str
end

function str2timestamp(sTime)
    if not sTime or sTime == "" then
        return
    end
    local year,month,day,hour,min,sec = string.match(sTime,"(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    year,month,day,hour,min,sec = tonumber(year),tonumber(month),tonumber(day),tonumber(hour or 0),tonumber(min or 0),tonumber(sec or 0)
    return os.time({year = year,month = month,day = day,hour=hour,min=min,sec=sec})
end
